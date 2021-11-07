//
// Created by Jason Davidson on 8/28/21.
//

import Foundation

import UIKit
import ProvWallet
import CoreData

class ManageWalletViewController: UIViewController {

// MARK: - UI
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if (walletService().rootWalletSeedExists()) {
			let address = walletService().fetchRootWalletSerializedPublicKey()
			mnemonicText.text = address
			mnemonicText.isEditable = false
		} else {
			do {
				mnemonicText.text = try walletService().randomMnemonic()
			} catch {
				Utilities.log(error)
			}
		}
	}

// MARK: - IBOutlet

	@IBOutlet weak var importButton: UIBarButtonItem!

	@IBOutlet weak var statusIndicator: UIActivityIndicatorView!

	@IBOutlet weak var mnemonicText: UITextView!

// MARK: - IBAction
	@IBAction func generateMnemonic(_ sender: UIBarButtonItem) {
		mnemonicText.text = Mnemonic.create(strength: .hight)
		onMainThread { [self] in
			importButton.isEnabled = true
		}
	}

	@IBAction func clearMnemonic(_ sender: UIBarButtonItem) {
		mnemonicText.text = ""
	}

	@IBAction func importMnemonic(_ sender: UIBarButtonItem) {
		if (mnemonicText.text.length == 0) {
			onMainThread {
				ErrorHandler.show(title: "Mnemonic Required", message: "Please enter a mnemonic value.", completionHandler: nil)
			}
		} else {
			onMainThread { [self] in
				statusIndicator.startAnimating()
				importButton.isEnabled = false
			}
			DispatchQueue.global(qos: .default).async {
				do {
					let key = try self.walletService().generatePrivateKey(mnemonic: self.mnemonicText.text)
					do {
						try Utilities.log(key.serialize())
					} catch {
						ErrorHandler.show(title: "Key Serialization Error", message: error.localizedDescription,
						                  completionHandler: nil)
					}
					//TODO encrypt private key with enclave and store in Core Data
					self.walletService().saveRootWallet(privateKey: key) { (uuid, saveError) in
						if (saveError != nil) {
							ErrorHandler.show(title: "Save Root Wallet", message: saveError!.localizedDescription,
							                  completionHandler: nil)
						}
					}
				} catch {
					ErrorHandler.show(title: "Import Mnemonic", message: error.localizedDescription, completionHandler: nil)
				}
				DispatchQueue.main.async { [self] in
					self.statusIndicator.stopAnimating()
					Utilities.showAlert(title: "Write it Down!", message: "This is the last time your mnemonic will be displayed.  Be sure to write it down:\n\(mnemonicText.text)") {
						mnemonicText.text = walletService().defaultAddress()
					}
				}
			}
		}
	}
}
