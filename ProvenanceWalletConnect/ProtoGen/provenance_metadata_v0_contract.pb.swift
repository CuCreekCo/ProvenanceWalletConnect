// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: provenance/metadata/v0/contract.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
fileprivate struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

enum Contract_ExecutionResultType: SwiftProtobuf.Enum {
  typealias RawValue = Int
  case resultTypeUnknown // = 0
  case resultTypePass // = 1

  /// Couldn't process the condition/consideration due to missing facts being generated by other considerations.
  case resultTypeSkip // = 2
  case resultTypeFail // = 3
  case UNRECOGNIZED(Int)

  init() {
    self = .resultTypeUnknown
  }

  init?(rawValue: Int) {
    switch rawValue {
    case 0: self = .resultTypeUnknown
    case 1: self = .resultTypePass
    case 2: self = .resultTypeSkip
    case 3: self = .resultTypeFail
    default: self = .UNRECOGNIZED(rawValue)
    }
  }

  var rawValue: Int {
    switch self {
    case .resultTypeUnknown: return 0
    case .resultTypePass: return 1
    case .resultTypeSkip: return 2
    case .resultTypeFail: return 3
    case .UNRECOGNIZED(let i): return i
    }
  }

}

#if swift(>=4.2)

extension Contract_ExecutionResultType: CaseIterable {
  // The compiler won't synthesize support with the UNRECOGNIZED case.
  static var allCases: [Contract_ExecutionResultType] = [
    .resultTypeUnknown,
    .resultTypePass,
    .resultTypeSkip,
    .resultTypeFail,
  ]
}

#endif  // swift(>=4.2)

struct Contract_Recital {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var signerRole: Types_PartyType = .unknown

  var signer: Types_SigningAndEncryptionPublicKeys {
    get {return _signer ?? Types_SigningAndEncryptionPublicKeys()}
    set {_signer = newValue}
  }
  /// Returns true if `signer` has been explicitly set.
  var hasSigner: Bool {return self._signer != nil}
  /// Clears the value of `signer`. Subsequent reads from it will return its default value.
  mutating func clearSigner() {self._signer = nil}

  var address: Data = Data()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _signer: Types_SigningAndEncryptionPublicKeys? = nil
}

struct Contract_Recitals {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var parties: [Contract_Recital] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

struct Contract_Contract {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var definition: Spec_DefinitionSpec {
    get {return _storage._definition ?? Spec_DefinitionSpec()}
    set {_uniqueStorage()._definition = newValue}
  }
  /// Returns true if `definition` has been explicitly set.
  var hasDefinition: Bool {return _storage._definition != nil}
  /// Clears the value of `definition`. Subsequent reads from it will return its default value.
  mutating func clearDefinition() {_uniqueStorage()._definition = nil}

  /// Points to the proto for the contractSpec
  var spec: Types_Fact {
    get {return _storage._spec ?? Types_Fact()}
    set {_uniqueStorage()._spec = newValue}
  }
  /// Returns true if `spec` has been explicitly set.
  var hasSpec: Bool {return _storage._spec != nil}
  /// Clears the value of `spec`. Subsequent reads from it will return its default value.
  mutating func clearSpec() {_uniqueStorage()._spec = nil}

  /// Invoker of this contract
  var invoker: Types_SigningAndEncryptionPublicKeys {
    get {return _storage._invoker ?? Types_SigningAndEncryptionPublicKeys()}
    set {_uniqueStorage()._invoker = newValue}
  }
  /// Returns true if `invoker` has been explicitly set.
  var hasInvoker: Bool {return _storage._invoker != nil}
  /// Clears the value of `invoker`. Subsequent reads from it will return its default value.
  mutating func clearInvoker() {_uniqueStorage()._invoker = nil}

  /// Constructor arguments.
  /// These are always the output of a previously recorded consideration.
  var inputs: [Types_Fact] {
    get {return _storage._inputs}
    set {_uniqueStorage()._inputs = newValue}
  }

  var conditions: [Contract_Condition] {
    get {return _storage._conditions}
    set {_uniqueStorage()._conditions = newValue}
  }

  var considerations: [Contract_Consideration] {
    get {return _storage._considerations}
    set {_uniqueStorage()._considerations = newValue}
  }

  var recitals: [Contract_Recital] {
    get {return _storage._recitals}
    set {_uniqueStorage()._recitals = newValue}
  }

  var timesExecuted: Int32 {
    get {return _storage._timesExecuted}
    set {_uniqueStorage()._timesExecuted = newValue}
  }

  /// This is only set once when the contract is initially executed
  var startTime: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _storage._startTime ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_uniqueStorage()._startTime = newValue}
  }
  /// Returns true if `startTime` has been explicitly set.
  var hasStartTime: Bool {return _storage._startTime != nil}
  /// Clears the value of `startTime`. Subsequent reads from it will return its default value.
  mutating func clearStartTime() {_uniqueStorage()._startTime = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _storage = _StorageClass.defaultInstance
}

struct Contract_Condition {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var conditionName: String = String()

  var result: Contract_ExecutionResult {
    get {return _result ?? Contract_ExecutionResult()}
    set {_result = newValue}
  }
  /// Returns true if `result` has been explicitly set.
  var hasResult: Bool {return self._result != nil}
  /// Clears the value of `result`. Subsequent reads from it will return its default value.
  mutating func clearResult() {self._result = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _result: Contract_ExecutionResult? = nil
}

struct Contract_Consideration {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var considerationName: String = String()

  /// Data pushed to a consideration that will ultimately match the output_spec of the consideration
  var inputs: [Contract_ProposedFact] = []

  var result: Contract_ExecutionResult {
    get {return _result ?? Contract_ExecutionResult()}
    set {_result = newValue}
  }
  /// Returns true if `result` has been explicitly set.
  var hasResult: Bool {return self._result != nil}
  /// Clears the value of `result`. Subsequent reads from it will return its default value.
  mutating func clearResult() {self._result = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _result: Contract_ExecutionResult? = nil
}

/// Input to a consideration defined at runtime, and emitted as a proposed fact for inclusion on the blockchain.
struct Contract_ProposedFact {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var name: String = String()

  var hash: String = String()

  var classname: String = String()

  var ancestor: Types_ProvenanceReference {
    get {return _ancestor ?? Types_ProvenanceReference()}
    set {_ancestor = newValue}
  }
  /// Returns true if `ancestor` has been explicitly set.
  var hasAncestor: Bool {return self._ancestor != nil}
  /// Clears the value of `ancestor`. Subsequent reads from it will return its default value.
  mutating func clearAncestor() {self._ancestor = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _ancestor: Types_ProvenanceReference? = nil
}

struct Contract_ExecutionResult {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var output: Contract_ProposedFact {
    get {return _output ?? Contract_ProposedFact()}
    set {_output = newValue}
  }
  /// Returns true if `output` has been explicitly set.
  var hasOutput: Bool {return self._output != nil}
  /// Clears the value of `output`. Subsequent reads from it will return its default value.
  mutating func clearOutput() {self._output = nil}

  var result: Contract_ExecutionResultType = .resultTypeUnknown

  var recordedAt: SwiftProtobuf.Google_Protobuf_Timestamp {
    get {return _recordedAt ?? SwiftProtobuf.Google_Protobuf_Timestamp()}
    set {_recordedAt = newValue}
  }
  /// Returns true if `recordedAt` has been explicitly set.
  var hasRecordedAt: Bool {return self._recordedAt != nil}
  /// Clears the value of `recordedAt`. Subsequent reads from it will return its default value.
  mutating func clearRecordedAt() {self._recordedAt = nil}

  var errorMessage: String = String()

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _output: Contract_ProposedFact? = nil
  fileprivate var _recordedAt: SwiftProtobuf.Google_Protobuf_Timestamp? = nil
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "contract"

extension Contract_ExecutionResultType: SwiftProtobuf._ProtoNameProviding {
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    0: .same(proto: "RESULT_TYPE_UNKNOWN"),
    1: .same(proto: "RESULT_TYPE_PASS"),
    2: .same(proto: "RESULT_TYPE_SKIP"),
    3: .same(proto: "RESULT_TYPE_FAIL"),
  ]
}

extension Contract_Recital: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Recital"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "signer_role"),
    2: .same(proto: "signer"),
    3: .same(proto: "address"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self.signerRole) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._signer) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self.address) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.signerRole != .unknown {
      try visitor.visitSingularEnumField(value: self.signerRole, fieldNumber: 1)
    }
    if let v = self._signer {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    if !self.address.isEmpty {
      try visitor.visitSingularBytesField(value: self.address, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_Recital, rhs: Contract_Recital) -> Bool {
    if lhs.signerRole != rhs.signerRole {return false}
    if lhs._signer != rhs._signer {return false}
    if lhs.address != rhs.address {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Contract_Recitals: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Recitals"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "parties"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedMessageField(value: &self.parties) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.parties.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.parties, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_Recitals, rhs: Contract_Recitals) -> Bool {
    if lhs.parties != rhs.parties {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Contract_Contract: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Contract"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "definition"),
    2: .same(proto: "spec"),
    3: .same(proto: "invoker"),
    4: .same(proto: "inputs"),
    5: .same(proto: "conditions"),
    6: .same(proto: "considerations"),
    7: .same(proto: "recitals"),
    8: .standard(proto: "times_executed"),
    9: .standard(proto: "start_time"),
  ]

  fileprivate class _StorageClass {
    var _definition: Spec_DefinitionSpec? = nil
    var _spec: Types_Fact? = nil
    var _invoker: Types_SigningAndEncryptionPublicKeys? = nil
    var _inputs: [Types_Fact] = []
    var _conditions: [Contract_Condition] = []
    var _considerations: [Contract_Consideration] = []
    var _recitals: [Contract_Recital] = []
    var _timesExecuted: Int32 = 0
    var _startTime: SwiftProtobuf.Google_Protobuf_Timestamp? = nil

    static let defaultInstance = _StorageClass()

    private init() {}

    init(copying source: _StorageClass) {
      _definition = source._definition
      _spec = source._spec
      _invoker = source._invoker
      _inputs = source._inputs
      _conditions = source._conditions
      _considerations = source._considerations
      _recitals = source._recitals
      _timesExecuted = source._timesExecuted
      _startTime = source._startTime
    }
  }

  fileprivate mutating func _uniqueStorage() -> _StorageClass {
    if !isKnownUniquelyReferenced(&_storage) {
      _storage = _StorageClass(copying: _storage)
    }
    return _storage
  }

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    _ = _uniqueStorage()
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      while let fieldNumber = try decoder.nextFieldNumber() {
        // The use of inline closures is to circumvent an issue where the compiler
        // allocates stack space for every case branch when no optimizations are
        // enabled. https://github.com/apple/swift-protobuf/issues/1034
        switch fieldNumber {
        case 1: try { try decoder.decodeSingularMessageField(value: &_storage._definition) }()
        case 2: try { try decoder.decodeSingularMessageField(value: &_storage._spec) }()
        case 3: try { try decoder.decodeSingularMessageField(value: &_storage._invoker) }()
        case 4: try { try decoder.decodeRepeatedMessageField(value: &_storage._inputs) }()
        case 5: try { try decoder.decodeRepeatedMessageField(value: &_storage._conditions) }()
        case 6: try { try decoder.decodeRepeatedMessageField(value: &_storage._considerations) }()
        case 7: try { try decoder.decodeRepeatedMessageField(value: &_storage._recitals) }()
        case 8: try { try decoder.decodeSingularInt32Field(value: &_storage._timesExecuted) }()
        case 9: try { try decoder.decodeSingularMessageField(value: &_storage._startTime) }()
        default: break
        }
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    try withExtendedLifetime(_storage) { (_storage: _StorageClass) in
      if let v = _storage._definition {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
      }
      if let v = _storage._spec {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
      }
      if let v = _storage._invoker {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
      }
      if !_storage._inputs.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._inputs, fieldNumber: 4)
      }
      if !_storage._conditions.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._conditions, fieldNumber: 5)
      }
      if !_storage._considerations.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._considerations, fieldNumber: 6)
      }
      if !_storage._recitals.isEmpty {
        try visitor.visitRepeatedMessageField(value: _storage._recitals, fieldNumber: 7)
      }
      if _storage._timesExecuted != 0 {
        try visitor.visitSingularInt32Field(value: _storage._timesExecuted, fieldNumber: 8)
      }
      if let v = _storage._startTime {
        try visitor.visitSingularMessageField(value: v, fieldNumber: 9)
      }
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_Contract, rhs: Contract_Contract) -> Bool {
    if lhs._storage !== rhs._storage {
      let storagesAreEqual: Bool = withExtendedLifetime((lhs._storage, rhs._storage)) { (_args: (_StorageClass, _StorageClass)) in
        let _storage = _args.0
        let rhs_storage = _args.1
        if _storage._definition != rhs_storage._definition {return false}
        if _storage._spec != rhs_storage._spec {return false}
        if _storage._invoker != rhs_storage._invoker {return false}
        if _storage._inputs != rhs_storage._inputs {return false}
        if _storage._conditions != rhs_storage._conditions {return false}
        if _storage._considerations != rhs_storage._considerations {return false}
        if _storage._recitals != rhs_storage._recitals {return false}
        if _storage._timesExecuted != rhs_storage._timesExecuted {return false}
        if _storage._startTime != rhs_storage._startTime {return false}
        return true
      }
      if !storagesAreEqual {return false}
    }
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Contract_Condition: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Condition"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "condition_name"),
    2: .same(proto: "result"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.conditionName) }()
      case 2: try { try decoder.decodeSingularMessageField(value: &self._result) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.conditionName.isEmpty {
      try visitor.visitSingularStringField(value: self.conditionName, fieldNumber: 1)
    }
    if let v = self._result {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 2)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_Condition, rhs: Contract_Condition) -> Bool {
    if lhs.conditionName != rhs.conditionName {return false}
    if lhs._result != rhs._result {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Contract_Consideration: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Consideration"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "consideration_name"),
    2: .same(proto: "inputs"),
    3: .same(proto: "result"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.considerationName) }()
      case 2: try { try decoder.decodeRepeatedMessageField(value: &self.inputs) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._result) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.considerationName.isEmpty {
      try visitor.visitSingularStringField(value: self.considerationName, fieldNumber: 1)
    }
    if !self.inputs.isEmpty {
      try visitor.visitRepeatedMessageField(value: self.inputs, fieldNumber: 2)
    }
    if let v = self._result {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_Consideration, rhs: Contract_Consideration) -> Bool {
    if lhs.considerationName != rhs.considerationName {return false}
    if lhs.inputs != rhs.inputs {return false}
    if lhs._result != rhs._result {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Contract_ProposedFact: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ProposedFact"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "name"),
    2: .same(proto: "hash"),
    3: .same(proto: "classname"),
    4: .same(proto: "ancestor"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularStringField(value: &self.name) }()
      case 2: try { try decoder.decodeSingularStringField(value: &self.hash) }()
      case 3: try { try decoder.decodeSingularStringField(value: &self.classname) }()
      case 4: try { try decoder.decodeSingularMessageField(value: &self._ancestor) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.name.isEmpty {
      try visitor.visitSingularStringField(value: self.name, fieldNumber: 1)
    }
    if !self.hash.isEmpty {
      try visitor.visitSingularStringField(value: self.hash, fieldNumber: 2)
    }
    if !self.classname.isEmpty {
      try visitor.visitSingularStringField(value: self.classname, fieldNumber: 3)
    }
    if let v = self._ancestor {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_ProposedFact, rhs: Contract_ProposedFact) -> Bool {
    if lhs.name != rhs.name {return false}
    if lhs.hash != rhs.hash {return false}
    if lhs.classname != rhs.classname {return false}
    if lhs._ancestor != rhs._ancestor {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Contract_ExecutionResult: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".ExecutionResult"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "output"),
    2: .same(proto: "result"),
    3: .standard(proto: "recorded_at"),
    4: .standard(proto: "error_message"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularMessageField(value: &self._output) }()
      case 2: try { try decoder.decodeSingularEnumField(value: &self.result) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._recordedAt) }()
      case 4: try { try decoder.decodeSingularStringField(value: &self.errorMessage) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if let v = self._output {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 1)
    }
    if self.result != .resultTypeUnknown {
      try visitor.visitSingularEnumField(value: self.result, fieldNumber: 2)
    }
    if let v = self._recordedAt {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    }
    if !self.errorMessage.isEmpty {
      try visitor.visitSingularStringField(value: self.errorMessage, fieldNumber: 4)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Contract_ExecutionResult, rhs: Contract_ExecutionResult) -> Bool {
    if lhs._output != rhs._output {return false}
    if lhs.result != rhs.result {return false}
    if lhs._recordedAt != rhs._recordedAt {return false}
    if lhs.errorMessage != rhs.errorMessage {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
