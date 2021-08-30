//
// Created by Jason Davidson on 8/28/21.
//

import Foundation
import ProvWallet
import CoreData
import GRPC

class WalletService: NSObject {
	
	private var container: NSPersistentContainer!

	init(persistentContainer: NSPersistentContainer) {
		super.init()
		//TODO ARC leak?
		container = persistentContainer
	}

// MARK: - HD Wallet
	func generatePrivateKey(mnemonic: String,
	                        completion: @escaping (PrivateKey?, ProvenanceWalletError?) -> Void) throws -> Void {
		let seed = Mnemonic.createSeed(mnemonic: mnemonic)

		let privateKey: PrivateKey = Utilities.mainnet() ?
				PrivateKey(seed: seed, coin: .mainnet) : PrivateKey(seed: seed, coin: .testnet)

		completion(privateKey, nil)
	}

	func walletAddress(index: Int) throws -> String? {
		var walletAddress: String? = nil
		var walletError: ProvenanceWalletError? = nil

		guard let rootWallet = try fetchRootWalletEntity() else {
			throw ProvenanceWalletError(kind: .rootWalletNotFound, message: "Root Wallet Not Found", messages: nil, underlyingError: nil)
		}
		let key = try decryptWalletKey(rootWallet: rootWallet)
		guard let walletAddress = try address(privateKey: key, index: index) else {
			throw ProvenanceWalletError(kind: .walletAddressError,
			                            message: "Invalid Wallet Index \(index)", messages: nil,
			                            underlyingError: nil)
		}
		return walletAddress
	}

	private func addresses(privateKey: PrivateKey, startIndex: Int, endIndex: Int) throws -> [String?] {
		try (startIndex...endIndex).map({ i in try address(privateKey: privateKey, index: i) })
	}

	private func address(privateKey: PrivateKey, index: Int) throws -> String? {
		do {
			let privateKey = try PrivateKey(bip32Serialized: privateKey.serialize(publicKeyOnly: false))
			// BIP44 key derivation
			// m/44'
			let purpose = privateKey.derived(at: .hardened(44))

			// m/44'/1' or m/44/505'
			let coinType = Utilities.mainnet() ? purpose.derived(at: .hardened(505))
					: purpose.derived(at: .hardened(1))

			// m/44'/1'/0'
			let account = coinType.derived(at: .hardened(0))

			// m/44'/1'/0'/0
			let change = account.derived(at: .notHardened(0))

			//TODO if mainnet unhardened, if testnet harded :|
			// m/44'/1'/0'/0/0
			let firstPrivateKey = Utilities.mainnet() ? change.derived(at: .notHardened(UInt32(index))) :
					change.derived(at: .hardened(UInt32(index)))

			NSLog("\(firstPrivateKey.publicKey.address)")
			return firstPrivateKey.publicKey.address
		} catch {
			Utilities.log(error)
			throw ProvenanceWalletError(
					kind: .walletAddressError, message: "Invalid root wallet", messages: nil, underlyingError: error
			)
		}
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
	func queryAuth(address: String) -> String {

		let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
		defer {
			try? group.syncShutdownGracefully()
		}
		let channel = ClientConnection.insecure(group: group)
		                              .connect(host: "10.0.1.12", port: 9090)

		let client = Cosmos_Auth_V1beta1_QueryClient(channel: channel)
		var request = Cosmos_Auth_V1beta1_QueryAccountRequest()
		request.address = address
		do {

			let account = try client.account(request).response.wait().account

			let baseAccount = try Cosmos_Auth_V1beta1_BaseAccount(serializedData: account.serializedData())
			Utilities.log("\(baseAccount.accountNumber)")
			return baseAccount.textFormatString()
		} catch {
			Utilities.log(error)
		}
		return "nil"

	}

	func queryBank() throws -> Cosmos_Base_V1beta1_Coin {
		guard let address = try fetchAddresses().first?.address else {
			throw ProvenanceWalletError(kind: .walletAddressError, message: "Wallet Address not Found", messages: nil, underlyingError: nil)
		}
		
		let group = PlatformSupport.makeEventLoopGroup(loopCount: 1)
		defer {
			try? group.syncShutdownGracefully()
		}
		let channel = ClientConnection.insecure(group: group)
		                              .connect(host: "10.0.1.12", port: 9090)

		let client = Cosmos_Bank_V1beta1_QueryClient(channel: channel)
		var request = Cosmos_Bank_V1beta1_QueryBalanceRequest()
		request.address = address
		request.denom = "nhash"
		do {

			let balance = try client.balance(request).response.wait().balance

			Utilities.log("\(balance.textFormatString())")
			return balance
		} catch {
			Utilities.log(error)
		}
		return Cosmos_Base_V1beta1_Coin()
	}
}
