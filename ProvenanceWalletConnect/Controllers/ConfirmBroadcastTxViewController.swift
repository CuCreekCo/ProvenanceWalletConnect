import UIKit
import WalletConnectSwift
import SwiftProtobuf
import SwiftyJSON
import ProvWallet

class ConfirmBroadcastTxViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cellMessageType: UITableViewCell!
    @IBOutlet weak var cellConnectedDapp: UITableViewCell!

    private var sections = ["WalletConnect", "Message", "Transaction"]
    private var transactions = ["", "", "", "", ""]

    var walletConnectRequest: (Notification.Name, Request)!
    var completion: () -> Void = {
    }

    private var requestType: Notification.Name?
    private var request: Request!
    private var messageType: String!
    private var message: Message!
    private var gas: UInt64?
    private var gasFee: UInt64?
    private var gasInfo: Cosmos_Base_Abci_V1beta1_GasInfo?
    private var messageKVArray: [(String, String)] = []

    //-------------------------------------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {

        super.viewDidLoad()
        title = "Confirm Transaction"
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        navigationController?.navigationBar.prefersLargeTitles = false

        (cellConnectedDapp.contentView.viewWithTag(1) as! UILabel).text = walletConnectService().dAppName()
        (cellConnectedDapp.contentView.viewWithTag(2) as! UILabel).text = walletConnectService().dAppUrl()

        requestType = walletConnectRequest.0
        request = walletConnectRequest.1

        do {
            (messageType, message) = try request.decodeMessage()

            messageKVArray = parseMessageFields()

            (cellMessageType.contentView.viewWithTag(22) as! UILabel).text = messageType.description
        } catch {
            onMainThread {
                //TODO make me a slide up modal and pop view on confirm
                Utilities.showAlert(title: "Error", message: "\(error)") {
                    //self.navigationController?.popToRootViewController(animated: true)
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
                //self.navigationController?.popToRootViewController(animated: true)
            }
        }

    }

    // MARK: - Data methods
    //-------------------------------------------------------------------------------------------------------------------------------------------

    // MARK: - User actions
    //-------------------------------------------------------------------------------------------------------------------------------------------
    @IBAction func actionSend(_ sender: UIButton) {

        print(#function)
        if (gasInfo != nil) {
            do {
                let rawTxPair = try walletService().broadcastTx(signingKey: walletService().defaultPrivateKey(), message: message, gasEstimate: gasInfo!)
                let txResponse = rawTxPair.txResponse

                //TODO punch up response modal here

                completion()
                if (txResponse.code == 0) {
                    Utilities.log(txResponse.rawLog)
                    try walletConnectService().send(.rawTxResponse(rawTxPair, for: request))
                    onMainThread {
                        self.activityIndicator.stopAnimating()
                        Utilities.showAlert(title: "Success", message: "\(txResponse.rawLog)") {
                            self.dismiss(animated: true)
                        }
                    }
                } else {
                    Utilities.log(txResponse.rawLog)
                    try walletConnectService().send(.rawTxErrorResponse(rawTxPair, for: request))
                    onMainThread {
                        [self]
                        self.activityIndicator.stopAnimating()
                        Utilities.showAlert(title: "Error", message: "\(txResponse.rawLog)") {
                            self.dismiss(animated: true)
                        }
                    }
                }
            } catch {
                Utilities.log(error)
                //TODO make me a slide up modal and pop view on confirm
                Utilities.showAlert(title: "Error", message: "\(error)") {
                    [self]
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
        walletConnectService().send(.reject(request))
        completion()
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Blockchain

    func calculateGasFee() throws {
        let signingKey = try walletService().defaultPrivateKey()

        try walletService().estimateTx(signingKey: signingKey, message: message) { [self] info, error in
            if (error != nil) {
                onMainThread {
                    [self]
                    //TODO make me a slide up modal
                    Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
                }
            } else {
                gasInfo = info!
                var gasFactor: Double = Double(gasInfo!.gasUsed) * 1.3
                gasFactor.round(.up)
                gas = UInt64(gasFactor)
                gasFee = gas! * Tx.gasPrice
                onMainThread {
                    [self]
                    (tableView.cellForRow(at: IndexPath(row: 0, section: 2))?.viewWithTag(1) as? UILabel)?.text =
                            "\(gas)"
                    (tableView.cellForRow(at: IndexPath(row: 1, section: 2))?.viewWithTag(1) as? UILabel)?.text =
                            "\(gasFee) nhash"
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
        //2 for the gas
        messageKVArray.count + 2
    }

    private func flatJson(_ json: JSON, label: String?, array: inout [(String, String)]) {
        for (k, v) in json {
            if (v.type == .dictionary) {
                flatJson(v, label: "\(label ?? "")-\(k)", array: &array)
            } else if (v.type == .array) {
                for a in v.arrayValue {
                    flatJson(a, label: "\(label ?? "")-\(k)", array: &array)
                }
            } else {
                array.append(("\(label) \(k)", v.stringValue))
            }
        }
    }

    func parseMessageFields() -> [(String, String)] {
        do {
            let jsonString = try message.jsonString()
            let json = JSON.init(parseJSON: jsonString)

            Utilities.log(jsonString)

            var kvArr: [(String, String)] = []
            flatJson(json, label: nil, array: &kvArr)

            return kvArr
        } catch {
            Utilities.log(error)
            return [("error", "\(error)")]
        }
    }
}

// MARK: - UITableViewDataSource
extension ConfirmBroadcastTxViewController: UITableViewDataSource {

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if (section == 0) {
            return 1
        }
        if (section == 1) {
            return 1
        }
        if (section == 2) {
            return messageFieldCount()
        }
        return 0
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if (indexPath.section == 0) && (indexPath.row == 0) {
            return cellConnectedDapp
        } else if (indexPath.section == 1) && (indexPath.row == 0) {
            return cellMessageType
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: "cellTransactionDetail")
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellTransactionDetail")
            }
            let label = cell!.textLabel!
            let value = cell!.detailTextLabel!

            if (indexPath.row == 0) { // let's call it the gas row
                label.text = "Gas Estimate"
                value.text = "Calculating..."
            } else if (indexPath.row == 1) { // let's call it the gas row
                label.text = "Gas Fees"
                value.text = "Calculating..."
            } else {
                let kv = messageKVArray[indexPath.row - 2]
                label.text = kv.0
                value.text = kv.1
            }
            return cell!
        }

    }
}

// MARK: - UITableViewDelegate
//-----------------------------------------------------------------------------------------------------------------------------------------------
extension ConfirmBroadcastTxViewController: UITableViewDelegate {

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        sections[section]
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {

        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = UIFont.systemFont(ofSize: 12)
        }
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {

        0.01
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if (indexPath.section == 0) {
            //dApp
        } else if (indexPath.section == 1) {
            if (indexPath.row == 0) {
                onMainThread {
                    Utilities.showAlert(title: "Data", message: self.messageJsonString(), completionHandler: nil)
                }
            }
        }
        print(#function)
    }
}
