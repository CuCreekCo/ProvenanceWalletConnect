//
// Created by JD on 2/8/22.
//

import Foundation
import WalletConnectSwift

class WalletConnectApproval: NSObject {
    let session: Session

    let approve: () -> Void
    let reject: () -> Void

    init(session: Session, approve: @escaping () -> (), reject: @escaping () -> ()) {
        self.session = session
        self.approve = approve
        self.reject = reject
        super.init()
    }
}

class WalletConnectService: NSObject {
    let sessionKey = "sessionKey"
    var server: Server!
    var session: Session!
    var notificationService: NotificationService!
    var walletService: WalletService!

    init(walletService: WalletService, notificationService: NotificationService) {
        super.init()
        self.notificationService = notificationService
        self.walletService = walletService
        configureServer()
    }

    private func configureServer() {
        server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(server: server, walletService: self.walletService,
                notificationService: self.notificationService))
        server.register(handler: SendTransactionHandler(server: server, walletService: self.walletService,
                notificationService: self.notificationService))

        reconnect()
    }

    func connect(url: URL) {
        let wc = "\(url.user.unsafelyUnwrapped):\(url.password.unsafelyUnwrapped)@\(url.host.unsafelyUnwrapped)/?\(url.query.unsafelyUnwrapped)"
        guard let wcUrl = WCURL(wc) else {
            return
        }
        self.connect(url: wcUrl)
    }

    func connect(url: WCURL) {
        do {
            try server.connect(to: url)
        } catch {
            Utilities.log(error)
        }
    }

    func disconnect() -> Bool {
        do {
            if (server == nil || session == nil) {
                return false
            }
            try server.disconnect(from: self.session)
            return true
        } catch {
            Utilities.log(error)
        }
        return false
    }

    func getSession() -> Session {
        session
    }

    func dAppName() -> String? {
        session?.dAppInfo.peerMeta.name
    }

    func dAppDescription() -> String? {
        session?.dAppInfo.peerMeta.description
    }

    func dAppUrl() -> String? {
        session?.dAppInfo.peerMeta.url.absoluteString
    }

    func send(_ response: Response) {
        server.send(response)
    }

    func openSessions() -> Int {
        if (server != nil) {
            return server.openSessions().count
        }
        return 0
    }

    func reconnect() {
        if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
           let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject) {
            try? server.reconnect(to: session)
        }
    }


}

// MARK: - WalletConnect Delegate

extension WalletConnectService: ServerDelegate {

    func server(_ server: Server, didFailToConnect url: WCURL) {
        notificationService.post(NotificationModel(name: Notification.Name.wcConnectFail, sender: self, object: url))
    }

    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        var publicKey: String = ""
        var signedJWT: String = ""

        do {
            let privateKey = try walletService.defaultPrivateKey()
            publicKey = privateKey.publicKey.compressedPublicKey
                    .toBase64URLWithoutPadding()

            Utilities.log("Public key \(publicKey)")

            signedJWT = try walletService.signed_jwt(privateKey: privateKey)
            Utilities.log("signed JWT \(signedJWT)")

        } catch {
            Utilities.log(error)
        }

        let walletMeta = Session.ClientMeta(name: "Unicorn Sparkle",
                description: "Provenance Sparkly Unicorn Wallet",
                icons: [],
                url: URL(string: "https://provenance.io")!)
        let walletInfo = Session.WalletInfo(approved: true,
                accounts: [
                    walletService.defaultAddress() ?? "UNKNOWN",
                    publicKey,
                    signedJWT
                ],
                chainId: 4,
                peerId: UUID().uuidString,
                peerMeta: walletMeta)

        let walletConnectApproval = WalletConnectApproval(
                session: session,
                approve: {
                    completion(walletInfo)
                },
                reject: {
                    Session.WalletInfo(approved: false, accounts: [], chainId: 4, peerId: "", peerMeta: walletMeta)
                })
        notificationService.post(NotificationModel(name: Notification.Name.wcShouldStart, sender: self, object: walletConnectApproval))
    }

    func server(_ server: Server, didConnect session: Session) {
        self.session = session
        let sessionData = try! JSONEncoder().encode(session)
        UserDefaults.standard.set(sessionData, forKey: sessionKey)
        notificationService.post(NotificationModel(name: Notification.Name.wcDidConnect, sender: self, object: session))
    }

    func server(_ server: Server, didDisconnect session: Session) {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        notificationService.post(NotificationModel(name: Notification.Name.wcDidDisconnect, sender: self, object: session))
    }

    func server(_ server: Server, didUpdate session: Session) {
        notificationService.post(NotificationModel(name: Notification.Name.wcDidUpdate, sender: self, object: session))
    }
}