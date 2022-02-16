//
// Created by Jason Davidson on 2/4/22.
//

import Foundation
import WalletConnectSwift
import SwiftyJSON
import SwiftProtobuf
import ProvWallet

extension Request {
    func messages() -> [String] {
        var r:[String] = []
        for index in 1..<self.parameterCount {
            do {
                r.append(try self.parameter(of: String.self, at: index))
            } catch {
                Utilities.log(error)
                r.append("\(error)")
            }
        }
        return r
    }

    func metadata() throws -> String {
        try self.parameter(of: String.self, at: 0)
    }

    func metadataJSON() throws -> JSON {
        JSON.init(parseJSON: try metadata());
    }

    func description() -> String {
        do {
            return try metadataJSON()["description"].stringValue
        } catch {
            Utilities.log(error)
            return "undefined"
        }
    }

    func address() throws -> String {
        try metadataJSON()["address"].stringValue
    }

    private func toTxMessageRequest(typeURL: String, message: Message) -> TxMessageRequest {
        TxMessageRequest(type: typeURL, message: message)
    }

    func decodeMessages() throws -> [TxMessageRequest] {
        /*
		 Provenance walletconnect-js sends requests as an array where
		 the first array element is metadata and subsequent elements
         are message(s)
		 */

        var txMessageRequests: [TxMessageRequest] = []

        let messages = messages()
        for index in 0..<messages.count {
            let msgHex = messages[index]
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
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Authz_V1beta1_MsgGrant(unpackingAny: msgAny)))
            case "/cosmos.authz.v1beta1.MsgExec":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Authz_V1beta1_MsgExec(unpackingAny: msgAny)))
            case "/cosmos.authz.v1beta1.MsgRevoke":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Authz_V1beta1_MsgRevoke(unpackingAny: msgAny)))

            case "/cosmos.bank.v1beta1.MsgMultiSend":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Bank_V1beta1_MsgMultiSend(unpackingAny: msgAny)))

            case "/cosmos.crisis.v1beta1.MsgVerifyInvariant":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Crisis_V1beta1_MsgVerifyInvariant(unpackingAny: msgAny)))

            case "/cosmos.distribution.v1beta1.MsgSetWithdrawAddress":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Distribution_V1beta1_MsgSetWithdrawAddress(unpackingAny: msgAny)))
            case "/cosmos.distribution.v1beta1.MsgWithdrawDelegatorReward":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Cosmos_Distribution_V1beta1_MsgWithdrawDelegatorReward(unpackingAny: msgAny)))
            case "/cosmos.distribution.v1beta1.MsgWithdrawValidatorCommission":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Cosmos_Distribution_V1beta1_MsgWithdrawValidatorCommission(unpackingAny: msgAny)))
            case "/cosmos.distribution.v1beta1.MsgFundCommunityPool":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Distribution_V1beta1_MsgFundCommunityPool(unpackingAny: msgAny)))

            case "/cosmos.evidence.v1beta1.MsgSubmitEvidence":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Evidence_V1beta1_MsgSubmitEvidence(unpackingAny: msgAny)))

            case "/cosmos.feegrant.v1beta1.MsgGrantAllowance":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Feegrant_V1beta1_MsgGrantAllowance(unpackingAny: msgAny)))
            case "/cosmos.feegrant.v1beta1.MsgRevokeAllowance":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Feegrant_V1beta1_MsgRevokeAllowance(unpackingAny: msgAny)))

            case "/cosmos.gov.v1beta1.MsgSubmitProposal":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgSubmitProposal(unpackingAny: msgAny)))
            case "/cosmos.gov.v1beta1.MsgVote":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgVote(unpackingAny: msgAny)))
            case "/cosmos.gov.v1beta1.MsgVoteWeighted":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgVoteWeighted(unpackingAny: msgAny)))
            case "/cosmos.gov.v1beta1.MsgDeposit":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgDeposit(unpackingAny: msgAny)))

            case "/cosmos.gov.v1beta2.MsgSubmitProposal":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgSubmitProposal(unpackingAny: msgAny)))
            case "/cosmos.gov.v1beta2.MsgVote":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgVote(unpackingAny: msgAny)))
            case "/cosmos.gov.v1beta2.MsgVoteWeighted":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgVoteWeighted(unpackingAny: msgAny)))
            case "/cosmos.gov.v1beta2.MsgDeposit":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Gov_V1beta1_MsgDeposit(unpackingAny: msgAny)))

                    /* future
			case "/cosmos.group.v1beta1.MsgCreateGroupRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgCreateGroupRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgUpdateGroupMembersRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgUpdateGroupMembersRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAdminRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgUpdateGroupAdminRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgUpdateGroupMetadataRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgUpdateGroupMetadataRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgCreateGroupAccountRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgCreateGroupAccountRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountAdminRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgUpdateGroupAccountAdminRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountDecisionPolicyRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgUpdateGroupAccountDecisionPolicyRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgUpdateGroupAccountMetadataRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgUpdateGroupAccountMetadataRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgCreateProposalRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgCreateProposalRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgVoteRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgVoteRequest(unpackingAny: msgAny)))
			case "/cosmos.group.v1beta1.MsgExecRequest":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Group_V1beta1_MsgExecRequest(unpackingAny: msgAny)))

			case "/cosmos.nft.v1beta1.MsgSend":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Nft_V1beta1_MsgSend(unpackingAny: msgAny)))


				 */
            case "/cosmos.slashing.v1beta1.MsgUnjail":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Slashing_V1beta1_MsgUnjail(unpackingAny: msgAny)))

            case "/cosmos.staking.v1beta1.MsgCreateValidator":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Staking_V1beta1_MsgCreateValidator(unpackingAny: msgAny)))
            case "/cosmos.staking.v1beta1.MsgEditValidator":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Staking_V1beta1_MsgEditValidator(unpackingAny: msgAny)))
            case "/cosmos.staking.v1beta1.MsgDelegate":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Staking_V1beta1_MsgDelegate(unpackingAny: msgAny)))
            case "/cosmos.staking.v1beta1.MsgBeginRedelegate":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Staking_V1beta1_MsgBeginRedelegate(unpackingAny: msgAny)))
            case "/cosmos.staking.v1beta1.MsgUndelegate":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Staking_V1beta1_MsgUndelegate(unpackingAny: msgAny)))

            case "/cosmos.tx.v1beta1.GetTxsEventRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Tx_V1beta1_GetTxsEventRequest(unpackingAny: msgAny)))

            case "/cosmos.tx.v1beta1.BroadcastTxRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Tx_V1beta1_BroadcastTxRequest(unpackingAny: msgAny)))

            case "/cosmos.tx.v1beta1.SimulateRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Tx_V1beta1_SimulateRequest(unpackingAny: msgAny)))

            case "/cosmos.tx.v1beta1.GetTxRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Tx_V1beta1_GetTxRequest(unpackingAny: msgAny)))

            case "/cosmos.vesting.v1beta1.MsgCreateVestingAccount":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Vesting_V1beta1_MsgCreateVestingAccount(unpackingAny: msgAny)))
                    /* future
			case "/cosmos.vesting.v1beta1.MsgCreatePeriodicVestingAccount":
				txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Vesting_V1beta1_MsgCreatePeriodicVestingAccount(unpackingAny: msgAny)))
				 */
            case "/cosmos.bank.v1beta1.MsgSend":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Bank_V1beta1_MsgSend(unpackingAny: msgAny)))

                    /* Provenance Messages */

            case "/provenance.attribute.v1.MsgAddAttributeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Attribute_V1_MsgAddAttributeRequest(unpackingAny: msgAny)))
            case "/provenance.attribute.v1.MsgDeleteAttributeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Attribute_V1_MsgDeleteAttributeRequest(unpackingAny: msgAny)))
            case "/provenance.attribute.v1.MsgDeleteDistinctAttributeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Attribute_V1_MsgDeleteDistinctAttributeRequest(unpackingAny: msgAny)))
            case "/provenance.attribute.v1.MsgUpdateAttributeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Attribute_V1_MsgUpdateAttributeRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgActivateRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgActivateRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgAddAccessRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgAddAccessRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgAddMarkerRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgAddMarkerRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgBurnRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgBurnRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgCancelRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgCancelRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgDeleteAccessRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgDeleteAccessRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgDeleteRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgDeleteRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgFinalizeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgFinalizeRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgMintRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgMintRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgSetDenomMetadataRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgSetDenomMetadataRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgTransferRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgTransferRequest(unpackingAny: msgAny)))
            case "/provenance.marker.v1.MsgWithdrawRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Marker_V1_MsgWithdrawRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgAddContractSpecToScopeSpecRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgAddContractSpecToScopeSpecRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgAddScopeDataAccessRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgAddScopeDataAccessRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgAddScopeOwnerRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgAddScopeOwnerRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgBindOSLocatorRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgBindOSLocatorRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteContractSpecFromScopeSpecRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgDeleteContractSpecFromScopeSpecRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteContractSpecificationRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteOSLocatorRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgDeleteOSLocatorRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteRecordRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgDeleteRecordRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteRecordSpecificationRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteScopeDataAccessRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgDeleteScopeDataAccessRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteScopeOwnerRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgDeleteScopeOwnerRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteScopeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgDeleteScopeRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgDeleteScopeSpecificationRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgModifyOSLocatorRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgModifyOSLocatorRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgP8eMemorializeContractRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgP8eMemorializeContractRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteContractSpecificationRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgWriteContractSpecificationRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteP8eContractSpecRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteRecordRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgWriteRecordRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteRecordSpecificationRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteScopeRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgWriteScopeRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteScopeSpecificationRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL,
                        message: try Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest(unpackingAny: msgAny)))
            case "/provenance.metadata.v1.MsgWriteSessionRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Metadata_V1_MsgWriteSessionRequest(unpackingAny: msgAny)))
            case "/provenance.name.v1.MsgBindNameRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Name_V1_MsgBindNameRequest(unpackingAny: msgAny)))
            case "/provenance.name.v1.MsgDeleteNameRequest":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Provenance_Name_V1_MsgDeleteNameRequest(unpackingAny: msgAny)))

                    /* CosmWasm Messages */

            case "/cosmwasm.wasm.v1.MsgClearAdmin":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmwasm_Wasm_V1_MsgClearAdmin(unpackingAny: msgAny)))
            case "/cosmwasm.wasm.v1.MsgExecuteContract":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmwasm_Wasm_V1_MsgExecuteContract(unpackingAny: msgAny)))
            case "/cosmwasm.wasm.v1.MsgInstantiateContract":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmwasm_Wasm_V1_MsgInstantiateContract(unpackingAny: msgAny)))
            case "/cosmwasm.wasm.v1.MsgMigrateContract":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmwasm_Wasm_V1_MsgMigrateContract(unpackingAny: msgAny)))
            case "/cosmwasm.wasm.v1.MsgStoreCode":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmwasm_Wasm_V1_MsgStoreCode(unpackingAny: msgAny)))
            case "/cosmwasm.wasm.v1.MsgUpdateAdmin":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmwasm_Wasm_V1_MsgUpdateAdmin(unpackingAny: msgAny)))
            case "/cosmwasm.wasm.v1.MsgUpdateAdmin":
                txMessageRequests.append(toTxMessageRequest(typeURL: msgAny.typeURL, message: try Cosmos_Tx_V1beta1_TxBody(unpackingAny: msgAny)))
            default:
                throw ProvenanceWalletError(kind: .unsupportedProvenanceMessage,
                        message: "wallet does not support \(msgAny.typeURL)",
                        messages: nil,
                        underlyingError: nil)
            }

        }
        return txMessageRequests
    }


}

