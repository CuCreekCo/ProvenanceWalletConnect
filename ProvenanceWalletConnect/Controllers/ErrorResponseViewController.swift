import UIKit
import ProvWallet
import WalletConnectSwift
import SwiftyJSON
import SwiftProtobuf

class ErrorResponseViewController: UIViewController {

	@IBOutlet var messageLabel: UILabel!
	@IBOutlet var buttonClose: UIButton!
    @IBOutlet weak var tableView: UITableView!

	var rawResponsePair: RawTxResponsePair!
	var walletConnectRequest: (Notification.Name, Request)!

	private var requestType: Notification.Name?
	private var request: Request!
	private var messageType: String!
	private var message: Message!
	private var messageKVArray: [(String, String)] = []

	//-------------------------------------------------------------------------------------------------------------------------------------------
	override func viewDidLoad() {

		super.viewDidLoad()
		navigationController?.navigationBar.isHidden = true

		tableView.register(UINib(nibName: "ConnectedDappCell", bundle: nil), forCellReuseIdentifier: "cellConnectedDapp")

		requestType = walletConnectRequest.0
		request = walletConnectRequest.1

		do {
			(messageType, message) = try request.decodeMessage()
			messageLabel.text = messageType.substringAfterLast(".").camelCaseToWords()

			messageKVArray = parseTxResponseFields()
		} catch {
			onMainThread {
				//TODO make me a slide up modal and pop view on confirm
				Utilities.showAlert(title: "Error", message: "\(error)") {
					self.navigationController?.popToRootViewController(animated: true)
				}
			}
		}

	}

	private func messageFieldCount() -> Int {
		messageKVArray.count
	}

	private func parseTxResponseFields() -> [(String, String)] {
		do {
			let jsonString = try rawResponsePair.txResponse.jsonString()
			let json = JSON.init(parseJSON: jsonString)
			Utilities.log(jsonString)
			return json.flatten()
		} catch {
			Utilities.log(error)
			return [("error", "\(error)")]
		}
	}

	// MARK: - User actions
	@IBAction func actionClose(_ sender: UIButton) {
		print(#function)
		Utilities.log(navigationController)
		navigationController?.navigationBar.isHidden = false
		navigationController?.popToRootViewController(animated: true)
	}
}

// MARK: - Table Data Source
extension ErrorResponseViewController: UITableViewDataSource {
	func numberOfSections(in tableView: UITableView) -> Int {
		//Sections: dApp, Gas (wanted, used, total fees), Details (block, id, status, time, memo), Transaction Response (dynamic)
		4
	}
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

		if (section == 0) {
			return 1
		}
		if (section == 1) {
			return 3 //Gas
		}
		if (section == 2) {
			return 5 //Details
		}
		if (section == 3) {
			return messageFieldCount()
		}
		return 0
	}
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

		if (indexPath.section == 0) {
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

			if (indexPath.row == 0) {
				label.text = "Gas Wanted"
				value.text = "\(rawResponsePair.txResponse.gasWanted)"
			} else if (indexPath.row == 1) {
				label.text = "Gas Used"
				value.text = "\(rawResponsePair.txResponse.gasUsed)"
			} else if (indexPath.row == 2) {
				label.text = "Gas Fees"
				do {
					let txRaw = rawResponsePair.txRaw
					let authInfoBytes = try Cosmos_Tx_V1beta1_AuthInfo(serializedData: txRaw.authInfoBytes)
					let gasFees = authInfoBytes.fee.amount.first?.amount ?? "N/A"
					value.text = "\(walletService().nhashToHash(gasFees)) Hash"
				} catch {
					Utilities.log(error)
					value.text = "\(error)"
				}
			}
			return cell!
		} else if (indexPath.section == 2) {
			// Details (block, id, status, time, memo)
			var cell = tableView.dequeueReusableCell(withIdentifier: "cellTransactionDetail")
			if cell == nil {
				cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellTransactionDetail")
			}
			let label = cell!.textLabel!
			let value = cell!.detailTextLabel!

			if (indexPath.row == 0) {
				label.text = "Block"
				value.text = "\(rawResponsePair.txResponse.height)"
			} else if (indexPath.row == 1) {
				label.text = "Tx ID"
				value.text = rawResponsePair.txResponse.txhash
			} else if(indexPath.row == 3) {
				label.text = "Status"
				value.text = rawResponsePair.txResponse.code == 0 ? "Success" : "Failed"
			} else if(indexPath.row == 4) {
				label.text = "Time"
				value.text = rawResponsePair.txResponse.timestamp
			} else if(indexPath.row == 4) {
				label.text = "Memo"
				value.text = rawResponsePair.txResponse.info
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

// MARK: - Table Delegate
extension ErrorResponseViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		//Sections: dApp, Gas (wanted, used, total fees), Details (block, id, status, time, memo), Transaction Response (dynamic)
		if (section == 0) {
			return "WalletConnect"
		}
		if (section == 1) {
			return "Gas"
		}
		if (section == 2) {
			return "Transaction Details"
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
				var txRaw: String!
				do {
					txRaw = try rawResponsePair.txRaw.jsonString()
				} catch {
					txRaw = "\(error)"
				}
				onMainThread {
					Utilities.showAlert(title: "Data", message: txRaw, completionHandler: nil)
				}
			}
		}
		print(#function)
	}

}
