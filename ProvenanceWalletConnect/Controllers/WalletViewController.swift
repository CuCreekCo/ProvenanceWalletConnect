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

class WalletViewController: UIViewController, ScannerViewControllerDelegate, ServerDelegate {

	var server: Server!
	var session: Session!
	//TODO what is this really?
	let sessionKey = "sessionKey"

	var walletConnectQueue: [(Notification.Name, Request)] = []

// MARK: - IBOutlets
	@IBOutlet var viewTitle: UIView!
	@IBOutlet var labelTitle: UILabel!
	@IBOutlet var labelBalance: UILabel!
	@IBOutlet var collectionView: UICollectionView!
	@IBOutlet var connectedAppIcon: UIImageView!
	@IBOutlet var connectedApp: UILabel!
    @IBOutlet weak var connectedAppDetails: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var sendHashButton: UIButton!

// MARK: - IBActions

	@IBAction func disconnectWallet(_ sender: Any) {
		let disconnected = walletService().disconnectWallet()
		if (disconnected) {
			if (session != nil) {
				serverDisconnect();
			}
			onMainThread {
				self.setButtonState([.no_wallet])

			}
		}
	}

    @IBAction func copyAddress(_ sender: Any) {
		let address = labelTitle.text
		UIPasteboard.general.string = address
		Utilities.showAlert(title: "Address Copied", message: "\(address) Copied to clipboard",
		                    completionHandler: nil)
	}

	// MARK: - Refresh methods
	//-------------------------------------------------------------------------------------------------------------------------------------------
	func refreshCollectionView() {

		collectionView.reloadData()
	}

	// MARK: - User actions
	//-------------------------------------------------------------------------------------------------------------------------------------------
	@objc func actionProfile(_ sender: UIButton) {

		print(#function)
		navigationController?.pushViewController(ManageWalletViewController(), animated: true)
	}
	
	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionDisconnectWalletConnect(_ sender: UIButton) {

		print(#function)
		serverDisconnect()
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionWalletConnectInfo(_ sender: UIButton) {

		print(#function)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionConnectWalletConnect(_ sender: UIButton) {

		print(#function)
		let qrCapture = QRCaptureViewController()
		qrCapture.delegate = self
		navigationController?.pushViewController(qrCapture, animated: true)

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

	func setButtonState(_ walletStates: [WalletState], dAppInfo: Session.DAppInfo? = nil) {
		self.connectedApp.text = dAppInfo?.peerMeta.name ?? "--"
		self.connectedAppDetails.text = dAppInfo?.peerMeta.description ?? "--"
		
		if (dAppInfo != nil) {
			self.connectedAppIcon.greenCircle()
		} else {
			self.connectedAppIcon.grayCircle()
		}


		/*

		if (walletStates.contains(.has_wallet)) {
		}
		if (walletStates.contains(.no_wallet)) {
			disconnectWalletConnectTabBarItem.isEnabled = false
			walletConnectTabBarItem.isEnabled = false
		}
		if (walletStates.contains(.walletconnected)) {
			disconnectWalletConnectTabBarItem.isEnabled = true
			walletConnectTabBarItem.isEnabled = false
		}
		if (walletStates.contains(.not_walletconnected)) {
			disconnectWalletConnectTabBarItem.isEnabled = false
			walletConnectTabBarItem.isEnabled = true
		}
		 
		 */
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.leftBarButtonItem = UIBarButtonItem(customView: viewTitle)
		navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.circle.fill"), style: .plain,
		                                                    target: self, action: #selector(actionProfile))

		collectionView.register(UINib(nibName: "WalletViewCell", bundle: Bundle.main),
		                        forCellWithReuseIdentifier: "WalletViewCell")

		configureServer()
		observeWalletConnectRequests()

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let navController = navigationController as? NavigationController {
			navController.setBackground(color: .clear)
		}

		do {
			if (try walletService().fetchRootWalletEntity()) != nil {
				onMainThread {
					self.labelTitle.text = self.walletService().defaultAddress()

                    /*
					do {
						let coin = try self.walletService().queryBank()
						self.labelBalance.text = "\((Int32(coin.amount) ?? 0 )/1000000000)"
					} catch {
						Utilities.log(error)
					}
                    */

					self.setButtonState([.has_wallet])

					if let url = self.applicationOpenURL() {
						if (self.server.openSessions().count > 0) {
							self.disconnectWallet(self)
							self.setButtonState([.not_walletconnected])
						} else {
							self.configureServer()
							self.observeWalletConnectRequests()
						}

						//let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
						let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
						Utilities.log(wc)
						self.didScan(wc)
						self.clearApplicationOpenURL()
					} else {
						if (self.server.openSessions().count > 0) {
							self.setButtonState([.walletconnected], dAppInfo: self.session.dAppInfo)
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

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		do {

			let coin =  try walletService().queryBank()
			onMainThread {
				self.labelBalance.text = "\(Double(coin.amount) ?? 0.0 / 1000000000)"
			}
		} catch {
			Utilities.log(error)
		}
	}

	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)

		if let navBar = navigationController as? NavigationController {
			navBar.setNavigationBar()
		}
	}

}

// MARK: - UICollectionViewDataSource
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension WalletViewController: UICollectionViewDataSource {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func numberOfSections(in collectionView: UICollectionView) -> Int {

		return 1
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

		walletConnectQueue.count
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WalletViewCell", for: indexPath) as! WalletViewCell
		cell.bindData(index: indexPath, data: walletConnectQueue[indexPath.row])
		return cell
	}
}

// MARK: - UICollectionViewDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension WalletViewController: UICollectionViewDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		print(#function)
		do {
			let requestType = walletConnectQueue[indexPath.row].0
			let request: Request = walletConnectQueue[indexPath.row].1

			if (requestType == Notification.Name.provenanceSendTransaction) {
				onMainThread {
					self.activityIndicator.startAnimating()
				}
				
				let (type, message) = try request.decodeMessage()

				let signingKey = try self.walletService().defaultPrivateKey()
				let gasEstimate = try self.walletService().estimateTx(signingKey: signingKey, message: message)
				let displayMessage = try message.jsonString()
				var gas = (Double(gasEstimate.gasUsed) * 1.3)
				gas.round(.up)

				let gasFee = UInt64(gas) * Tx.gasPrice

				askToSend(request: request, message: message, description: try request.description(),
				          displayMessage: displayMessage,
				          gasFee: gasFee, send: { [self]
					return try self.walletService()
					               .broadcastTx(signingKey: signingKey, message: message, gasEstimate: gasEstimate)
				})
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
}

// MARK: - UICollectionViewDelegateFlowLayout
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension WalletViewController: UICollectionViewDelegateFlowLayout {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

		let height = (collectionView.frame.size.height-20)
		return CGSize(width: 70, height: height)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {

		return 5
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

		return 5
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

		return UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
	}
}

// MARK: - UIScrollViewDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension WalletViewController: UIScrollViewDelegate {

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func scrollViewDidScroll(_ scrollView: UIScrollView) {

		if scrollView.tag == 11 {
			if let navController = navigationController as? NavigationController {
				if (scrollView.contentOffset.y > sendHashButton.frame.origin.y) {
					navController.setBackground(color: .systemBackground)
				} else {
					navController.setBackground(color: .clear)
				}
			}
		}
	}
}

// MARK: - WalletConnect
extension WalletViewController {
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
			Utilities.log("Connected to \(self.session.dAppInfo.peerMeta.name)")
			self.setButtonState([.walletconnected], dAppInfo: self.session.dAppInfo)
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

	func serverDisconnect() {
		do {
			if(server == nil || self.session == nil) {
				self.setButtonState([.not_walletconnected])
				return
			}
			try server.disconnect(from: self.session)
			onMainThread {
				self.setButtonState([.not_walletconnected])
			}
		} catch {
			Utilities.log(error)
		}
	}
}

// MARK: - Observers
extension WalletViewController {
	@objc func handleWalletConnectRequest(notification: Notification) {
		let notificationModel: NotificationModel = notificationService().unwrap(notification)
		Utilities.log("WalletViewController got NotificationModel \(notificationModel.name.rawValue)")
		walletConnectQueue.append((notification.name, notificationModel.object as! Request))

		onMainThread {
			self.refreshCollectionView()
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
}
// MARK: - UI Prompting
extension WalletViewController {
	func askToSign(request: Request, description: String, message: String, sign: @escaping () throws -> String) {
		let onSign = {
			do {
				let signature = try sign()
				self.server.send(.signature(signature, for: request))
			} catch {
				Utilities.log(error)
				self.server.send(.error(error, for: request))
			}
			self.removeFromQueue(request: request)
		}
		let onCancel = {
			self.server.send(.reject(request))
			self.removeFromQueue(request: request)
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
						self.activityIndicator.stopAnimating()
					}

				} else {
					Utilities.log(txResponse.rawLog)
					try self.server.send(.rawTxErrorResponse(rawTxPair, for: request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Error", message: "\(txResponse.rawLog)", completionHandler: nil)
						self.activityIndicator.stopAnimating()
					}

				}
			} catch {
				Utilities.log(error)
				self.server.send(.error(error, for: request))
				DispatchQueue.main.async {
					Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
					self.activityIndicator.stopAnimating()
				}
			}
			self.removeFromQueue(request: request)
		}
		let onCancel = {
			self.server.send(.reject(request))
			self.removeFromQueue(request: request)
			self.activityIndicator.stopAnimating()
		}
		onMainThread {
			UIAlertController.showShouldSend(from: self,
			                                 title: description,
			                                 message: "\(displayMessage) will cost \(gasFee)\(Tx.baseDenom)",
			                                 onSend: onSend,
			                                 onCancel: onCancel)
		}
	}
}

// MARK: - manage walletConnectQueue
extension WalletViewController {
	func removeFromQueue(request: Request) {
		let index = walletConnectQueue.firstIndex(where: {$0.1 === request })
		if (index != nil) {
			walletConnectQueue.remove(at: index!)
			onMainThread {
				self.refreshCollectionView()
			}
		}
	}
}

