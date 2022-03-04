//
// Created by Jason Davidson on 8/28/21.
//

import Foundation
import ProvWallet
import GRPC
import NIO
import SwiftProtobuf
import CoreData
import SwiftyJSON

class WalletService: NSObject {
	
	private var container: NSPersistentContainer!

	var auth: AuthQuery!
	var bank: Bank!
	var channel: ClientConnection!

	init(persistentContainer: NSPersistentContainer, channel:ClientConnection) {
		super.init()
		//TODO ARC leak?
		container = persistentContainer

		self.channel = channel
		self.channel.connectivity.delegate = self
		auth = AuthQuery(channel: channel)
		bank = Bank(channel: channel)

	}

// MARK: - HD Wallet
    func randomMnemonic() throws -> String {
	    Mnemonic.create(strength: .hight)
    }
	
	func generatePrivateKey(mnemonic: String) throws -> PrivateKey {
		let seed = Mnemonic.createSeed(mnemonic: mnemonic)

		return Utilities.mainnet() ? PrivateKey(seed: seed, coin: .mainnet) : PrivateKey(seed: seed, coin: .testnet)
	}

	func defaultPrivateKey(index: UInt32 = 0) throws -> PrivateKey {
		guard let rootWallet = try fetchRootWalletEntity() else {
			throw ProvenanceWalletError(kind: .rootWalletNotFound, message: "Root Wallet Not Found", messages: nil, underlyingError: nil)
		}
		let root = try decryptWalletKey(rootWallet: rootWallet)
		return accountPathKey(rootKey: root, atIndex: index)
	}

	func accountPathKey(rootKey: PrivateKey, atIndex:UInt32) -> PrivateKey {
		// BIP44 key derivation
		// m/44'
		let purpose = rootKey.derived(at: .hardened(44))

		// m/44'/1' or m/44/505'
		let coinType = Utilities.mainnet() ? purpose.derived(at: .hardened(505))
				: purpose.derived(at: .hardened(1))

		// m/44'/1'/0'
		let account = coinType.derived(at: .hardened(0))

		// m/44'/1'/0'/0
		let change = account.derived(at: .notHardened(0))

		//TODO if mainnet unhardened, if testnet hardened :|
		// m/44'/1'/0'/0/0
		return Utilities.mainnet() ? change.derived(at: .notHardened(atIndex)) :
				change.derived(at: .hardened(atIndex))
	}

	private func addresses(privateKey: PrivateKey, startIndex: Int, endIndex: Int) throws -> [String?] {
		try (startIndex...endIndex).map({ i in try address(privateKey: privateKey, index: i) })
	}

	private func address(privateKey: PrivateKey, index: Int) throws -> String? {
		do {
			//TODO if mainnet unhardened, if testnet hardened :|
			// m/44'/1'/0'/0/0
			let firstPrivateKey = accountPathKey(rootKey: privateKey, atIndex: UInt32(index))

			NSLog("\(firstPrivateKey.publicKey.address)")
			return firstPrivateKey.publicKey.address
		} catch {
			Utilities.log(error)
			throw ProvenanceWalletError(
					kind: .walletAddressError, message: "Invalid root wallet", messages: nil, underlyingError: error
			)
		}
	}

// MARK: - Signature
	func sign(messageData: Data) throws -> Data {
		let privateKey = try defaultPrivateKey()
		return try privateKey.sign(data: messageData).provenanceSignature
	}

// MARK: - JWT
	func signed_jwt(privateKey: PrivateKey) throws -> String {
		let now = Int(Date.init().timeIntervalSince1970)
		let headerDict = [
			"alg": "ES256K",
			"typ": "JWT"
		]
		let payloadDict = [
			"sub": privateKey.publicKey.compressedPublicKey.toBase64URLWithoutPadding(),
			"iss": "provenance.io",
			"iat": now,
			"exp": now + (24 * 60 * 60),
			"addr": privateKey.publicKey.address
		] as [String: Any]
		
		let headerJSON = JSON(headerDict).rawString([.encoding : String.Encoding.utf8])
		let header = headerJSON!.data(using: .utf8)!.toBase64URLWithoutPadding()
		
		let payloadJSON = JSON(payloadDict).rawString([.encoding : String.Encoding.utf8])
		let payload = payloadJSON!.data(using: .utf8)!.toBase64URLWithoutPadding()

		let signMe = "\(header).\(payload)"
		let signature = try privateKey.sign(data: signMe.data(using: .utf8)!.sha256()).provenanceSignature
		return "\(signMe).\(signature.toBase64URLWithoutPadding())"
	}

// MARK: - Wallet Cipher
	private func decryptWalletKey(rootWallet: RootWallet) throws -> PrivateKey {
		guard let uuid = rootWallet.id else {
			throw ProvenanceWalletError(kind: .dataPersistence, message: "Could not decipher UUID",
			                            messages: nil, underlyingError: nil)
		}
		guard let data = rootWallet.seedCipher else {
			throw ProvenanceWalletError(kind: .dataPersistence, message: "Could not decipher seed cipher",
			                            messages: nil, underlyingError: nil)
		}
		let cipher = try CipherService.decrypt(keyName: uuid.uuidString, cipherText: data)

		guard let clearText = String(data: cipher, encoding: .utf8) else {
			throw ProvenanceWalletError(kind: .dataPersistence,
			                            message: "Could not decrypt with key \(uuid.uuidString)",
			                            messages: nil, underlyingError: nil)
		}
		return try PrivateKey(bip32Serialized: String(data: cipher, encoding: .utf8)!)
	}


// MARK: - Wallet Core Data
	func disconnectWallet() -> Bool {
		do {
			if let rootWallet = try fetchRootWalletEntity() {
				container.viewContext.delete(rootWallet)
			}
			if(container.viewContext.hasChanges) {
				try container.viewContext.save()
			}
			return true
		} catch {
			Utilities.log(error)
			return false
		}
	}
	func rootWalletSeedExists() -> Bool {
		let fetchRequest = NSFetchRequest<RootWallet>(entityName: "RootWallet")
		do {
			// Right now we only store 1 row in the RootWallet table
			let fetchResults = try container.viewContext.fetch(fetchRequest)
			return fetchResults.count > 0
		} catch {
			Utilities.log(error)
			return false
		}
	}

	func fetchRootWalletEntity() throws -> RootWallet? {
		let fetchRequest = NSFetchRequest<RootWallet>(entityName: "RootWallet")
		do {
			// Right now we only store 1 row in the RootWallet table
			let fetchResults = try container.viewContext.fetch(fetchRequest)
			return fetchResults.first
		} catch {
			Utilities.log(error)
			throw error
		}
	}

	func defaultAddress() -> String? {
		do {
			return try fetchRootWalletEntity()?.defaultAddress
		} catch {
			Utilities.log(error)
			return ""
		}

	}
	
	func fetchRootWalletSerializedPublicKey() -> String? {
		do {
			guard let rootWallet = try fetchRootWalletEntity() else {
				return nil
			}
			let key = try decryptWalletKey(rootWallet: rootWallet)
			return try key.serialize()
		} catch {
			Utilities.log(error)
		}
		return nil
	}

	func saveRootWallet(privateKey: PrivateKey,
	                    completion: @escaping (UUID?, ProvenanceWalletError?) -> Void) {
		do {
			var rootWallet: RootWallet
			let uuid = UUID()
			if (rootWalletSeedExists()) {
				rootWallet = try fetchRootWalletEntity()!
			} else {
				let rootWalletEntity = NSEntityDescription.entity(forEntityName: "RootWallet",
				                                                  in: container.viewContext)!
				rootWallet = RootWallet(entity: rootWalletEntity, insertInto: container.viewContext)
				rootWallet.setValue(uuid, forKeyPath: "id")
			}

			try CipherService.createAndStoreKey(name: rootWallet.id!.uuidString)
			let seedCipher = try CipherService.encrypt(keyName: rootWallet.id!.uuidString,
			                                           plainText: privateKey.serialize(publicKeyOnly: false))
			rootWallet.seedCipher = seedCipher
			rootWallet.mainnet = Utilities.mainnet()
			rootWallet.defaultAddress = try defaultPrivateKey().publicKey.address

			try container.viewContext.save()
			completion(uuid, nil)
		} catch let error as NSError {
			Utilities.log(error)
			completion(nil, ProvenanceWalletError(
					kind: .dataPersistence, message: error.localizedDescription, messages: nil, underlyingError: error)
			)
		}
	}

// MARK: - Blockchain
	func queryAuth(address: String) -> Cosmos_Auth_V1beta1_BaseAccount {

		do {
			return try auth.baseAccount(address: address).wait()
		} catch {
			Utilities.log(error)
			return Cosmos_Auth_V1beta1_BaseAccount.init()
		}
	}

	func queryBank() throws -> Cosmos_Base_V1beta1_Coin {
		guard let address = defaultAddress() else {
			throw ProvenanceWalletError(kind: .walletAddressError, message: "Wallet Address not Found", messages: nil, underlyingError: nil)
		}

		do {
			return try bank.balance(address: address, denom: "nhash").wait()
		} catch {
			Utilities.log(error)
			return Cosmos_Base_V1beta1_Coin.init()
		}
	}

	func nhashToHash(_ nhash: UInt64) -> Double {
		Double(nhash) / 1000000000
	}

	func nhashToHash(_ nhash: String) -> Double {
		(Double(nhash) ?? 0.0) / 1000000000
	}

	func estimateTx(signingKey: PrivateKey, messages: [Message]) throws -> GasEstimate {

		// Query the blockchain account in a blocking wait
		let baseAccount = try auth.baseAccount(address: signingKey.publicKey.address).wait()

		let tx = Tx(signingKey: signingKey, baseAccount: baseAccount, channel: channel)

		let txMsgs = try messages.map { message -> Google_Protobuf_Any in
			try Google_Protobuf_Any.from(message: message)
		}

		let estPromise: EventLoopFuture<GasEstimate> = try tx.estimateTx(messages: txMsgs)

		let gasEstimate = try estPromise.wait()

		Utilities.log(gasEstimate)

		return gasEstimate
	}

	func estimateTx(signingKey: PrivateKey, messages: [Message], completion: @escaping (GasEstimate?, Error?) -> Void) throws {

		// Query the blockchain account in a blocking wait
		let baseAccount = try auth.baseAccount(address: signingKey.publicKey.address).wait()

		let tx = Tx(signingKey: signingKey, baseAccount: baseAccount, channel: channel)

		let txMsgs = try messages.map { message -> Google_Protobuf_Any in
			try Google_Protobuf_Any.from(message: message)
		}

		let estPromise: EventLoopFuture<GasEstimate> = try tx.estimateTx(messages: txMsgs)

		estPromise.whenSuccess({ [self] info in
			do {
				Utilities.log(info)
			} catch {
				Utilities.log(error)
			}
			completion(info, nil)
		})

		estPromise.whenFailure { error in
			completion(nil, error)
		}
	}

	func broadcastTx(signingKey: PrivateKey, messages: [Message], gasEstimate: GasEstimate) throws -> RawTxResponsePair {
		// Query the blockchain account in a blocking wait
		let baseAccount = try auth.baseAccount(address: signingKey.publicKey.address).wait()

		let tx = Tx(signingKey: signingKey, baseAccount: baseAccount, channel: channel)

		let txMsgs = try messages.map { message -> Google_Protobuf_Any in
			try Google_Protobuf_Any.from(message: message)
		}

		let txPromise: EventLoopFuture<RawTxResponsePair> = try tx.broadcastTx(gasEstimate: gasEstimate, messages: txMsgs)
		return try txPromise.wait()
	}

	func broadcastTx(signingKey: PrivateKey, messages: [Message], gasEstimate: GasEstimate, completion: @escaping (RawTxResponsePair?, Error?) -> Void) {
		do {
			let baseAccount = try auth.baseAccount(address: signingKey.publicKey.address).wait()
			let tx = Tx(signingKey: signingKey, baseAccount: baseAccount, channel: channel)

			let txMsgs = try messages.map { message -> Google_Protobuf_Any in
				try Google_Protobuf_Any.from(message: message)
			}

			let txPromise: EventLoopFuture<RawTxResponsePair> = try tx.broadcastTx(gasEstimate: gasEstimate, messages: txMsgs)
			txPromise.whenSuccess { pair in
				completion(pair, nil)
			}
			txPromise.whenFailure { error in
				completion(nil, error)
			}
		} catch {
			Utilities.log(error)
			completion(nil, error)
		}
	}

}

extension WalletService: ConnectivityStateDelegate {
	public func connectivityStateDidChange(from oldState: ConnectivityState, to newState: ConnectivityState) {
		Utilities.log(oldState)
		Utilities.log(newState)
	}
}
