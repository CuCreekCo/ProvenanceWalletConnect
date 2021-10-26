//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import WalletConnectSwift

class BaseHandler: RequestHandler {
	weak var controller: UIViewController!
	weak var sever: Server!
	weak var walletService: WalletService!

	init(for controller: UIViewController, server: Server, walletService: WalletService) {
		self.controller = controller
		sever = server
		self.walletService = walletService
	}

	func canHandle(request: Request) -> Bool {
		false
	}

	func handle(request: Request) {
		// to override
		Utilities.log(request)
	}

	func askToSign(request: Request, message: String, sign: @escaping () -> String) {
		Utilities.log("askToSign")
		Utilities.log(request)
		Utilities.log(message)
		let onSign = {
			let signature = sign()
			self.sever.send(.signature(signature, for: request))
		}
		let onCancel = {
			self.sever.send(.reject(request))
		}
		DispatchQueue.main.async {
			UIAlertController.showShouldSign(from: self.controller,
			                                 title: "Request to sign a message",
			                                 message: message,
			                                 onSign: onSign,
			                                 onCancel: onCancel)
		}
	}
}

class PersonalSignHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "eth_sign"
	}

	override func handle(request: Request) {
		Utilities.log("askToSign")
		Utilities.log(request)

		do {
			let messageBytes = try request.parameter(of: String.self, at: 1)
			let address = try request.parameter(of: String.self, at: 0)

			guard address == walletService.defaultAddress() else {
				sever.send(.reject(request))
				return
			}

			let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes

			askToSign(request: request, message: decodedMessage) {
				let personalMessageData = self.personalMessageData(messageData: Data(hex: messageBytes))
				let (v, r, s) = (0, Data(), Data()) //try! self.privateKey.sign(message: .init(hex: personalMessageData.toHexString()))
				return "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16) // v in [0, 1]
			}
		} catch {
			sever.send(.invalid(request))
			return
		}
	}

	private func personalMessageData(messageData: Data) -> Data {
		Utilities.log("personalMessageData")
		Utilities.log(messageData)

		let prefix = "\u{19}Ethereum Signed Message:\n"
		let prefixData = (prefix + String(messageData.count)).data(using: .ascii)!
		return prefixData + messageData
	}
}

class SignTransactionHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "eth_signTransaction"
	}

	override func handle(request: Request) {
		do {
			Utilities.log(request)
			//TODO change to Cosmos type
			/*
			let transaction = try request.parameter(of: EthereumTransaction.self, at: 0)
			guard transaction.from == walletService.defaultAddress() else {
				sever.send(.reject(request))
				return
			}


			 */
			askToSign(request: request, message: request.jsonString) {
				/*
				let signedTx = try! transaction.sign(with: self.privateKey, chainId: 4)
				let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
				return r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)

				 */
				return "Yo dawg"
			}
		} catch {
			sever.send(.invalid(request))
		}
	}
}
