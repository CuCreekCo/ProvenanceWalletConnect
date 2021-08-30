//
// Created by Jason Davidson on 8/29/21.
//

import Foundation

class CipherService: NSObject {

	static func encrypt(keyName: String, plainText: String) throws -> Data {
		let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
		guard let key = loadKey(name: keyName) else {
			throw ProvenanceWalletError(kind: .keyNotFound, message: "\(keyName) not found", messages: nil,
			                            underlyingError: nil)
		}
		guard let publicKey: SecKey = SecKeyCopyPublicKey(key) else {
			throw ProvenanceWalletError(kind: .publicKeyError, message: "Could not create public key", messages: nil,
			                            underlyingError: nil)
		}

		guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
			throw ProvenanceWalletError(kind: .unsupportedAlgorithm, message: "Encryption Algorithm is not supported",
			                            messages: nil, underlyingError: nil)
		}
		var error: Unmanaged<CFError>?

		guard let cipherText = SecKeyCreateEncryptedData(publicKey,
		                                                 algorithm,
		                                                 plainText.data(using: .utf8)! as CFData,
		                                                 &error) as Data? else {
			throw error!.takeRetainedValue() as Error
		}
		return cipherText
	}

	static func decrypt(keyName: String, cipherText: Data) throws -> Data {
		guard let key = loadKey(name: keyName) else {
			throw ProvenanceWalletError(kind: .keyNotFound, message: "\(keyName) not found", messages: nil,
			                            underlyingError: nil)
		}

		let algorithm: SecKeyAlgorithm = .eciesEncryptionCofactorVariableIVX963SHA256AESGCM
		guard SecKeyIsAlgorithmSupported(key, .decrypt, algorithm) else {
			throw ProvenanceWalletError(kind: .unsupportedAlgorithm, message: "Decryption Algorithm is not supported",
			                            messages: nil, underlyingError: nil)
		}

		var error: Unmanaged<CFError>?

		guard let plainText = SecKeyCreateDecryptedData(key, algorithm, cipherText as CFData,
		                                                &error) as Data? else {
			throw error!.takeRetainedValue() as Error
		}
		return plainText
	}

	/**
	 
	 - Returns: private key, public key tuple
	 - Throws: cipher errors
	 */
	static func createAndStoreKey(name: String) throws -> (SecKey, SecKey) {

		let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
		                                             kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
		                                             [.privateKeyUsage, .biometryCurrentSet],
		                                             nil)!
		let tag = name.data(using: .utf8)!
		let attributes: [String: Any] = [
			kSecAttrKeyType as String: kSecAttrKeyTypeEC,
			kSecAttrKeySizeInBits as String: 256,
			kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
			kSecPrivateKeyAttrs as String: [
				kSecAttrIsPermanent as String: true,
				kSecAttrApplicationTag as String: tag,
				kSecAttrAccessControl as String: access
			]
		]

		var error: Unmanaged<CFError>?
		guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
			throw error!.takeRetainedValue() as Error
		}
		guard let pubKey: SecKey = SecKeyCopyPublicKey(privateKey) else {
			throw ProvenanceWalletError(kind: .publicKeyError, message: "Could not create public key", messages: nil,
			                            underlyingError: nil)
		}
		return (privateKey, pubKey)
	}

	static func loadKey(name: String) -> SecKey? {
		let tag = name.data(using: .utf8)!
		let query: [String: Any] = [
			kSecClass as String: kSecClassKey,
			kSecAttrApplicationTag as String: tag,
			kSecAttrKeyType as String: kSecAttrKeyTypeEC,
			kSecReturnRef as String: true
		]

		var item: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &item)
		guard status == errSecSuccess else {
			return nil
		}
		return (item as! SecKey)
	}
}
