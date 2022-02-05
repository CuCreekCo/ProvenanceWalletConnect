//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import ProvWallet
import SwiftProtobuf
import WalletConnectSwift
import SwiftyJSON

class BaseHandler: RequestHandler {
	weak var server: Server!
	weak var walletService: WalletService!
	weak var notificationService: NotificationService!

	init(server: Server, walletService: WalletService,
	     notificationService: NotificationService) {
		self.server = server
		self.walletService = walletService
		self.notificationService = notificationService
	}

	func canHandle(request: Request) -> Bool {
		false
	}

	func handle(request: Request) {
		// to override
		Utilities.log(request)
	}
	
}

class PersonalSignHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "provenance_sign"
	}

	override func handle(request: Request) {
		do {
			let address = try request.address()
			guard address == walletService.defaultAddress() else {
				server.send(
						.error("Wallet address \(walletService.defaultAddress() ?? "null") does not match request address \(address)", for: request))
				return
			}
			notificationService.post(
					NotificationModel(name: Notification.Name.provenanceSign , sender: self, object: request)
			)

		} catch {
			server.send(.error(error, for: request))
			DispatchQueue.main.async {
				Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
			}

			return
		}
	}
}

class SendTransactionHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "provenance_sendTransaction"
	}

	override func handle(request: Request) {
		do {
			Utilities.log(request)

			guard try request.address() == walletService.defaultAddress() else {
				server.send(.error("Wallet address \(walletService.defaultAddress() ?? "null") does not match request address \(try request.address())",
					for: request))
				return
			}

			notificationService.post(
					NotificationModel(name: Notification.Name.provenanceSendTransaction , sender: self, object: request)
			)
			
		} catch {
			Utilities.log(error)
			server.send(.error(error, for: request))
			DispatchQueue.main.async {
				Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
			}
		}
	}

}
