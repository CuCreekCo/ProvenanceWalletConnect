import UIKit
import ProvWallet
import WalletConnectSwift
import SwiftyJSON
import SwiftProtobuf

class ErrorResponseViewController: UIViewController {

	@IBOutlet var messageLabel: UILabel!
    @IBOutlet weak var errorTextField: UITextView!
    
	var okCompletion: (() -> Void)? = nil

	var message: String!
	var error: String!

	override func viewDidLoad() {
		super.viewDidLoad()

		messageLabel.text = message
		errorTextField.text = error

		navigationController?.navigationBar.isHidden = true
	}

    @IBAction func actionClose(_ sender: UIButton) {
		print(#function)
		if(okCompletion != nil) {
			okCompletion!()
		} else {
			navigationController?.navigationBar.isHidden = false
			navigationController?.popToRootViewController(animated: true)
		}
	}
}
