import Foundation

extension Notification.Name {
	static let provenanceSign = Notification.Name("provenanceSign")
	static let provenanceSendTransaction = Notification.Name("provenanceSendTransaction")
	static let wcConnectFail = Notification.Name("walletConnectFail")
	static let wcShouldStart = Notification.Name("walletConnectShouldStart")
	static let wcDidConnect = Notification.Name("walletConnectDidConnect")
	static let wcDidDisconnect = Notification.Name("walletConnectDidDisconnect")
	static let wcDidUpdate = Notification.Name("walletConnectDidUpdate")
}