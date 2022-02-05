//
// Created by Jason Davidson on 2/4/22.
//

import Foundation
import WalletConnectSwift
import SwiftyJSON

extension Request {
	func message() throws -> String {
		try self.parameter(of: String.self, at: 1)
	}
	func metadata() throws -> String {
		try self.parameter(of: String.self, at: 0)
	}
	func metadataJSON() throws -> JSON {
		JSON.init(parseJSON: try metadata());
	}
	func description() throws -> String {
		try metadataJSON()["description"].stringValue
	}
	func address() throws -> String {
		try metadataJSON()["address"].stringValue
	}
}

