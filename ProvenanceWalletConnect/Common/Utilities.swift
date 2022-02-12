//
// Created by Jason Davidson on 8/28/21.
//

import Foundation
import UserNotifications
import UIKit
import SwiftyJSON

public class Utilities {
	public static func randomString(length: Int) -> String {

		let letters: NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		let len = UInt32(letters.length)

		var randomString = ""

		for _ in 0..<length {
			let rand = arc4random_uniform(len)
			var nextChar = letters.character(at: Int(rand))
			randomString += NSString(characters: &nextChar, length: 1) as String
		}

		return randomString
	}

	public static func plistString(_ key: String) -> String {
		let plistDict: NSMutableDictionary = NSMutableDictionary(
				contentsOfFile: Bundle.main.path(forResource: "Info", ofType: "plist")!)!
		return plistDict.object(forKey: key) as! String
	}

	public static func plistBool(_ key: String) -> Bool {
		let plistDict: NSMutableDictionary = NSMutableDictionary(
				contentsOfFile: Bundle.main.path(forResource: "Info", ofType: "plist")!)!
		return plistDict.object(forKey: key) as! Bool
	}

	public static func mainnet() -> Bool {
		return plistBool("ProvenanceMainnet")
	}
	
	public static func log(_ message: Any?) -> Void {
		if let logMessage = message as? String {
			NSLog(logMessage)
		} else if let logMessage = message as? NSError {
			NSLog("%@", logMessage)
		} else if let logMessage = message as? JSON {
			NSLog("%@", logMessage.stringValue)
		} else if let logMessage = message as? NSObject {
			NSLog("%@", logMessage)
		}

	}

	static func showAlert(title: String, message: String, completionHandler: (() -> Void)?) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default) { action in
			if let handler = completionHandler {
				handler()
			}
		}
		alertController.addAction(okAction)
		UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
	}

	static func showConfirm(title: String, message: String, continueHandler: @escaping () -> Void, cancelHandler: (() -> Void)?) {
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

		let continueAction = UIAlertAction(title: "Continue", style: .default) { action in
			continueHandler()
		}

		let cancelAction = UIAlertAction(title: "Cancel", style: .default) { action in
			if let handler = cancelHandler {
				handler()
			}
		}

		alertController.addAction(cancelAction)
		alertController.addAction(continueAction)
		UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
	}

}