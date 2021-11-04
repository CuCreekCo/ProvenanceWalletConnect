//
// Created by Jason Davidson on 8/28/21.
//

import Foundation
import ProvWallet
import GRPC
import NIO
import SwiftProtobuf
import CoreData

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
		auth = AuthQuery(channel: channel)
		bank = Bank(channel: channel)

	}

// MARK: - HD Wallet
	func generatePrivateKey(mnemonic: String,
	                        completion: @escaping (PrivateKey?, ProvenanceWalletError?) -> Void) throws -> Void {
		let seed = Mnemonic.createSeed(mnemonic: mnemonic)

		let privateKey: PrivateKey = Utilities.mainnet() ?
				PrivateKey(seed: seed, coin: .mainnet) : PrivateKey(seed: seed, coin: .testnet)

		completion(privateKey, nil)
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
			try container.viewContext.save()
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

	func fetchAddressEntity(rootWallet: RootWallet, index: Int) throws -> Address? {
		let address: Address? = rootWallet.addresses?.filter { e in
			(e as! Address).index == Int32(index)
		}.first as? Address
		return address
	}

	func defaultAddress() -> String {
		do {
			return try fetchAddresses().first!.address!
		} catch {
			Utilities.log(error)
			return ""
		}

	}
	
	func fetchAddresses() throws -> [Address] {
		guard let rootWallet = try fetchRootWalletEntity() else {
			throw ProvenanceWalletError(kind: .rootWalletNotFound, message: "Root Wallet Not Found", messages: nil, underlyingError: nil)
		}
		let addresses = rootWallet.addresses?.map {  a in
			a as! Address
		} ?? []

		return addresses.sorted { x, y  in
			x.index < y.index
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

			/* Clean out old addresses */
			for case let address as Address in rootWallet.addresses ?? NSSet() {
				container.viewContext.delete(address)
			}
			try attachAddresses(privateKey: privateKey, rootWallet: rootWallet)
			
			try container.viewContext.save()
			completion(uuid, nil)
		} catch let error as NSError {
			Utilities.log(error)
			completion(nil, ProvenanceWalletError(
					kind: .dataPersistence, message: error.localizedDescription, messages: nil, underlyingError: error)
			)
		}
	}
	private func attachAddresses(privateKey: PrivateKey, rootWallet: RootWallet) throws -> Void {
		try addresses(privateKey: privateKey, startIndex: 0, endIndex: 10).enumerated().forEach({ (index, addr) in
			let address = Address(entity: NSEntityDescription.entity(forEntityName: "Address",
			                                                           in: container.viewContext)!, insertInto: container.viewContext)
			address.address = addr
			address.index = Int32(index)
			address.rootWallet = rootWallet
		})
	}
	func refreshAddresses() throws -> Void {
		do {
			guard let rootWallet = try fetchRootWalletEntity() else {
				throw ProvenanceWalletError(kind: .rootWalletNotFound, message: "Root Wallet Not Found", messages: nil, underlyingError: nil)
			}

			for case let address as Address in rootWallet.addresses ?? NSSet() {
				container.viewContext.delete(address)
			}
			
			let key = try decryptWalletKey(rootWallet: rootWallet)
			try attachAddresses(privateKey: key, rootWallet: rootWallet)
			try container.viewContext.save()
		} catch {
			Utilities.log(error)
			throw ProvenanceWalletError(kind: .dataPersistence, message: "Could Not Refresh", messages: nil, underlyingError: error)
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
		guard let address = try fetchAddresses().first?.address else {
			throw ProvenanceWalletError(kind: .walletAddressError, message: "Wallet Address not Found", messages: nil, underlyingError: nil)
		}

		do {
			return try bank.balance(address: address, denom: "nhash").wait()
		} catch {
			Utilities.log(error)
			return Cosmos_Base_V1beta1_Coin.init()
		}
	}

	func estimateTx(signingKey: PrivateKey, message: Message) throws -> Cosmos_Base_Abci_V1beta1_GasInfo {

		// Query the blockchain account in a blocking wait
		let baseAccount = try auth.baseAccount(address: signingKey.publicKey.address).wait()

		let tx = Tx(signingKey: signingKey, baseAccount: baseAccount, channel: channel)

		let txMsg = try Google_Protobuf_Any.from(message: message)

		let estPromise: EventLoopFuture<Cosmos_Base_Abci_V1beta1_GasInfo> = try tx.estimateTx(messages: [txMsg])

		return try estPromise.wait()
	}

	func broadcastTx(signingKey: PrivateKey, message: Message, gasEstimate: Cosmos_Base_Abci_V1beta1_GasInfo) throws -> Cosmos_Base_Abci_V1beta1_TxResponse {
		// Query the blockchain account in a blocking wait
		let baseAccount = try auth.baseAccount(address: signingKey.publicKey.address).wait()

		let tx = Tx(signingKey: signingKey, baseAccount: baseAccount, channel: channel)

		let txMsg = try Google_Protobuf_Any.from(message: message)

		let txPromise: EventLoopFuture<Cosmos_Base_Abci_V1beta1_TxResponse> = try tx.broadcastTx(gasEstimate: gasEstimate, messages: [txMsg])
		return try txPromise.wait()
	}

}
