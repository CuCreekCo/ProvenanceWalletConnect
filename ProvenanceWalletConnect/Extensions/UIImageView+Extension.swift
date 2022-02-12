import UIKit

extension UIImageView {

	func grayCircle() {
		let size = CGSize(width: 1, height: 1)
		let placeholder = UIGraphicsImageRenderer(size: size).image { rendererContext in
			UIColor.lightGray.setFill()
			rendererContext.fill(CGRect(origin: .zero, size: size))
		}
		image = placeholder
	}

	func greenCircle() {
		let size = CGSize(width: 1, height: 1)
		let placeholder = UIGraphicsImageRenderer(size: size).image { rendererContext in
			UIColor.green.setFill()
			rendererContext.fill(CGRect(origin: .zero, size: size))
		}
		image = placeholder
	}

}
