import UIKit
import WalletConnectSwift
import SwiftProtobuf
import SwiftyJSON
import ProvWallet

class ConfirmBroadcastTxViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    
    private var sections = ["WalletConnect", "Gas"]

    var walletConnectRequest: (Notification.Name, Request)!
    var completion: () -> Void = {
    }

    private var requestMessage: String!
    private var requestType: Notification.Name?
    private var request: Request!
    private var txMessageRequests: [TxMessageRequest] = []
    private var gasEstimate: GasEstimate?
    private var messageKVArray: [[(String, String)]] = []

    private enum TxState {
        case ready_to_broadcast
        case broadcasting
        case success
        case error
    }
// MARK: - View Lifecycle

    override func viewDidLoad() {

        super.viewDidLoad()
        title = "Confirm Transaction"

        tableView.register(UINib(nibName: "ConnectedDappCell", bundle: nil), forCellReuseIdentifier: "cellConnectedDapp")

        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        requestType = walletConnectRequest.0
        request = walletConnectRequest.1

        do {
            requestMessage = try request.description()
        } catch {
            requestMessage = requestType?.rawValue
        }

        do {
            txMessageRequests = try request.decodeMessages()
            messageKVArray = parseMessageFields()
            setButtonState([.ready_to_broadcast])
        } catch {
            Utilities.log(error)
            onMainThread {
                self.pushErrorView(message: self.requestMessage, error: "\(error)") {
                    self.sendPopAndCompleteError(error: "\(error)")
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try calculateGasFee()
        } catch {
            Utilities.log(error)
            onMainThread {
                self.pushErrorView(message: self.requestMessage, error: "\(error)") {
                    self.sendPopAndCompleteError(error: "\(error)")
                }
            }
        }
    }

    private func sendPopAndCompleteError(error: String) {
        walletConnectService().send(.error(error, for: request))
        completion()
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }
    private func sendAndPopError(error: String) {
        walletConnectService().send(.error(error, for: request))
        navigationController?.navigationBar.isHidden = false
        navigationController?.popToRootViewController(animated: true)
    }

    private func setButtonState(_ state: [TxState]) {
        onMainThread {
            if(state.contains(.ready_to_broadcast)) {
                self.sendButton.isEnabled = true
                self.rejectButton.isEnabled = true
            }
            if(state.contains(.broadcasting)) {
                self.sendButton.isEnabled = false
                self.rejectButton.isEnabled = false
            }
            if(state.contains(.success)) {
                self.sendButton.isEnabled = false
                self.rejectButton.isEnabled = false
            }
            if(state.contains(.error)) {
                self.sendButton.isEnabled = false
                self.rejectButton.isEnabled = false
            }
        }
    }

    private func requestMessages() -> [Message] {
        txMessageRequests.map { request -> Message in
            request.message
        }
    }

// MARK: - User actions

    @IBAction func actionSend(_ sender: UIButton) {

        print(#function)

        if (gasEstimate != nil) {
            do {
                setButtonState([.broadcasting])
                onMainThread {
                    self.activityIndicator.startAnimating()
                }
                let signingKey = try walletService().defaultPrivateKey()

                walletService().broadcastTx(signingKey: signingKey, messages: requestMessages(), gasEstimate: gasEstimate!) { pair, error in

                    self.onMainThread {
                        self.activityIndicator.stopAnimating()
                    }

                    self.completion()

                    if let txPair = pair  {
                        let txResponse = txPair.txResponse

                        if (txResponse.code == 0) {
                            Utilities.log(txResponse.rawLog)
                            do {
                                try self.walletConnectService().send(.rawTxResponse(txPair, for: self.request))
                                let responseController = ProvenanceResponseViewController()
                                responseController.rawResponsePair = txPair
                                responseController.walletConnectRequest = self.walletConnectRequest
                                self.onMainThread { [self]
                                    self.navigationController?.pushViewController(responseController, animated: true)
                                }
                            } catch {
                                Utilities.log(error)
                                self.onMainThread {
                                    self.pushErrorView(message: self.requestMessage, error: "\(error)") {
                                        self.sendPopAndCompleteError(error: "\(error)")
                                    }
                                }
                            }
                        } else {
                            Utilities.log(txResponse.rawLog)
                            do {
                                try self.walletConnectService().send(.rawTxErrorResponse(txPair, for: self.request))
                                self.onMainThread { [self]
                                    self.activityIndicator.stopAnimating()
                                    self.pushErrorView(message: self.requestMessage, error: "\(txResponse.rawLog)") {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            } catch {
                                Utilities.log(error)
                                self.onMainThread { [self]
                                    self.pushErrorView(message: self.requestMessage, error: "\(error)") {
                                        self.sendAndPopError(error: "\(error)")
                                    }
                                }
                            }
                        }
                    }
                    else if let txError = error {
                        Utilities.log(txError)

                        self.onMainThread {
                            self.pushErrorView(message: self.requestMessage, error: "\(txError)") {
                                self.sendAndPopError(error: "\(txError)")
                            }
                        }
                    }
                }
            } catch {
                Utilities.log(error)
                self.onMainThread { [self]
                    self.pushErrorView(message: self.requestMessage, error: "\(error)") {
                        self.sendPopAndCompleteError(error: "\(error)")
                    }
                }
            }
        } else {
            onMainThread {
                Utilities.showAlert(title: "Gas Calculating...", message: "Gas prices are still calculating, can't submit.", completionHandler: nil)
            }
        }
    }

    @IBAction func actionReject(_ sender: Any) {
        print(#function)
        var description = ""
        do {
            description = try request.description()
        } catch {
            Utilities.log(error)
        }
        Utilities.showConfirm(title: "Reject Request?",
                message: "Press Continue to reject \(description) from \(walletConnectService().dAppName() ?? "").",
                continueHandler: {
                    [self]
                    self.walletConnectService().send(.reject(self.request))
                    self.completion()
                    self.navigationController?.popToRootViewController(animated: true)
                },
                cancelHandler: nil)
    }

// MARK: - Blockchain

    func calculateGasFee() throws {
        let signingKey = try walletService().defaultPrivateKey()

        try walletService().estimateTx(signingKey: signingKey, messages: requestMessages()) { [self] gasEstimate, error in
            if (error != nil) {
                onMainThread {
                    [self]
                    pushErrorView(message: self.requestMessage, error: "\(error)") {
                        sendPopAndCompleteError(error: "\(error)")
                    }
                }
            } else {
                self.gasEstimate = gasEstimate
                onMainThread {
                    [self]
                    tableView.reloadData()
                    activityIndicator.stopAnimating()
                }
            }
        }
    }


    func messageJsonString() -> String {
        do {
            let s = try requestMessages().map { message -> String in
                try message.jsonString()
            }.joined(separator: ",")
            return "[ \(s) ]"
        } catch {
            return "\(error)"
        }
    }

    func messageCount() -> Int {
        txMessageRequests.count
    }

    func messageFieldCount(section: Int) -> Int {
        messageKVArray.count
    }

    func parseMessageFields() -> [[(String, String)]] {
        var r:[[(String, String)]] = []
        for index in 0..<messageCount() {
            do {
                let jsonString = try txMessageRequests[index].message.jsonString()
                let json = JSON.init(parseJSON: jsonString)
                Utilities.log(jsonString)
                r.append(json.flatten())
            } catch {
                Utilities.log(error)
                r.append([("error", "\(error)")])
            }
        }
        return r
    }
}

// MARK: - UITableViewDataSource
extension ConfirmBroadcastTxViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        2 + messageCount()
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if (section == 0) {
            return 1
        }
        if (section == 1) {
            return 2
        }
        return messageKVArray[section - 2].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if (indexPath.section == 0) && (indexPath.row == 0) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellConnectedDapp")!
            (cell.contentView.viewWithTag(1) as! UILabel).text = walletConnectService().dAppName()
            (cell.contentView.viewWithTag(2) as! UILabel).text = walletConnectService().dAppUrl()
            return cell
        } else if (indexPath.section == 1) {
            var cell = tableView.dequeueReusableCell(withIdentifier: "cellTransactionDetail")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellTransactionDetail")
            }
            let label = cell!.textLabel!
            let value = cell!.detailTextLabel!

            if (indexPath.row == 0) { // let's call it the gas row
                label.text = "Gas Estimate"
                if (gasEstimate != nil) {
                    value.text = "\(gasEstimate!.gas ?? 0)"
                } else {
                    value.text = "Calculating..."
                }
            } else if (indexPath.row == 1) { // let's call it the gas row
                label.text = "Gas Fees"
                if (gasEstimate != nil) {
                    value.text = "\(walletService().nhashToHash(gasEstimate!.gasFee ?? 0)) Hash"
                } else {
                    value.text = "Calculating..."
                }
            }
            return cell!
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "cellTransactionDetail")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellTransactionDetail")
            }
            let label = cell!.textLabel!
            let value = cell!.detailTextLabel!

            let kv = messageKVArray[indexPath.section - 2][indexPath.row]
            label.text = kv.0
            value.text = kv.1
            return cell!
        }

    }
}

// MARK: - UITableViewDelegate
extension ConfirmBroadcastTxViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if (section == 0) {
            return "WalletConnect"
        }
        if (section == 1) {
            return "Gas"
        }
        return "\(txMessageRequests[section - 2].typeTitle()) [\(section - 2 + 1)]"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = UIFont.systemFont(ofSize: 12)
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0.01
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if (indexPath.section == 0) {
            if (indexPath.row == 0) {
                //TODO make this a nice modal
                onMainThread {
                    Utilities.showAlert(title: "Data", message: self.messageJsonString(), completionHandler: nil)
                }
            }
        }
        print(#function)
    }
}
