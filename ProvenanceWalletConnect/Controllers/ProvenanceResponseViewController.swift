import UIKit

class ProvenanceResponseViewController: UIViewController {

	@IBOutlet var messageLabel: UILabel!
	@IBOutlet var messageSignerLabel: UILabel!
	@IBOutlet var imageViewUser1: UIImageView!
	@IBOutlet var blockNumberLabel: UILabel!
	@IBOutlet var txIdLabel: UILabel!
	@IBOutlet var buttonClose: UIButton!

    @IBOutlet weak var feeLabelView: LabelValueDetailView!
    //-------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		navigationController?.navigationBar.isHidden = true
		navigationController?.navigationItem.largeTitleDisplayMode = .never
		navigationController?.navigationBar.prefersLargeTitles = false

		buttonClose.layer.borderWidth = 1
		buttonClose.layer.borderColor = AppColor.Border.cgColor
        
        feeLabelView.label.text = "Heyo"
        
	}

	// MARK: - User actions
	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func transactionDetails(_ sender: UIButton) {

		print(#function)
	}


	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionTransactionDetails(_ sender: UIButton) {

		print(#function)
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------
	@IBAction func actionClose(_ sender: UIButton) {

		print(#function)
		dismiss(animated: true)
	}
}
