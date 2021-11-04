import Foundation

struct ProvenanceWalletError: Error {
	enum ErrorKind {
		case jsonParseError
		case blockchainError
		case apiError
		case bridgeError
		case businessValidationErrors
		case dataPersistence
		case unsupportedAlgorithm
		case keyNotFound
		case publicKeyError
		case invalidDataLength
		case rootWalletNotFound
		case walletAddressError
		case invalidProvenanceMessage
		case unsupportedProvenanceMessage
	}
	let kind: ErrorKind
	let message: String
	let messages: [String]?
	let underlyingError: Error?
}
