//
// Created by Jason Davidson on 8/28/21.
//

import Foundation

import UIKit
import ProvWallet
import CoreData

class ManageWalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

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

	@IBOutlet weak var addressTable: UITableView!

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
				DispatchQueue.main.async { [self] in
					addressTable.reloadData()
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

	@IBAction func refreshAddresses(_ sender: Any) {
	}

// MARK: - UITable

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		1
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "AddressTableCell", for: indexPath)
		do {
			let address = try walletService().defaultAddress()
			cell.textLabel?.text = String(indexPath.row)
			cell.detailTextLabel?.text = address
		} catch {
			Utilities.log(error)
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
		do {
			let address = try walletService().defaultAddress()
			UIPasteboard.general.string = address
			Utilities.showAlert(title: "Address Copied", message: "\(address) Copied to clipboard",
			                    completionHandler: nil)
		} catch {
			Utilities.log(error)
		}
	}
}
