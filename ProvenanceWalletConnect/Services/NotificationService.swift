//
// Created by Jason Davidson on 1/24/17.
// Copyright (c) 2017 Copper Creek Software. All rights reserved.
//

import Foundation
import UIKit

public struct NotificationModel {
	var name: Notification.Name
	var sender: Any?
	var object: Any?
}
public struct ObserverModel: Equatable {
	var name: Notification.Name
	var receiver: Any
	var selector: Selector
	public static func ==(lhs: ObserverModel, rhs: ObserverModel) -> Bool {
		let areEqual = (lhs.receiver as! UIViewController) == (rhs.receiver as! UIViewController)
				&& lhs.name == rhs.name
		return areEqual
	}
}

public class NotificationService: NSObject {

	var observerCache:[ObserverModel]!

	override public init() {
		observerCache = []
	}

	public func post(_ notificationModel: NotificationModel) -> Void {
		Utilities.log("post for \(notificationModel.name) sender: \(notificationModel.sender)")
		NotificationCenter.default
				.post(
				name:notificationModel.name,
				object: notificationModel.sender,
				userInfo: ["\(notificationModel.name.rawValue)Model": notificationModel])
	}
	public func observe(_ observerModel: ObserverModel) -> Void {
		if(!observerCache.contains(observerModel)) {
			observerCache.append(observerModel)
			Utilities.log("observe for \(observerModel.name) observer: \(observerModel.receiver)")
			NotificationCenter.default.addObserver(observerModel.receiver,
					selector: observerModel.selector,
					name: observerModel.name,
					object: nil)
		} else {
			Utilities.log("observe for \(observerModel.name) observer: \(observerModel.receiver) found in cache")
		}
	}

	public func unobserve(_ observerModel: ObserverModel) -> Void {
		if (observerCache != nil && observerCache.contains(observerModel)) {
			if let index = observerCache.index(of: observerModel) {
				observerCache.remove(at: index)
			}
		}
		Utilities.log("unobserve for \(observerModel.name) observer: \(observerModel.receiver)")
		NotificationCenter.default.removeObserver(observerModel.receiver,
				name: observerModel.name,
				object: nil)
	}

	public func unwrap(_ notification: Notification) -> NotificationModel {
		return notification.userInfo!.values.first as! NotificationModel
	}

}