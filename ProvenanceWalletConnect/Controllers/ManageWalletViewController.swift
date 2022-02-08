//
// Created by Jason Davidson on 8/28/21.
//

import Foundation

import UIKit
import ProvWallet
import CoreData
import IQKeyboardManagerSwift

class ManageWalletViewController: UIViewController {

    @IBOutlet weak var layoutConstraintBottom: NSLayoutConstraint!
    // MARK: - UI
	override func viewDidLoad() {
		super.viewDidLoad()

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
		IQKeyboardManager.shared.enable = false
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if (walletService().rootWalletSeedExists()) {
			let address = walletService().fetchRootWalletSerializedPublicKey()
			mnemonicText.text = address
		} else {
			do {
				mnemonicText.text = try walletService().randomMnemonic()
			} catch {
				Utilities.log(error)
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool) {

		super.viewWillDisappear(animated)
		NotificationCenter.default.removeObserver(self)
		IQKeyboardManager.shared.enable = true
	}

	@objc func doneButtonTapped() {
		view.endEditing(true)
	}

	@objc func keyboardWillShow(_ notification: Notification) {

		if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
			let keyboardRectangle = keyboardFrame.cgRectValue
			let keyboardHeight = keyboardRectangle.height
			UIView.animate(withDuration: 0.5) {
				self.layoutConstraintBottom.constant = keyboardHeight
			}
			UIView.animate(withDuration: 0.5, animations: {
				self.layoutConstraintBottom.constant = keyboardHeight
			}) { (isComplete) in
				self.layoutConstraintBottom.constant -= self.view.safeAreaInsets.bottom
			}
		}
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	@objc func keyboardWillHide(_ notification: Notification) {

		UIView.animate(withDuration: 0.5) {
			self.layoutConstraintBottom.constant = 0
		}
	}

// MARK: - IBOutlet

    @IBOutlet weak var setRandomPhraseButton: UIButton!
    
    @IBOutlet weak var importPhraseButton: UIButton!
    @IBOutlet weak var statusIndicator: UIActivityIndicatorView!

	@IBOutlet weak var mnemonicText: UITextView!

// MARK: - IBAction
	
    @IBAction func generateMnemonic(_ sender: Any) {
		mnemonicText.text = Mnemonic.create(strength: .hight)
		onMainThread { [self] in
            importPhraseButton.isEnabled = true
		}
	}
    @IBAction func importPhrase(_ sender: Any) {
		if (mnemonicText.text.length == 0) {
			onMainThread {
				ErrorHandler.show(title: "Mnemonic Required", message: "Please enter a mnemonic value.", completionHandler: nil)
			}
		} else {
			onMainThread { [self] in
				statusIndicator.startAnimating()
				importPhraseButton.isEnabled = false
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
