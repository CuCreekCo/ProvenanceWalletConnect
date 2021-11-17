//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import WalletConnectSwift
import ProvWallet

extension Response {
	static func signature(_ signature: String, for request: Request) -> Response {
		try! Response(url: request.url, value: signature, id: request.id!)
	}
	static func transaction(_ txId: String, for request: Request) -> Response {
		try! Response(url: request.url, value: txId, id: request.id!)
	}

	static func rawTxResponse(_ rawTxResponsePair: RawTxResponsePair, for request: Request) throws -> Response {
		Utilities.log("rawTxResponse")
		try Utilities.log(rawTxResponsePair.asJsonString())
		return try! Response(url: request.url, value: rawTxResponsePair.asJsonString(), id: request.id!)
	}

}
