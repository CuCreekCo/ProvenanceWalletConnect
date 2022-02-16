//
// Created by JD on 2/16/22.
//

import Foundation
import SwiftProtobuf

struct TxMessageRequest {
    let type: String
    let message: Message
}

extension TxMessageRequest {
    public func typeTitle() -> String {
        type.substringAfterLast(".").camelCaseToWords()
    }
}