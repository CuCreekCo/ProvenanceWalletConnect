//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import CoreData

extension UIViewController {
	func onMainThread(_ closure: @escaping () -> Void) {
		if Thread.isMainThread {
			closure()
		} else {
			DispatchQueue.main.async {
				closure()
			}
		}
	}

	func persistentContainer() -> NSPersistentContainer {
		// Is our parent the RootViewController?
		if let rootVC =  parent as? RootViewController {
			return rootVC.container
		} else {
			fatalError("This view needs a persistent container.")
		}
	}
}
