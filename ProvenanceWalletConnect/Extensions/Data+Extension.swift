//
// Created by Jason Davidson on 12/20/21.
//

import Foundation

extension Data {
	func toBase64URLWithoutPadding() -> String {
		let base64url = base64EncodedString()
		                    .replacingOccurrences(of: "+", with: "-")
		                    .replacingOccurrences(of: "/", with: "_")
		                    .replacingOccurrences(of: "=", with: "")
		return base64url
	}
}
