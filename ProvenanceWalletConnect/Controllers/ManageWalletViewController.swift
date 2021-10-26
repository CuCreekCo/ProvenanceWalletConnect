//
// Created by Jason Davidson on 8/28/21.
//

import Foundation

import UIKit
import ProvWallet
import CoreData

class ManageWalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
	var container: NSPersistentContainer!
	var walletService: WalletService!

// MARK: - UI
	override func viewDidLoad() {
		super.viewDidLoad()
		guard container != nil else {
			fatalError("This view needs a persistent container.")
		}
		walletService = WalletService(persistentContainer: container, channel: channel())
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if (walletService.rootWalletSeedExists()) {
			let address = walletService.fetchRootWalletSerializedPublicKey()
			mnemonicText.text = address
			mnemonicText.isEditable = false
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
		self.statusIndicator.startAnimating()
		onMainThread { [self] in
			importButton.isEnabled = false
		}
		DispatchQueue.global(qos: .default).async {
			do {
				try self.walletService.generatePrivateKey(mnemonic: self.mnemonicText.text) { key, error in
					do {
						try Utilities.log(key?.serialize())
					} catch {
						ErrorHandler.show(title: "Key Serialization Error", message: error.localizedDescription,
						                  completionHandler: nil)
					}
					//TODO encrypt private key with enclave and store in Core Data
					if (key != nil) {
						self.walletService.saveRootWallet(privateKey: key!) { (uuid, saveError) in
							if (saveError != nil) {
								ErrorHandler.show(title: "Save Root Wallet", message: saveError!.localizedDescription,
								                  completionHandler: nil)
							}
						}
						DispatchQueue.main.async { [self] in
							addressTable.reloadData()
						}
					}
					if (error != nil) {
						ErrorHandler.show(title: "Generate Private Key", message: error!.localizedDescription,
						                  completionHandler: nil)
					}
				}
			} catch {
				ErrorHandler.show(title: "Import Mnemonic", message: error.localizedDescription, completionHandler: nil)
			}
			DispatchQueue.main.async { [self] in
				self.statusIndicator.stopAnimating()
				Utilities.showAlert(title: "Write it Down!", message: "This is the last time your mnemonic will be displayed.  Be sure to write it down:\n\(mnemonicText.text)") {
					mnemonicText.text = walletService.fetchRootWalletSerializedPublicKey()
				}
			}
		}
	}

    @IBAction func refreshAddresses(_ sender: Any) {
	    do {
		    try walletService.refreshAddresses()
		    onMainThread { [self] in
			    addressTable.reloadData()
		    }
	    } catch {
		    Utilities.log(error)
		    ErrorHandler.show(title: "Refresh Address", message: error.localizedDescription, completionHandler: nil)
	    }
			    
    }

// MARK: - UITable

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		do {
			return try walletService.fetchAddresses().count
		} catch {
			Utilities.log(error)
			return 0
		}
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "AddressTableCell", for: indexPath)
		do {
			let address = try walletService.fetchAddresses()[indexPath.row]
			cell.textLabel?.text = String(address.index)
			cell.detailTextLabel?.text = address.address
		} catch {
			Utilities.log(error)
		}
		return cell
	}

	func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
		do {
			let address = try walletService.fetchAddresses()[indexPath.row]
			UIPasteboard.general.string = address.address
			Utilities.showAlert(title: "Address Copied", message: "\(address.address) Copied to clipboard", completionHandler: nil)
		} catch {
			Utilities.log(error)
		}
	}
}
