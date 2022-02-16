import UIKit
import WalletConnectSwift

//-----------------------------------------------------------------------------------------------------------------------------------------------
class WalletViewCell: UICollectionViewCell {

	@IBOutlet var imageViewProfile: UIImageView!
	@IBOutlet var labelName: UILabel!

	//-------------------------------------------------------------------------------------------------------------------------------------------
	func bindData(index: IndexPath, data: (Notification.Name, Request)) {

		let name = data.0.rawValue
		do {
			labelName.text = try data.1.description()
		} catch {
			labelName.text = name
		}
	}
}
