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
import WalletConnectSwift

class WalletViewController: UIViewController, ScannerViewControllerDelegate, ServerDelegate {
	var server: Server!
	var session: Session!
	//TODO what is this really?
	let sessionKey = "sessionKey"

// MARK: - UI

	override func viewDidLoad() {
		super.viewDidLoad()
		configureServer()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		do {
			if (try walletService().fetchRootWalletEntity()) != nil {
				onMainThread {
					self.connectWalletView.isHidden = true
					self.connectedWalletView.isHidden = false
					self.connectedWalletAddress.text = self.walletService().defaultAddress()

					if let url = self.applicationOpenURL() {
						if (self.server.openSessions().count > 0) {
							self.disconnectWallet(self)
						} else {
							self.configureServer()
						}

						let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
						Utilities.log(wc)
						self.didScan(wc)
					} else {
						if (self.server.openSessions().count > 0) {
							self.disconnectWalletConnectView.isHidden = false
						} else {
							self.disconnectWalletConnectView.isHidden = true
							self.scanWalletConnectView.isHidden = false
						}
					}
				}

			} else {
				onMainThread {
					self.connectWalletView.isHidden = false
					self.connectedWalletView.isHidden = true
				}
			}

		} catch {
			Utilities.log(error)
		}

	}

// MARK: - IBOutlets

	@IBOutlet weak var connectedWalletView: UIView!
	@IBOutlet weak var connectedWalletAddress: UITextField!

	@IBOutlet weak var disconnectWalletConnectView: UIView!

	@IBOutlet weak var scanWalletConnectView: UIView!
	@IBOutlet weak var connectWalletView: UIView!
	@IBOutlet weak var walletConnectPeerLabel: UILabel!

	// MARK: - IBActions

	@IBAction func disconnectWallet(_ sender: Any) {
		let disconnected = walletService().disconnectWallet()
		if (disconnected) {
			connectWalletView.isHidden = false
			connectedWalletView.isHidden = true
			if (session != nil) {
				serverDisconnect(session: session);
				scanWalletConnectView.isHidden = false
				disconnectWalletConnectView.isHidden = true
			}
		}
	}

	@IBAction func disconnectWalletConnect(_ sender: Any) {
		serverDisconnect(session: session);
		scanWalletConnectView.isHidden = false
		disconnectWalletConnectView.isHidden = true
	}

	@IBAction func didTouchUpAddress(_ sender: Any) {
		let address = connectedWalletAddress.text
		UIPasteboard.general.string = address
		Utilities.showAlert(title: "Address Copied", message: "\(address) Copied to clipboard",
		                    completionHandler: nil)

	}

// MARK: - WalletConnect

	private func configureServer() {
		server = Server(delegate: self)
		server.register(handler: PersonalSignHandler(for: self, server: server, walletService: walletService()))
		server.register(handler: SendTransactionHandler(for: self, server: server, walletService: walletService()))
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
			self.disconnectWalletConnectView.isHidden = false
			self.scanWalletConnectView.isHidden = true
			self.walletConnectPeerLabel.text = session.dAppInfo.peerMeta.name
		}
	}

	func server(_ server: Server, didDisconnect session: Session) {
		UserDefaults.standard.removeObject(forKey: sessionKey)
		onMainThread {
			self.disconnectWalletConnectView.isHidden = true
			self.scanWalletConnectView.isHidden = false
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
		self.disconnectWalletConnectView.isHidden = false
		self.scanWalletConnectView.isHidden = true
		do {
			try server.connect(to: url)
		} catch {
			Utilities.log(error)
			return
		}
	}
}
