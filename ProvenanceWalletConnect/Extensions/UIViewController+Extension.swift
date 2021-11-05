//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import CoreData
import GRPC

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

	private func appDelegate() -> AppDelegate {
		UIApplication.shared.delegate as! AppDelegate
	}

	func channel() -> ClientConnection {
		appDelegate().channel
	}

	func container() -> NSPersistentCloudKitContainer {
		appDelegate().persistentContainer
	}

	func walletService() -> WalletService {
		appDelegate().walletService
	}
}
