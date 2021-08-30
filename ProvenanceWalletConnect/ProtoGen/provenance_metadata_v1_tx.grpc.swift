//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: provenance/metadata/v1/tx.proto
//

//
// Copyright 2018, gRPC Authors All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
import GRPC
import NIO
import SwiftProtobuf


/// Msg defines the Metadata Msg service.
///
/// Usage: instantiate `Provenance_Metadata_V1_MsgClient`, then call methods of this protocol to make API calls.
internal protocol Provenance_Metadata_V1_MsgClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Provenance_Metadata_V1_MsgClientInterceptorFactoryProtocol? { get }

  func writeScope(
    _ request: Provenance_Metadata_V1_MsgWriteScopeRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteScopeRequest, Provenance_Metadata_V1_MsgWriteScopeResponse>

  func deleteScope(
    _ request: Provenance_Metadata_V1_MsgDeleteScopeRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteScopeRequest, Provenance_Metadata_V1_MsgDeleteScopeResponse>

  func writeSession(
    _ request: Provenance_Metadata_V1_MsgWriteSessionRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteSessionRequest, Provenance_Metadata_V1_MsgWriteSessionResponse>

  func writeRecord(
    _ request: Provenance_Metadata_V1_MsgWriteRecordRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteRecordRequest, Provenance_Metadata_V1_MsgWriteRecordResponse>

  func deleteRecord(
    _ request: Provenance_Metadata_V1_MsgDeleteRecordRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteRecordRequest, Provenance_Metadata_V1_MsgDeleteRecordResponse>

  func writeScopeSpecification(
    _ request: Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest, Provenance_Metadata_V1_MsgWriteScopeSpecificationResponse>

  func deleteScopeSpecification(
    _ request: Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest, Provenance_Metadata_V1_MsgDeleteScopeSpecificationResponse>

  func writeContractSpecification(
    _ request: Provenance_Metadata_V1_MsgWriteContractSpecificationRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteContractSpecificationRequest, Provenance_Metadata_V1_MsgWriteContractSpecificationResponse>

  func deleteContractSpecification(
    _ request: Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest, Provenance_Metadata_V1_MsgDeleteContractSpecificationResponse>

  func writeRecordSpecification(
    _ request: Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest, Provenance_Metadata_V1_MsgWriteRecordSpecificationResponse>

  func deleteRecordSpecification(
    _ request: Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest, Provenance_Metadata_V1_MsgDeleteRecordSpecificationResponse>

  func writeP8eContractSpec(
    _ request: Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest, Provenance_Metadata_V1_MsgWriteP8eContractSpecResponse>

  func p8eMemorializeContract(
    _ request: Provenance_Metadata_V1_MsgP8eMemorializeContractRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgP8eMemorializeContractRequest, Provenance_Metadata_V1_MsgP8eMemorializeContractResponse>

  func bindOSLocator(
    _ request: Provenance_Metadata_V1_MsgBindOSLocatorRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgBindOSLocatorRequest, Provenance_Metadata_V1_MsgBindOSLocatorResponse>

  func deleteOSLocator(
    _ request: Provenance_Metadata_V1_MsgDeleteOSLocatorRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteOSLocatorRequest, Provenance_Metadata_V1_MsgDeleteOSLocatorResponse>

  func modifyOSLocator(
    _ request: Provenance_Metadata_V1_MsgModifyOSLocatorRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Provenance_Metadata_V1_MsgModifyOSLocatorRequest, Provenance_Metadata_V1_MsgModifyOSLocatorResponse>
}

extension Provenance_Metadata_V1_MsgClientProtocol {
  internal var serviceName: String {
    return "provenance.metadata.v1.Msg"
  }

  /// WriteScope adds or updates a scope.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteScope.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeScope(
    _ request: Provenance_Metadata_V1_MsgWriteScopeRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteScopeRequest, Provenance_Metadata_V1_MsgWriteScopeResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteScope",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteScopeInterceptors() ?? []
    )
  }

  /// DeleteScope deletes a scope and all associated Records, Sessions.
  ///
  /// - Parameters:
  ///   - request: Request to send to DeleteScope.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func deleteScope(
    _ request: Provenance_Metadata_V1_MsgDeleteScopeRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteScopeRequest, Provenance_Metadata_V1_MsgDeleteScopeResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/DeleteScope",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDeleteScopeInterceptors() ?? []
    )
  }

  /// WriteSession adds or updates a session context.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteSession.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeSession(
    _ request: Provenance_Metadata_V1_MsgWriteSessionRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteSessionRequest, Provenance_Metadata_V1_MsgWriteSessionResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteSession",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteSessionInterceptors() ?? []
    )
  }

  /// WriteRecord adds or updates a record.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteRecord.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeRecord(
    _ request: Provenance_Metadata_V1_MsgWriteRecordRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteRecordRequest, Provenance_Metadata_V1_MsgWriteRecordResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteRecord",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteRecordInterceptors() ?? []
    )
  }

  /// DeleteRecord deletes a record.
  ///
  /// - Parameters:
  ///   - request: Request to send to DeleteRecord.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func deleteRecord(
    _ request: Provenance_Metadata_V1_MsgDeleteRecordRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteRecordRequest, Provenance_Metadata_V1_MsgDeleteRecordResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/DeleteRecord",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDeleteRecordInterceptors() ?? []
    )
  }

  /// WriteScopeSpecification adds or updates a scope specification.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteScopeSpecification.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeScopeSpecification(
    _ request: Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest, Provenance_Metadata_V1_MsgWriteScopeSpecificationResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteScopeSpecification",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteScopeSpecificationInterceptors() ?? []
    )
  }

  /// DeleteScopeSpecification deletes a scope specification.
  ///
  /// - Parameters:
  ///   - request: Request to send to DeleteScopeSpecification.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func deleteScopeSpecification(
    _ request: Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest, Provenance_Metadata_V1_MsgDeleteScopeSpecificationResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/DeleteScopeSpecification",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDeleteScopeSpecificationInterceptors() ?? []
    )
  }

  /// WriteContractSpecification adds or updates a contract specification.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteContractSpecification.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeContractSpecification(
    _ request: Provenance_Metadata_V1_MsgWriteContractSpecificationRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteContractSpecificationRequest, Provenance_Metadata_V1_MsgWriteContractSpecificationResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteContractSpecification",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteContractSpecificationInterceptors() ?? []
    )
  }

  /// DeleteContractSpecification deletes a contract specification.
  ///
  /// - Parameters:
  ///   - request: Request to send to DeleteContractSpecification.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func deleteContractSpecification(
    _ request: Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest, Provenance_Metadata_V1_MsgDeleteContractSpecificationResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/DeleteContractSpecification",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDeleteContractSpecificationInterceptors() ?? []
    )
  }

  /// WriteRecordSpecification adds or updates a record specification.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteRecordSpecification.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeRecordSpecification(
    _ request: Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest, Provenance_Metadata_V1_MsgWriteRecordSpecificationResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteRecordSpecification",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteRecordSpecificationInterceptors() ?? []
    )
  }

  /// DeleteRecordSpecification deletes a record specification.
  ///
  /// - Parameters:
  ///   - request: Request to send to DeleteRecordSpecification.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func deleteRecordSpecification(
    _ request: Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest, Provenance_Metadata_V1_MsgDeleteRecordSpecificationResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/DeleteRecordSpecification",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDeleteRecordSpecificationInterceptors() ?? []
    )
  }

  /// WriteP8eContractSpec adds a P8e v39 contract spec as a v40 ContractSpecification
  /// It only exists to help facilitate the transition. Users should transition to WriteContractSpecification.
  ///
  /// - Parameters:
  ///   - request: Request to send to WriteP8eContractSpec.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func writeP8eContractSpec(
    _ request: Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest, Provenance_Metadata_V1_MsgWriteP8eContractSpecResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/WriteP8eContractSpec",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeWriteP8eContractSpecInterceptors() ?? []
    )
  }

  /// P8EMemorializeContract records the results of a P8e contract execution as a session and set of records in a scope
  /// It only exists to help facilitate the transition. Users should transition to calling the individual Write methods.
  ///
  /// - Parameters:
  ///   - request: Request to send to P8eMemorializeContract.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func p8eMemorializeContract(
    _ request: Provenance_Metadata_V1_MsgP8eMemorializeContractRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgP8eMemorializeContractRequest, Provenance_Metadata_V1_MsgP8eMemorializeContractResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/P8eMemorializeContract",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeP8eMemorializeContractInterceptors() ?? []
    )
  }

  /// BindOSLocator binds an owner address to a uri.
  ///
  /// - Parameters:
  ///   - request: Request to send to BindOSLocator.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func bindOSLocator(
    _ request: Provenance_Metadata_V1_MsgBindOSLocatorRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgBindOSLocatorRequest, Provenance_Metadata_V1_MsgBindOSLocatorResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/BindOSLocator",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeBindOSLocatorInterceptors() ?? []
    )
  }

  /// DeleteOSLocator deletes an existing ObjectStoreLocator record.
  ///
  /// - Parameters:
  ///   - request: Request to send to DeleteOSLocator.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func deleteOSLocator(
    _ request: Provenance_Metadata_V1_MsgDeleteOSLocatorRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgDeleteOSLocatorRequest, Provenance_Metadata_V1_MsgDeleteOSLocatorResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/DeleteOSLocator",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDeleteOSLocatorInterceptors() ?? []
    )
  }

  /// ModifyOSLocator updates an ObjectStoreLocator record by the current owner.
  ///
  /// - Parameters:
  ///   - request: Request to send to ModifyOSLocator.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func modifyOSLocator(
    _ request: Provenance_Metadata_V1_MsgModifyOSLocatorRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Provenance_Metadata_V1_MsgModifyOSLocatorRequest, Provenance_Metadata_V1_MsgModifyOSLocatorResponse> {
    return self.makeUnaryCall(
      path: "/provenance.metadata.v1.Msg/ModifyOSLocator",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeModifyOSLocatorInterceptors() ?? []
    )
  }
}

internal protocol Provenance_Metadata_V1_MsgClientInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when invoking 'writeScope'.
  func makeWriteScopeInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteScopeRequest, Provenance_Metadata_V1_MsgWriteScopeResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteScope'.
  func makeDeleteScopeInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgDeleteScopeRequest, Provenance_Metadata_V1_MsgDeleteScopeResponse>]

  /// - Returns: Interceptors to use when invoking 'writeSession'.
  func makeWriteSessionInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteSessionRequest, Provenance_Metadata_V1_MsgWriteSessionResponse>]

  /// - Returns: Interceptors to use when invoking 'writeRecord'.
  func makeWriteRecordInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteRecordRequest, Provenance_Metadata_V1_MsgWriteRecordResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteRecord'.
  func makeDeleteRecordInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgDeleteRecordRequest, Provenance_Metadata_V1_MsgDeleteRecordResponse>]

  /// - Returns: Interceptors to use when invoking 'writeScopeSpecification'.
  func makeWriteScopeSpecificationInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteScopeSpecificationRequest, Provenance_Metadata_V1_MsgWriteScopeSpecificationResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteScopeSpecification'.
  func makeDeleteScopeSpecificationInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgDeleteScopeSpecificationRequest, Provenance_Metadata_V1_MsgDeleteScopeSpecificationResponse>]

  /// - Returns: Interceptors to use when invoking 'writeContractSpecification'.
  func makeWriteContractSpecificationInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteContractSpecificationRequest, Provenance_Metadata_V1_MsgWriteContractSpecificationResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteContractSpecification'.
  func makeDeleteContractSpecificationInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgDeleteContractSpecificationRequest, Provenance_Metadata_V1_MsgDeleteContractSpecificationResponse>]

  /// - Returns: Interceptors to use when invoking 'writeRecordSpecification'.
  func makeWriteRecordSpecificationInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteRecordSpecificationRequest, Provenance_Metadata_V1_MsgWriteRecordSpecificationResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteRecordSpecification'.
  func makeDeleteRecordSpecificationInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgDeleteRecordSpecificationRequest, Provenance_Metadata_V1_MsgDeleteRecordSpecificationResponse>]

  /// - Returns: Interceptors to use when invoking 'writeP8eContractSpec'.
  func makeWriteP8eContractSpecInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgWriteP8eContractSpecRequest, Provenance_Metadata_V1_MsgWriteP8eContractSpecResponse>]

  /// - Returns: Interceptors to use when invoking 'p8eMemorializeContract'.
  func makeP8eMemorializeContractInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgP8eMemorializeContractRequest, Provenance_Metadata_V1_MsgP8eMemorializeContractResponse>]

  /// - Returns: Interceptors to use when invoking 'bindOSLocator'.
  func makeBindOSLocatorInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgBindOSLocatorRequest, Provenance_Metadata_V1_MsgBindOSLocatorResponse>]

  /// - Returns: Interceptors to use when invoking 'deleteOSLocator'.
  func makeDeleteOSLocatorInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgDeleteOSLocatorRequest, Provenance_Metadata_V1_MsgDeleteOSLocatorResponse>]

  /// - Returns: Interceptors to use when invoking 'modifyOSLocator'.
  func makeModifyOSLocatorInterceptors() -> [ClientInterceptor<Provenance_Metadata_V1_MsgModifyOSLocatorRequest, Provenance_Metadata_V1_MsgModifyOSLocatorResponse>]
}

internal final class Provenance_Metadata_V1_MsgClient: Provenance_Metadata_V1_MsgClientProtocol {
  internal let channel: GRPCChannel
  internal var defaultCallOptions: CallOptions
  internal var interceptors: Provenance_Metadata_V1_MsgClientInterceptorFactoryProtocol?

  /// Creates a client for the provenance.metadata.v1.Msg service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  internal init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Provenance_Metadata_V1_MsgClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

