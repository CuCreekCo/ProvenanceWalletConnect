//
// Created by Jason Davidson on 8/29/21.
//

import Foundation
import UIKit
import ProvWallet
import SwiftProtobuf
import WalletConnectSwift
import SwiftyJSON

class BaseHandler: RequestHandler {
	weak var controller: UIViewController!
	weak var server: Server!
	weak var walletService: WalletService!

	init(for controller: UIViewController, server: Server, walletService: WalletService) {
		self.controller = controller
		self.server = server
		self.walletService = walletService
	}

	func canHandle(request: Request) -> Bool {
		false
	}

	func handle(request: Request) {
		// to override
		Utilities.log(request)
	}

	func askToSign(request: Request, description: String, message: String, sign: @escaping () throws -> String) {
		let onSign = {
			do {
				let signature = try sign()
				self.server.send(.signature(signature, for: request))
			} catch {
				Utilities.log(error)
				self.server.send(.error(error, for: request))
			}
		}
		let onCancel = {
			self.server.send(.reject(request))
		}
		DispatchQueue.main.async {
			UIAlertController.showShouldSign(from: self.controller,
			                                 title: description,
			                                 message: message,
			                                 onSign: onSign,
			                                 onCancel: onCancel)
		}
	}

	func askToSend(request: Request, message: Message, description: String,
	               displayMessage: String, gasFee: UInt64, send: @escaping () throws -> RawTxResponsePair) {
		let onSend = {
			do {

				let rawTxPair = try send()
				let txResponse = rawTxPair.txResponse
				if (txResponse.code == 0) {
					Utilities.log(txResponse.rawLog)
					try self.server.send(.rawTxResponse(rawTxPair, for: request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Success", message: "\(txResponse.rawLog)", completionHandler: nil)
					}

				} else {
					Utilities.log(txResponse.rawLog)
					try self.server.send(.rawTxErrorResponse(rawTxPair, for: request))
					DispatchQueue.main.async {
						Utilities.showAlert(title: "Error", message: "\(txResponse.rawLog)", completionHandler: nil)
					}

				}
			} catch {
				Utilities.log(error)
				self.server.send(.error(error, for: request))
				DispatchQueue.main.async {
					Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
				}
			}
		}
		let onCancel = {
			self.server.send(.reject(request))
		}
		DispatchQueue.main.async {
			UIAlertController.showShouldSend(from: self.controller,
			                                 title: description,
			                                 message: "\(displayMessage) will cost \(gasFee)\(Tx.baseDenom)",
			                                 onSend: onSend,
			                                 onCancel: onCancel)
		}
	}

}

class PersonalSignHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "provenance_sign"
	}

	override func handle(request: Request) {
		do {
			let metadata = try request.parameter(of: String.self, at: 0)
			let metaJSON = JSON.init(parseJSON: metadata);
			let messageBytes = try request.parameter(of: String.self, at: 1)

			guard metaJSON["address"].stringValue == walletService.defaultAddress() else {
				self.server.send(.error("Wallet address \(walletService.defaultAddress() ?? "null") does not match request address \(metaJSON["address"].stringValue)", for: request))
				return
			}

			let description = metaJSON["description"].stringValue

			let decodedMessage = String(data: Data(hex: messageBytes), encoding: .utf8) ?? messageBytes

			askToSign(request: request, description: description, message: decodedMessage) {
				let messageData = Data(hex: messageBytes).sha256()
				return try self.walletService.sign(messageData: messageData).toHexString()
			}
		} catch {
			self.server.send(.error(error, for: request))
			DispatchQueue.main.async {
				Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
			}

			return
		}
	}
}

class SendTransactionHandler: BaseHandler {
	override func canHandle(request: Request) -> Bool {
		request.method == "provenance_sendTransaction"
	}

	override func handle(request: Request) {
		do {
			Utilities.log(request)
			let metadata = try request.parameter(of: String.self, at: 0)
			let metaJSON = JSON.init(parseJSON: metadata);
			let description = metaJSON["description"].stringValue

			guard metaJSON["address"].stringValue == walletService.defaultAddress() else {
				self.server.send(.error("Wallet address \(walletService.defaultAddress() ?? "null") does not match request address \(metaJSON["address"].stringValue)", for: request))
				return
			}

			let (type, message) = try decodeMessage(request: request)

			let signingKey = try walletService.defaultPrivateKey()
			//TODO assert signing key == address in request

			let gasEstimate = try walletService.estimateTx(signingKey: signingKey, message: message)
			let displayMessage = try message.jsonString()
			var gas = (Double(gasEstimate.gasUsed) * 1.3)
			gas.round(.up)

			let gasFee = UInt64(gas) * Tx.gasPrice

			askToSend(request: request, message: message, description: description, displayMessage: displayMessage,
			          gasFee: gasFee) {
				try self.walletService.broadcastTx(signingKey: signingKey, message: message, gasEstimate: gasEstimate)
			}
		} catch {
			Utilities.log(error)
			self.server.send(.error(error, for: request))
			DispatchQueue.main.async {
				Utilities.showAlert(title: "Error", message: "\(error)", completionHandler: nil)
			}

		}
	}

	private func decodeMessage(request: Request) throws -> (String, Message) {
		let msgHex = try request.parameter(of: String.self, at: 1)
		let msgData = Data(hex: msgHex)
		guard let msgB64 = Data(base64Encoded: msgData) else {
			throw ProvenanceWalletError(kind: .invalidProvenanceMessage,
			                            message: "request contains invalid message information", messages: nil,
			                            underlyingError: nil)
		}
		let msgAny = try Google_Protobuf_Any(serializedData: msgB64)

		Utilities.log(msgAny.typeURL)

		/*
		 Cosmos: https://buf.build/cosmos/cosmos-sdk/docs/main
		 CosmWasm Messages: https://github.com/CosmWasm/wasmd/blob/master/docs/proto/proto-docs.md
         Provenance Messages: https://github.com/provenance-io/provenance/blob/main/docs/proto-docs.md
		 */
		switch msgAny.typeURL {

				/* Cosmos Messages */
			case "/cosmos.authz.v1beta1.MsgGrant":
				return (msgAny.typeURL, try Cosmos_Authz_V1beta1_MsgGrant(unpackingAny: msgAny))
			case "/cosmos.authz.v1beta1.MsgExec":
				return (msgAny.typeURL, try Cosmos_Authz_V1beta1_MsgExec(unpackingAny: msgAny))
			case "/cosmos.authz.v1beta1.MsgRevoke":
				return (msgAny.typeURL, try Cosmos_Authz_V1beta1_MsgRevoke(unpackingAny: msgAny))

			case "/cosmos.bank.v1beta1.MsgMultiSend":
				return (msgAny.typeURL, try Cosmos_Bank_V1beta1_MsgMultiSend(unpackingAny: msgAny))

			case "/cosmos.crisis.v1beta1.MsgVerifyInvariant":
				return (msgAny.typeURL, try Cosmos_Crisis_V1beta1_MsgVerifyInvariant(unpackingAny: msgAny))

			case "/cosmos.distribution.v1beta1.MsgSetWithdrawAddress":
				return (msgAny.typeURL, try Cosmos_Distribution_V1beta1_MsgSetWithdrawAddress(unpackingAny: msgAny))
			case "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward":
				return (msgAny.typeURL,
						try Cosmos_Distribution_V1beta1_MsgWithdrawDelegatorReward(unpackingAny: msgAny))
			case "/cosmos.distribution.v1beta1.MsgWithdrawValidatorCommission":
				return (msgAny.typeURL,
						try Cosmos_Distribution_V1beta1_MsgWithdrawValidatorCommission(unpackingAny: msgAny))
			case "/cosmos.distribution.v1beta1.MsgFundCommunityPool":
				return (msgAny.typeURL, try Cosmos_Distribution_V1beta1_MsgFundCommunityPool(unpackingAny: msgAny))

			case "/cosmos.evidence.v1beta1.MsgSubmitEvidence":
				return (msgAny.typeURL, try Cosmos_Evidence_V1beta1_MsgSubmitEvidence(unpackingAny: msgAny))

			case "/cosmos.feegrant.v1beta1.MsgGrantAllowance":
				return (msgAny.typeURL, try Cosmos_Feegrant_V1beta1_MsgGrantAllowance(unpackingAny: msgAny))
			case "/cosmos.feegrant.v1beta1.MsgRevokeAllowance":
				return (msgAny.typeURL, try Cosmos_Feegrant_V1beta1_MsgRevokeAllowance(unpackingAny: msgAny))

			case "/cosmos.gov.v1beta1.MsgSubmitProposal":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgSubmitProposal(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta1.MsgVote":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVote(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta1.MsgVoteWeighted":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVoteWeighted(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta1.MsgDeposit":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgDeposit(unpackingAny: msgAny))

			case "/cosmos.gov.v1beta2.MsgSubmitProposal":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgSubmitProposal(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta2.MsgVote":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVote(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta2.MsgVoteWeighted":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgVoteWeighted(unpackingAny: msgAny))
			case "/cosmos.gov.v1beta2.MsgDeposit":
				return (msgAny.typeURL, try Cosmos_Gov_V1beta1_MsgDeposit(unpackingAny: msgAny))

				/* future
			case "/cosmos.group.v1beta1.MsgCreateGroupRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgCreateGroupRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupMembersRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupMembersRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAdminRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAdminRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupMetadataRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupMetadataRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgCreateGroupAccountRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgCreateGroupAccountRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountAdminRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAccountAdminRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountDecisionPolicyRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAccountDecisionPolicyRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountMetadataRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgUpdateGroupAccountMetadataRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgCreateProposalRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgCreateProposalRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgVoteRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgVoteRequest(unpackingAny: msgAny))
			case "/cosmos.group.v1beta1.MsgExecRequest":
				return(msgAny.typeURL, try Cosmos_Group_V1beta1_MsgExecRequest(unpackingAny: msgAny))

			case "/cosmos.nft.v1beta1.MsgSend":
				return(msgAny.typeURL, try Cosmos_Nft_V1beta1_MsgSend(unpackingAny: msgAny))

				 
				 */
			case "/cosmos.slashing.v1beta1.MsgUnjail":
				return (msgAny.typeURL, try Cosmos_Slashing_V1beta1_MsgUnjail(unpackingAny: msgAny))

			case "/cosmos.staking.v1beta1.MsgCreateValidator":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgCreateValidator(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgEditValidator":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgEditValidator(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgDelegate":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgDelegate(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgBeginRedelegate":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgBeginRedelegate(unpackingAny: msgAny))
			case "/cosmos.staking.v1beta1.MsgUndelegate":
				return (msgAny.typeURL, try Cosmos_Staking_V1beta1_MsgUndelegate(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.GetTxsEventRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_GetTxsEventRequest(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.BroadcastTxRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_BroadcastTxRequest(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.SimulateRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_SimulateRequest(unpackingAny: msgAny))

			case "/cosmos.tx.v1beta1.GetTxRequest":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_GetTxRequest(unpackingAny: msgAny))

			case "/cosmos.vesting.v1beta1.MsgCreateVestingAccount":
				return (msgAny.typeURL, try Cosmos_Vesting_V1beta1_MsgCreateVestingAccount(unpackingAny: msgAny))
				/* future
			case "/cosmos.vesting.v1beta1.MsgCreatePeriodicVestingAccount":
				return(msgAny.typeURL, try Cosmos_Vesting_V1beta1_MsgCreatePeriodicVestingAccount(unpackingAny: msgAny))
				 */
			case "/cosmos.bank.v1beta1.MsgSend":
				return (msgAny.typeURL, try Cosmos_Bank_V1beta1_MsgSend(unpackingAny: msgAny))

				/* Provenance Messages */

			case "/provenance.attribute.v1.MsgAddAttributeRequest":
				return (msgAny.typeURL, try Provenance_Attribute_V1_MsgAddAttributeRequest(unpackingAny: msgAny))
			case "/provenance.attribute.v1.MsgDeleteAttributeRequest":
				return (msgAny.typeURL, try Provenance_Attribute_V1_MsgDeleteAttributeRequest(unpackingAny: msgAny))
			case "/provenance.attribute.v1.MsgDeleteDistinctAttributeRequest":
				return (msgAny.typeURL,
						try Provenance_Attribute_V1_MsgDeleteDistinctAttributeRequest(unpackingAny: msgAny))
			case "/provenance.attribute.v1.MsgUpdateAttributeRequest":
				return (msgAny.typeURL, try Provenance_Attribute_V1_MsgUpdateAttributeRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgActivateRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgActivateRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgAddAccessRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgAddAccessRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgAddMarkerRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgAddMarkerRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgBurnRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgBurnRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgCancelRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgCancelRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgDeleteAccessRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgDeleteAccessRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgDeleteRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgDeleteRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgFinalizeRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgFinalizeRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgMintRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgMintRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgSetDenomMetadataRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgSetDenomMetadataRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgTransferRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgTransferRequest(unpackingAny: msgAny))
			case "/provenance.marker.v1.MsgWithdrawRequest":
				return (msgAny.typeURL, try Provenance_Marker_V1_MsgWithdrawRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgAddContractSpecToScopeSpecRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgAddContractSpecToScopeSpecRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgAddScopeDataAccessRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgAddScopeDataAccessRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgAddScopeOwnerRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgAddScopeOwnerRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgBindOSLocatorRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgBindOSLocatorRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteContractSpecFromScopeSpecRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteContractSpecFromScopeSpecRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteContractSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteOSLocatorRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteOSLocatorRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteRecordRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteRecordRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteRecordSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeDataAccessRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteScopeDataAccessRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeOwnerRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteScopeOwnerRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgDeleteScopeRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgDeleteScopeSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgModifyOSLocatorRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgModifyOSLocatorRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgP8eMemorializeContractRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgP8eMemorializeContractRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteContractSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgWriteContractSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteP8eContractSpecRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteRecordRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteRecordRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteRecordSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteScopeRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteScopeRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteScopeSpecificationRequest":
				return (msgAny.typeURL,
						try Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest(unpackingAny: msgAny))
			case "/provenance.metadata.v1.MsgWriteSessionRequest":
				return (msgAny.typeURL, try Provenance_Metadata_V1_MsgWriteSessionRequest(unpackingAny: msgAny))
			case "/provenance.name.v1.MsgBindNameRequest":
				return (msgAny.typeURL, try Provenance_Name_V1_MsgBindNameRequest(unpackingAny: msgAny))
			case "/provenance.name.v1.MsgDeleteNameRequest":
				return (msgAny.typeURL, try Provenance_Name_V1_MsgDeleteNameRequest(unpackingAny: msgAny))

				/* CosmWasm Messages */

			case "/cosmwasm.wasm.v1.MsgClearAdmin":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgClearAdmin(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgExecuteContract":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgExecuteContract(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgInstantiateContract":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgInstantiateContract(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgMigrateContract":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgMigrateContract(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgStoreCode":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgStoreCode(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgUpdateAdmin":
				return (msgAny.typeURL, try Cosmwasm_Wasm_V1_MsgUpdateAdmin(unpackingAny: msgAny))
			case "/cosmwasm.wasm.v1.MsgUpdateAdmin":
				return (msgAny.typeURL, try Cosmos_Tx_V1beta1_TxBody(unpackingAny: msgAny))
			default:
				throw ProvenanceWalletError(kind: .unsupportedProvenanceMessage,
				                            message: "wallet does not support \(msgAny.typeURL)",
				                            messages: nil,
				                            underlyingError: nil)
		}


	}
}
