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

    private var requestType: Notification.Name?
    private var request: Request!
    private var messageType: String!
    private var message: Message!
    private var gasEstimate: GasEstimate?
    private var messageKVArray: [(String, String)] = []

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
            (messageType, message) = try request.decodeMessage()
            messageKVArray = parseMessageFields()
            setButtonState([.ready_to_broadcast])
        } catch {
            onMainThread {
                //TODO make me a slide up modal and pop view on confirm
                self.setButtonState([.error])
                Utilities.showAlert(title: "Error", message: "\(error)") {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try calculateGasFee()
        } catch {
            //TODO make me a slide up modal and pop view on confirm
            Utilities.showAlert(title: "Error", message: "\(error)") {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }

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

                walletService().broadcastTx(signingKey: signingKey, messages: [message], gasEstimate: gasEstimate!) { pair, error in

                    self.onMainThread {
                        self.activityIndicator.stopAnimating()
                    }

                    //TODO punch up response modal here
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
                                self.onMainThread { [self]
                                    //TODO generic error modal
                                    Utilities.showAlert(title: "Error", message: "\(error)") {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            }
                        } else {
                            Utilities.log(txResponse.rawLog)
                            do {
                                try self.walletConnectService().send(.rawTxErrorResponse(txPair, for: self.request))
                                self.onMainThread { [self]
                                    //TODO response error modal
                                    self.activityIndicator.stopAnimating()
                                    Utilities.showAlert(title: "Error", message: "\(txResponse.rawLog)") {
                                        self.dismiss(animated: true)
                                    }
                                }
                            } catch {
                                Utilities.log(error)
                                self.onMainThread { [self]
                                    //TODO generic error modal
                                    Utilities.showAlert(title: "Error", message: "\(error)") {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            }
                        }
                    }
                    else if let txError = error {
                        //TODO generic error modal
                        Utilities.showAlert(title: "Error", message: "\(error)") {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                }
            } catch {
                Utilities.log(error)
                //TODO generic error modal
                Utilities.showAlert(title: "Error", message: "\(error)") {
                    self.navigationController?.popToRootViewController(animated: true)
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
        Utilities.showConfirm(title: "Reject Request?",
                message: "Press Continue to reject \(request.description() ?? "") from \(walletConnectService().dAppName() ?? "").",
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

        try walletService().estimateTx(signingKey: signingKey, messages: [message]) { [self] gasEstimate, error in
            if (error != nil) {
                onMainThread {
                    [self]
                    //TODO make me a slide up modal
                    Utilities.showAlert(title: "Error", message: "\(error)") {
                        self.navigationController?.popToRootViewController(animated: true)
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
            return try message.jsonString()
        } catch {
            return "\(error)"
        }
    }

    func messageFieldCount() -> Int {
        messageKVArray.count
    }

    func parseMessageFields() -> [(String, String)] {
        do {
            let jsonString = try message.jsonString()
            let json = JSON.init(parseJSON: jsonString)
            Utilities.log(jsonString)
            return json.flatten()
        } catch {
            Utilities.log(error)
            return [("error", "\(error)")]
        }
    }
}

// MARK: - UITableViewDataSource
extension ConfirmBroadcastTxViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if (section == 0) {
            return 1
        }
        if (section == 1) {
            return 2
        }
        if (section == 2) {
            return messageFieldCount()
        }
        return 0
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

            let kv = messageKVArray[indexPath.row]
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
        return messageType.substringAfterLast(".").camelCaseToWords()
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
