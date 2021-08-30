//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import WalletConnectSwift

extension Response {
	static func signature(_ signature: String, for request: Request) -> Response {
		try! Response(url: request.url, value: signature, id: request.id!)
	}
}
