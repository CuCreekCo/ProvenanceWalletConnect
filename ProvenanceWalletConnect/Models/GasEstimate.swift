//
// Created by JD on 2/12/22.
//

import Foundation
import ProvWallet

class GasEstimate: NSObject {
    let gasInfo: Cosmos_Base_Abci_V1beta1_GasInfo!
    let gas: UInt64!
    let gasFee: Double!
    let denom: String!

    init(gasInfo: Cosmos_Base_Abci_V1beta1_GasInfo!, gas: UInt64!, gasFee: Double!, denom: String) {
        self.gasInfo = gasInfo
        self.gas = gas
        self.gasFee = gasFee
        self.denom = denom
        super.init()
    }
}