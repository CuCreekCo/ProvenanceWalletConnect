// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: cosmos/base/snapshots/v1beta1/snapshot.proto
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

/// Snapshot contains Tendermint state sync snapshot info.
struct Cosmos_Base_Snapshots_V1beta1_Snapshot {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  var height: UInt64 = 0

  var format: UInt32 = 0

  var chunks: UInt32 = 0

  var hash: Data = Data()

  var metadata: Cosmos_Base_Snapshots_V1beta1_Metadata {
    get {return _metadata ?? Cosmos_Base_Snapshots_V1beta1_Metadata()}
    set {_metadata = newValue}
  }
  /// Returns true if `metadata` has been explicitly set.
  var hasMetadata: Bool {return self._metadata != nil}
  /// Clears the value of `metadata`. Subsequent reads from it will return its default value.
  mutating func clearMetadata() {self._metadata = nil}

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}

  fileprivate var _metadata: Cosmos_Base_Snapshots_V1beta1_Metadata? = nil
}

/// Metadata contains SDK-specific snapshot metadata.
struct Cosmos_Base_Snapshots_V1beta1_Metadata {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// SHA-256 chunk hashes
  var chunkHashes: [Data] = []

  var unknownFields = SwiftProtobuf.UnknownStorage()

  init() {}
}

// MARK: - Code below here is support for the SwiftProtobuf runtime.

fileprivate let _protobuf_package = "cosmos.base.snapshots.v1beta1"

extension Cosmos_Base_Snapshots_V1beta1_Snapshot: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Snapshot"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "height"),
    2: .same(proto: "format"),
    3: .same(proto: "chunks"),
    4: .same(proto: "hash"),
    5: .same(proto: "metadata"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularUInt64Field(value: &self.height) }()
      case 2: try { try decoder.decodeSingularUInt32Field(value: &self.format) }()
      case 3: try { try decoder.decodeSingularUInt32Field(value: &self.chunks) }()
      case 4: try { try decoder.decodeSingularBytesField(value: &self.hash) }()
      case 5: try { try decoder.decodeSingularMessageField(value: &self._metadata) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if self.height != 0 {
      try visitor.visitSingularUInt64Field(value: self.height, fieldNumber: 1)
    }
    if self.format != 0 {
      try visitor.visitSingularUInt32Field(value: self.format, fieldNumber: 2)
    }
    if self.chunks != 0 {
      try visitor.visitSingularUInt32Field(value: self.chunks, fieldNumber: 3)
    }
    if !self.hash.isEmpty {
      try visitor.visitSingularBytesField(value: self.hash, fieldNumber: 4)
    }
    if let v = self._metadata {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 5)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Cosmos_Base_Snapshots_V1beta1_Snapshot, rhs: Cosmos_Base_Snapshots_V1beta1_Snapshot) -> Bool {
    if lhs.height != rhs.height {return false}
    if lhs.format != rhs.format {return false}
    if lhs.chunks != rhs.chunks {return false}
    if lhs.hash != rhs.hash {return false}
    if lhs._metadata != rhs._metadata {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Cosmos_Base_Snapshots_V1beta1_Metadata: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  static let protoMessageName: String = _protobuf_package + ".Metadata"
  static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "chunk_hashes"),
  ]

  mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeRepeatedBytesField(value: &self.chunkHashes) }()
      default: break
      }
    }
  }

  func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    if !self.chunkHashes.isEmpty {
      try visitor.visitRepeatedBytesField(value: self.chunkHashes, fieldNumber: 1)
    }
    try unknownFields.traverse(visitor: &visitor)
  }

  static func ==(lhs: Cosmos_Base_Snapshots_V1beta1_Metadata, rhs: Cosmos_Base_Snapshots_V1beta1_Metadata) -> Bool {
    if lhs.chunkHashes != rhs.chunkHashes {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
