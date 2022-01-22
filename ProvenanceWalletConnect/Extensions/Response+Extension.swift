//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import WalletConnectSwift
import ProvWallet
import SwiftyJSON

extension Response {
	static func signature(_ signature: String, for request: Request) -> Response {
		try! Response(url: request.url, value: signature, id: request.id!)
	}

	static func transaction(_ txId: String, for request: Request) -> Response {
		try! Response(url: request.url, value: txId, id: request.id!)
	}

	static func rawTxResponse(_ rawTxResponsePair: RawTxResponsePair, for request: Request) throws -> Response {
		try Utilities.log(rawTxResponsePair.asJsonString())
		try Utilities.log(rawTxResponsePair.asJsonString())
		return try! Response(url: request.url, value: rawTxResponsePair.asJsonString(), id: request.id!)
	}

	static func error(_ error: Any?, for request: Request) -> Response {
		var message = ""
		if let logMessage = error as? String {
			message = logMessage
		} else if let logMessage = error as? NSError {
			message = logMessage.description
		} else if let logMessage = error as? JSON {
			message = logMessage.stringValue
		} else if let logMessage = error as? NSObject {
			message = logMessage.description
		}
		Utilities.log(error)

		return try! Response(url: request.url, errorCode: ResponseError.errorResponse.rawValue,
		                     message: message,
		                     id: request.id)

	}

	static func rawTxErrorResponse(_ rawTxResponsePair: RawTxResponsePair, for request: Request) throws -> Response {
		try Utilities.log(rawTxResponsePair.asJsonString())
		return try! Response(url: request.url, errorCode: ResponseError.requestRejected.rawValue,
		                     message: "\(rawTxResponsePair.txResponse.code) \(rawTxResponsePair.txResponse.codespace) \(rawTxResponsePair.txResponse.info)",
		                     value: rawTxResponsePair.asJsonString(), id: request.id)
	}

}
