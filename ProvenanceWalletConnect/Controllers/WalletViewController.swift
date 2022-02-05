//
//  WalletViewController.swift
//  ProvenanceWalletConnect
//
//  Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import CoreData
import ProvWallet
import SwiftProtobuf
import WalletConnectSwift

enum WalletState {
	case no_wallet
	case has_wallet
	case walletconnected
	case not_walletconnected
}

class WalletViewController: UIViewController,
		UITableViewDataSource,
		ScannerViewControllerDelegate, ServerDelegate {

	var server: Server!
	var session: Session!
	//TODO what is this really?
	let sessionKey = "sessionKey"

	var walletConnectQueue: [(Notification.Name, Request)] = []

// MARK: - IBOutlets

	@IBOutlet weak var disconnectWalletButton: UIButton!
	@IBOutlet weak var connectWalletButton: UIButton!
	@IBOutlet weak var scanWalletConnectQRButton: UIButton!
	@IBOutlet weak var disconnectWalletConnectButton: UIButton!
	@IBOutlet weak var connectedWalletAddress: UITextField!
	@IBOutlet weak var walletConnectPeerLabel: UILabel!
	@IBOutlet weak var walletConnectTable: UITableView!

// MARK: - IBActions

	@IBAction func disconnectWallet(_ sender: Any) {
		let disconnected = walletService().disconnectWallet()
		if (disconnected) {
			if (session != nil) {
				serverDisconnect(session: session);
			}
			onMainThread {
				self.setButtonState([.no_wallet])
			}
		}
	}

	@IBAction func disconnectWalletConnect(_ sender: Any) {
		serverDisconnect(session: session);
	}

	@IBAction func didTouchUpAddress(_ sender: Any) {
		let address = connectedWalletAddress.text
		UIPasteboard.general.string = address
		Utilities.showAlert(title: "Address Copied", message: "\(address) Copied to clipboard",
		                    completionHandler: nil)

	}

// MARK: - UI
	func observeWalletConnectRequests() {
		notificationService().observe(ObserverModel(name: Notification.Name.provenanceSendTransaction,
		                                            receiver: self,
		                                            selector: #selector(handleWalletConnectRequest)))
		notificationService().observe(ObserverModel(name: Notification.Name.provenanceSign,
		                                            receiver: self,
		                                            selector: #selector(handleWalletConnectRequest)))
	}

	func setButtonState(_ walletStates: [WalletState]) {
		if (walletStates.contains(.has_wallet)) {
			connectWalletButton.isHidden = true
			disconnectWalletButton.isHidden = false
		}
		if (walletStates.contains(.no_wallet)) {
			connectWalletButton.isHidden = false
			disconnectWalletButton.isHidden = true
			scanWalletConnectQRButton.isHidden = true
			disconnectWalletConnectButton.isHidden = true
		}
		if (walletStates.contains(.walletconnected)) {
			disconnectWalletConnectButton.isHidden = false
			scanWalletConnectQRButton.isHidden = true
		}
		if (walletStates.contains(.not_walletconnected)) {
			scanWalletConnectQRButton.isHidden = false
			disconnectWalletConnectButton.isHidden = true
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.configureServer()
		self.observeWalletConnectRequests()

		do {
			if (try walletService().fetchRootWalletEntity()) != nil {
				onMainThread {
					self.connectedWalletAddress.text = self.walletService().defaultAddress()

					self.setButtonState([.has_wallet])

					if let url = self.applicationOpenURL() {
						if (self.server.openSessions().count > 0) {
							self.disconnectWallet(self)
							self.setButtonState([.not_walletconnected])
						} else {
							self.configureServer()
							self.observeWalletConnectRequests()
						}

						let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
						Utilities.log(wc)
						self.didScan(wc)
					} else {
						if (self.server.openSessions().count > 0) {
							self.setButtonState([.walletconnected])
						} else {
							self.setButtonState([.not_walletconnected])
						}
					}
				}

			} else {
				onMainThread {
					self.setButtonState([.no_wallet])
				}
			}

		} catch {
			Utilities.log(error)
		}
	}

// MARK: - UITable
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return walletConnectQueue.count;
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "WalletConnectTableCell", for: indexPath)
		do {
			cell.textLabel?.text = try walletConnectQueue[indexPath.row].1.description()
		} catch {
			cell.textLabel?.text = "\(error)"
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

		do {
			let requestType = walletConnectQueue[indexPath.row].0
			let request: Request = walletConnectQueue[indexPath.row].1

			if (requestType == Notification.Name.provenanceSendTransaction) {
				let (type, message) = try decodeMessage(request: request)

				let signingKey = try walletService().defaultPrivateKey()
				let gasEstimate = try walletService().estimateTx(signingKey: signingKey, message: message)
				let displayMessage = try message.jsonString()
				var gas = (Double(gasEstimate.gasUsed) * 1.3)
				gas.round(.up)

				let gasFee = UInt64(gas) * Tx.gasPrice

				askToSend(request: request, message: message, description: try request.description(),
				          displayMessage: displayMessage,
				          gasFee: gasFee) {
					try self.walletService()
					        .broadcastTx(signingKey: signingKey, message: message, gasEstimate: gasEstimate)
				}
			} else {
				let description = try request.description()
				let messageBytes = try request.message()
				let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes
				
				askToSign(request: request, description: description, message: decodedMessage) {
					let messageData = Data(hex: messageBytes).sha256()
					return try self.walletService().sign(messageData: messageData).toHexString()
				}
			}
		} catch {
			Utilities.log("\(error)")
			onMainThread {
				Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
			}
		}


	}

// MARK: - WalletConnect

	private func configureServer() {
		server = Server(delegate: self)
		server.register(handler: PersonalSignHandler(server: server, walletService: walletService(),
		                                             notificationService: notificationService()))
		server.register(handler: SendTransactionHandler(server: server, walletService: walletService(),
		                                                notificationService: notificationService()))
		if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
		   let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
			try? server.reconnect(to: session)
		}
	}

	func server(_ server: Server, didFailToConnect url: WCURL) {
		onMainThread {
			UIAlertController.showFailedToConnect(from: self)
		}
	}

	func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
		var publicKey: String = ""
		var signedJWT: String = ""

		do {
			let privateKey = try walletService().defaultPrivateKey()
			publicKey = privateKey.publicKey.compressedPublicKey
			                      .toBase64URLWithoutPadding()

			Utilities.log("Public key \(publicKey)")

			signedJWT = try walletService().signed_jwt(privateKey: privateKey)
			Utilities.log("signed JWT \(signedJWT)")

		} catch {
			Utilities.log(error)
		}

		let walletMeta = Session.ClientMeta(name: "Unicorn Sparkle",
		                                    description: "Provenance Sparkly Unicorn Wallet",
		                                    icons: [],
		                                    url: URL(string: "https://provenance.io")!)
		let walletInfo = Session.WalletInfo(approved: true,
		                                    accounts: [
			                                    walletService().defaultAddress() ?? "UNKNOWN",
			                                    publicKey,
			                                    signedJWT
		                                    ],
		                                    chainId: 4,
		                                    peerId: UUID().uuidString,
		                                    peerMeta: walletMeta)
		onMainThread {
			UIAlertController.showShouldStart(from: self, clientName: session.dAppInfo.peerMeta.name, onStart: {
				completion(walletInfo)
			}, onClose: {
				completion(
						Session.WalletInfo(approved: false, accounts: [], chainId: 4, peerId: "", peerMeta: walletMeta))
				//self.scanQRCodeButton.isEnabled = true
			})
		}
	}

	func server(_ server: Server, didConnect session: Session) {
		self.session = session
		let sessionData = try! JSONEncoder().encode(session)
		UserDefaults.standard.set(sessionData, forKey: sessionKey)
		onMainThread {
			Utilities.log("Connected to \(session.dAppInfo.peerMeta.name)")
			self.setButtonState([.walletconnected])
			self.walletConnectPeerLabel.text = session.dAppInfo.peerMeta.name
		}
	}

	func server(_ server: Server, didDisconnect session: Session) {
		UserDefaults.standard.removeObject(forKey: sessionKey)
		onMainThread {
			self.setButtonState([.not_walletconnected])
			Utilities.log("Disconnected")
		}
	}

	func server(_ server: Server, didUpdate session: Session) {
		// no-op
	}

	func serverDisconnect(session: Session) {
		do {
			try server.disconnect(from: session)
		} catch {
			Utilities.log(error)
		}
	}

// MARK: - Observers
	@objc func handleWalletConnectRequest(notification: Notification) {
		let notificationModel: NotificationModel = notificationService().unwrap(notification)
		Utilities.log("WalletViewController got NotificationModel \(notificationModel.name.rawValue)")
		walletConnectQueue.append((notification.name, notificationModel.object as! Request))

		onMainThread {
			self.walletConnectTable.reloadData()
		}
	}

// MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let nextVC: QRCaptureViewController = segue.destination as? QRCaptureViewController {
			nextVC.delegate = self
		}

	}

// MARK: - QR Scanning
	func didScan(_ code: String) {
		guard let url = WCURL(code) else {
			return
		}
		do {
			try server.connect(to: url)
			setButtonState([.walletconnected])
		} catch {
			Utilities.log(error)
			setButtonState([.not_walletconnected])
			return
		}
	}

// MARK: - UI Prompting

	func askToSign(request: Request, description: String, message: String, sign: @escaping () throws -> String) {
		let onSign = {
			do {
				let signature = try sign()
				self.server.send(.signature(signature, for: request))
			} catch {
				Utilities.log(error)
				self.server.send(.error(error, for: request))
			}
		}
		let onCancel = {
			self.server.send(.reject(request))
		}
		onMainThread {
			UIAlertController.showShouldSign(from: self,
			                                 title: description,
			                                 message: message,
			                                 onSign: onSign,
			                                 onCancel: onCancel)
		}
	}

	func askToSend(request: Request, message: Message, description: String,
	               displayMessage: String, gasFee: UInt64, send: @escaping () throws -> RawTxResponsePair) {
		let onSend = {
			do {

				let rawTxPair = try send()
				let txResponse = rawTxPair.txResponse
				if (txResponse.code == 0) {
					Utilities.log(txResponse.rawLog)
					try self.server.send(.rawTxResponse(rawTxPair, for: request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Success", message: "\(txResponse.rawLog)", completionHandler: nil)
					}

				} else {
					Utilities.log(txResponse.rawLog)
					try self.server.send(.rawTxErrorResponse(rawTxPair, for: request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Error", message: "\(txResponse.rawLog)", completionHandler: nil)
					}

				}
			} catch {
				Utilities.log(error)
				self.server.send(.error(error, for: request))
				DispatchQueue.main.async {
					Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
				}
			}
		}
		let onCancel = {
			self.server.send(.reject(request))
		}
		onMainThread {
			UIAlertController.showShouldSend(from: self,
			                                 title: description,
			                                 message: "\(displayMessage) will cost \(gasFee)\(Tx.baseDenom)",
			                                 onSend: onSend,
			                                 onCancel: onCancel)
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

		/*
		 Cosmos: https://buf.build/cosmos/cosmos-sdk/docs/main
		 CosmWasm Messages: https://github.com/CosmWasm/wasmd/blob/master/docs/proto/proto-docs.md
         Provenance Messages: https://github.com/provenance-io/provenance/blob/main/docs/proto-docs.md
		 */
		switch msgAny.typeURL {

				/* Cosmos Messages */
			case "/cosmos.authz.v1beta1.MsgGrant":
				return (msgAny.typeURL, try Cosmos_Authz_V1beta1_MsgGrant(unpackingAny: msgAny))
			case "/cosmos.authz.v1beta1.MsgExec":
				return (msgAny.typeURL, try Cosmos_Authz_V1beta1_MsgExec(unpackingAny: msgAny))
			case "/cosmos.authz.v1beta1.MsgRevoke":
				return (msgAny.typeURL, try Cosmos_Authz_V1beta1_MsgRevoke(unpackingAny: msgAny))

			case "/cosmos.bank.v1beta1.MsgMultiSend":
				return (msgAny.typeURL, try Cosmos_Bank_V1beta1_MsgMultiSend(unpackingAny: msgAny))

			case "/cosmos.crisis.v1beta1.MsgVerifyInvariant":
				return (msgAny.typeURL, try Cosmos_Crisis_V1beta1_MsgVerifyInvariant(unpackingAny: msgAny))

			case "/cosmos.distribution.v1beta1.MsgSetWithdrawAddress":
				return (msgAny.typeURL, try Cosmos_Distribution_V1beta1_MsgSetWithdrawAddress(unpackingAny: msgAny))
			case "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward":
				return (msgAny.typeURL,
						try Cosmos_Distribution_V1beta1_MsgWithdrawDelegatorReward(unpackingAny: msgAny))
			case "/cosmos.distribution.v1beta1.MsgWithdrawValidatorCommission":
				return (msgAny.typeURL,
						try Cosmos_Distribution_V1beta1_MsgWithdrawValidatorCommission(unpackingAny: msgAny))
			case "/cosmos.distribution.v1beta1.MsgFundCommunityPool":
				return (msgAny.typeURL, try Cosmos_Distribution_V1beta1_MsgFundCommunityPool(unpackingAny: msgAny))

			case "/cosmos.evidence.v1beta1.MsgSubmitEvidence":
				return (msgAny.typeURL, try Cosmos_Evidence_V1beta1_MsgSubmitEvidence(unpackingAny: msgAny))

			case "/cosmos.feegrant.v1beta1.MsgGrantAllowance":
				return (msgAny.typeURL, try Cosmos_Feegrant_V1beta1_MsgGrantAllowance(unpackingAny: msgAny))
			case "/cosmos.feegrant.v1beta1.MsgRevokeAllowance":
				return (msgAny.typeURL, try Cosmos_Feegrant_V1beta1_MsgRevokeAllowance(unpackingAny: msgAny))

			case "/cosmos.gov.v1beta1.MsgSubmitProposal":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgSubmitProposal(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta1.MsgVote":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVote(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta1.MsgVoteWeighted":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVoteWeighted(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta1.MsgDeposit":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgDeposit(unpackingAny: msgAny))

			case "/cosmos.gov.v1beta2.MsgSubmitProposal":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgSubmitProposal(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta2.MsgVote":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVote(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta2.MsgVoteWeighted":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVoteWeighted(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta2.MsgDeposit":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgDeposit(unpackingAny: msgAny))

				/* future
			case "/cosmos.group.v1beta1.MsgCreateGroupRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgCreateGroupRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupMembersRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupMembersRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAdminRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAdminRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupMetadataRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupMetadataRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgCreateGroupAccountRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgCreateGroupAccountRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountAdminRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAccountAdminRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountDecisionPolicyRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAccountDecisionPolicyRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountMetadataRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAccountMetadataRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgCreateProposalRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgCreateProposalRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgVoteRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgVoteRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgExecRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgExecRequest(unpackingAny: msgAny))

			case "/cosmos.nft.v1beta1.MsgSend":
				return(msgAny.typeURL, try Cosmos_Nft_V1beta1_MsgSend(unpackingAny: msgAny))


				 */
			case "/cosmos.slashing.v1beta1.MsgUnjail":
				return (msgAny.typeURL, try Cosmos_Slashing_V1beta1_MsgUnjail(unpackingAny: msgAny))

			case "/cosmos.staking.v1beta1.MsgCreateValidator":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgCreateValidator(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgEditValidator":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgEditValidator(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgDelegate":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgDelegate(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgBeginRedelegate":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgBeginRedelegate(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgUndelegate":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgUndelegate(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.GetTxsEventRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_GetTxsEventRequest(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.BroadcastTxRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_BroadcastTxRequest(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.SimulateRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_SimulateRequest(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.GetTxRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_GetTxRequest(unpackingAny: msgAny))

			case "/cosmos.vesting.v1beta1.MsgCreateVestingAccount":
				return (msgAny.typeURL, try Cosmos_Vesting_V1beta1_MsgCreateVestingAccount(unpackingAny: msgAny))
				/* future
			case "/cosmos.vesting.v1beta1.MsgCreatePeriodicVestingAccount":
				return(msgAny.typeURL, try Cosmos_Vesting_V1beta1_MsgCreatePeriodicVestingAccount(unpackingAny: msgAny))
				 */
			case "/cosmos.bank.v1beta1.MsgSend":
				return (msgAny.typeURL, try Cosmos_Bank_V1beta1_MsgSend(unpackingAny: msgAny))

				/* Provenance Messages */

			case "/provenance.attribute.v1.MsgAddAttributeRequest":
				return (msgAny.typeURL, try Provenance_Attribute_V1_MsgAddAttributeRequest(unpackingAny: msgAny))
			case "/provenance.attribute.v1.MsgDeleteAttributeRequest":
				return (msgAny.typeURL, try Provenance_Attribute_V1_MsgDeleteAttributeRequest(unpackingAny: msgAny))
			case "/provenance.attribute.v1.MsgDeleteDistinctAttributeRequest":
				return (msgAny.typeURL,
						try Provenance_Attribute_V1_MsgDeleteDistinctAttributeRequest(unpackingAny: msgAny))
			case "/provenance.attribute.v1.MsgUpdateAttributeRequest":
				return (msgAny.typeURL, try Provenance_Attribute_V1_MsgUpdateAttributeRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgActivateRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgActivateRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgAddAccessRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgAddAccessRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgAddMarkerRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgAddMarkerRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgBurnRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgBurnRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgCancelRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgCancelRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgDeleteAccessRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgDeleteAccessRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgDeleteRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgDeleteRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgFinalizeRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgFinalizeRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgMintRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgMintRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgSetDenomMetadataRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgSetDenomMetadataRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgTransferRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgTransferRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgWithdrawRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgWithdrawRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgAddContractSpecToScopeSpecRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgAddContractSpecToScopeSpecRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgAddScopeDataAccessRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgAddScopeDataAccessRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgAddScopeOwnerRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgAddScopeOwnerRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgBindOSLocatorRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgBindOSLocatorRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteContractSpecFromScopeSpecRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteContractSpecFromScopeSpecRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteContractSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteOSLocatorRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteOSLocatorRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteRecordRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteRecordRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteRecordSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeDataAccessRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteScopeDataAccessRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeOwnerRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteScopeOwnerRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteScopeRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgModifyOSLocatorRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgModifyOSLocatorRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgP8eMemorializeContractRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgP8eMemorializeContractRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteContractSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgWriteContractSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteP8eContractSpecRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteRecordRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteRecordRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteRecordSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteScopeRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteScopeRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteScopeSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteSessionRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteSessionRequest(unpackingAny: msgAny))
			case "/provenance.name.v1.MsgBindNameRequest":
				return (msgAny.typeURL, try Provenance_Name_V1_MsgBindNameRequest(unpackingAny: msgAny))
			case "/provenance.name.v1.MsgDeleteNameRequest":
				return (msgAny.typeURL, try Provenance_Name_V1_MsgDeleteNameRequest(unpackingAny: msgAny))

				/* CosmWasm Messages */

			case "/cosmwasm.wasm.v1.MsgClearAdmin":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgClearAdmin(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgExecuteContract":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgExecuteContract(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgInstantiateContract":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgInstantiateContract(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgMigrateContract":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgMigrateContract(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgStoreCode":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgStoreCode(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgUpdateAdmin":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgUpdateAdmin(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgUpdateAdmin":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_TxBody(unpackingAny: msgAny))
			default:
				throw ProvenanceWalletError(kind: .unsupportedProvenanceMessage,
				                            message: "wallet does not support \(msgAny.typeURL)",
				                            messages: nil,
				                            underlyingError: nil)
		}


	}

}

