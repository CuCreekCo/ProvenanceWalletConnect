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

class WalletViewController: UIViewController, ScannerViewControllerDelegate {

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
			walletConnectService().disconnect()
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
	func observeWalletConnect() {
		notificationService().observe(ObserverModel(name: Notification.Name.provenanceSendTransaction,
		                                            receiver: self,
		                                            selector: #selector(handleWalletConnectRequest)))
		notificationService().observe(ObserverModel(name: Notification.Name.provenanceSign,
		                                            receiver: self,
		                                            selector: #selector(handleWalletConnectRequest)))

		notificationService().observe(ObserverModel(name: Notification.Name.wcDidConnect,
				receiver: self,
				selector: #selector(handleWcDidConnect)))

		notificationService().observe(ObserverModel(name: Notification.Name.wcDidDisconnect,
				receiver: self,
				selector: #selector(handleWcDidDisconnect)))

		notificationService().observe(ObserverModel(name: Notification.Name.wcShouldStart,
				receiver: self,
				selector: #selector(handleWcShouldStart)))

		notificationService().observe(ObserverModel(name: Notification.Name.wcConnectFail,
				receiver: self,
				selector: #selector(handleWcDidFailToConnect)))

		notificationService().observe(ObserverModel(name: Notification.Name.wcDidUpdate,
				receiver: self,
				selector: #selector(handleWcDidUpdate)))

	}

	func setButtonState(_ walletStates: [WalletState], dAppInfo: Session.DAppInfo? = nil) {
		connectedApp.text = walletConnectService().dAppName() ?? "--"
		connectedAppDetails.text = walletConnectService().dAppDescription() ?? "--"
		
		if (dAppInfo != nil) {
			connectedAppIcon.greenCircle()
		} else {
			connectedAppIcon.grayCircle()
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

		observeWalletConnect()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if let navController = navigationController as? NavigationController {
			navController.setBackground(color: .clear)
		}

		do {
			if (try walletService().fetchRootWalletEntity()) != nil {
				onMainThread { [self]
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
						if (self.walletConnectService().openSessions() > 0) {
							self.disconnectWallet(self)
							self.setButtonState([.not_walletconnected])
						} else {
							self.walletConnectService().reconnect()
							self.observeWalletConnect()
						}

						//let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
						let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
						Utilities.log(wc)
						self.didScan(wc)
						self.clearApplicationOpenURL()
					} else {
						if (self.walletConnectService().openSessions() > 0) {
							self.setButtonState([.walletconnected], dAppInfo: self.walletConnectService().getSession().dAppInfo)
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
				self.labelBalance.text = "\(self.walletService().nhashToHash(coin.amount))"
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
		1
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

				let confirmBroadcastTxViewController = ConfirmBroadcastTxViewController()
				confirmBroadcastTxViewController.walletConnectRequest = walletConnectQueue[indexPath.row]
				confirmBroadcastTxViewController.completion = { [self]
					self.removeFromQueue(request: request)
				}
				navigationController?.pushViewController(confirmBroadcastTxViewController, animated: true)

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

		5
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {

		5
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

		UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
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
	func serverDisconnect() {
		walletConnectService().disconnect()
		onMainThread {
			self.setButtonState([.not_walletconnected])
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

	@objc func handleWcShouldStart(notification: Notification) {
		let notificationModel: NotificationModel = notificationService().unwrap(notification)
		let walletConnectApproval: WalletConnectApproval = notificationModel.object as! WalletConnectApproval

		onMainThread {
			UIAlertController.showShouldStart(from: self, clientName: walletConnectApproval.session.dAppInfo.peerMeta.name, onStart: walletConnectApproval.approve, onClose: walletConnectApproval.reject)
		}
	}

	@objc func handleWcDidFailToConnect(notification: Notification) {
		Utilities.log("Did fail to connect \(notification)")
		onMainThread {
			UIAlertController.showFailedToConnect(from: self)
		}
	}

	@objc func handleWcDidUpdate(notification: Notification) {
		Utilities.log("WC Did update \(notification)")
	}

	@objc func handleWcDidConnect(notification: Notification) {
		let notificationModel: NotificationModel = notificationService().unwrap(notification)
		let session = notificationModel.object as! Session
		onMainThread {
			Utilities.log("Connected to \(session.dAppInfo.peerMeta.name)")
			self.setButtonState([.walletconnected], dAppInfo: session.dAppInfo)
		}
	}

	@objc func handleWcDidDisconnect(notification: Notification) {
		onMainThread {
			self.setButtonState([.not_walletconnected])
		}
	}

// MARK: - QR Scanning
	func didScan(_ code: String) {

		guard let url = WCURL(code) else {
			return
		}
		do {
			try walletConnectService().connect(url: url)
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
		let onSign = { [self]
			do {
				let signature = try sign()
				self.walletConnectService().send(.signature(signature, for: request))
			} catch {
				Utilities.log(error)
				self.walletConnectService().send(.error(error, for: request))
			}
			self.removeFromQueue(request: request)
		}
		let onCancel = { [self]
			self.walletConnectService().send(.reject(request))
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

