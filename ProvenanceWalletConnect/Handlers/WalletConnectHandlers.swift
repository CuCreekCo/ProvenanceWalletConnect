//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import ProvWallet
import SwiftProtobuf
import WalletConnectSwift

class BaseHandler: RequestHandler {
	weak var controller: UIViewController!
	weak var server: Server!
	weak var walletService: WalletService!

	init(for controller: UIViewController, server: Server, walletService: WalletService) {
		self.controller = controller
		self.server = server
		self.walletService = walletService
	}

	func canHandle(request: Request) -> Bool {
		false
	}

	func handle(request: Request) {
		// to override
		Utilities.log(request)
	}

	func askToSign(request: Request, message: String, sign: @escaping () throws -> String) {
		let onSign = {
			do {
				let signature = try sign()
				self.server.send(.signature(signature, for: request))
			} catch {
				Utilities.log(error)
				self.server.send(.reject(request))
			}
		}
		let onCancel = {
			self.server.send(.reject(request))
		}
		DispatchQueue.main.async {
			UIAlertController.showShouldSign(from: self.controller,
			                                 title: "Request to sign a message",
			                                 message: message,
			                                 onSign: onSign,
			                                 onCancel: onCancel)
		}
	}

	func askToSend(request: Request, message: Message, displayMessage: String, gasFee: UInt64, send: @escaping () throws -> Cosmos_Base_Abci_V1beta1_TxResponse) {
		let onSend = {
			do {
				
				let txResponse = try send()
				if (txResponse.code == 0) {
					Utilities.log(txResponse.rawLog)
					self.server.send(.transaction(txResponse.txhash, for: request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Success", message: "\(txResponse.rawLog)", completionHandler: nil)
					}

				} else {
					Utilities.log(txResponse.rawLog)
					self.server.send(.reject(request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Error", message: "\(txResponse.rawLog)", completionHandler: nil)
					}

				}
			} catch {
				Utilities.log(error)
				self.server.send(.reject(request))
				DispatchQueue.main.async {
					Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
				}
			}
		}
		let onCancel = {
			self.server.send(.reject(request))
		}
		DispatchQueue.main.async {
			UIAlertController.showShouldSend(from: self.controller,
			                                 title: "Send Message",
			                                 message: "\(displayMessage) will cost \(gasFee)\(Tx.baseDenom)",
			                                 onSend: onSend,
			                                 onCancel: onCancel)
		}
	}

}

class PersonalSignHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "provenance_sign"
	}

	override func handle(request: Request) {
		do {
			let messageBytes = try request.parameter(of: String.self, at: 1)
			let address = try request.parameter(of: String.self, at: 0)

			guard address == walletService.defaultAddress() else {
				server.send(.reject(request))
				return
			}

			let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes

			askToSign(request: request, message: decodedMessage) {
				let messageData = Data(hex: messageBytes).sha256()
				return try self.walletService.sign(messageData: messageData).toHexString()
			}
		} catch {
			server.send(.invalid(request))
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
			let address = try request.parameter(of: String.self, at: 0)
			let (type, message) = try decodeMessage(request: request)

			let signingKey = try walletService.defaultPrivateKey()
			//TODO assert signing key == address in request
			
			let gasEstimate = try walletService.estimateTx(signingKey: signingKey, message: message)
			let displayMessage = try message.jsonString()
			var gas = (Double(gasEstimate.gasUsed) * 1.3)
			gas.round(.up)

			let gasFee = UInt64(gas) * Tx.gasPrice

			askToSend(request: request, message: message, displayMessage: displayMessage, gasFee: gasFee) {
				try self.walletService.broadcastTx(signingKey: signingKey, message: message, gasEstimate: gasEstimate)
			}
		} catch {
			Utilities.log(error)
			server.send(.invalid(request))
			DispatchQueue.main.async {
				Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
			}

		}
	}

	private func decodeMessage(request: Request) throws -> (String, Message) {
		let msgHex = try request.parameter(of: String.self, at: 1)
		let msgData = Data(hex: msgHex)
		guard let msgB64 = Data(base64Encoded: msgData) else {
			throw ProvenanceWalletError(kind: .invalidProvenanceMessage,
			                            message: "request contains invalid message information", messages: nil,
			                            underlyingError: nil)
		}
		let msgAny = try Google_Protobuf_Any(serializedData: msgB64)

		Utilities.log(msgAny.typeURL)

		switch msgAny.typeURL {
			case "/cosmos.bank.v1beta1.MsgSend":
				return (msgAny.typeURL, try Cosmos_Bank_V1beta1_MsgSend(unpackingAny: msgAny))
			default:
				throw ProvenanceWalletError(kind: .unsupportedProvenanceMessage,
				                            message: "wallet does not support \(msgAny.typeURL)",
				                            messages: nil,
				                            underlyingError: nil)
		}


	}
}