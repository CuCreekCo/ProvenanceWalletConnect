//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: ibc/applications/transfer/v1/query.proto
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


/// Query provides defines the gRPC querier service.
///
/// Usage: instantiate `Ibc_Applications_Transfer_V1_QueryClient`, then call methods of this protocol to make API calls.
internal protocol Ibc_Applications_Transfer_V1_QueryClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Ibc_Applications_Transfer_V1_QueryClientInterceptorFactoryProtocol? { get }

  func denomTrace(
    _ request: Ibc_Applications_Transfer_V1_QueryDenomTraceRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Ibc_Applications_Transfer_V1_QueryDenomTraceRequest, Ibc_Applications_Transfer_V1_QueryDenomTraceResponse>

  func denomTraces(
    _ request: Ibc_Applications_Transfer_V1_QueryDenomTracesRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Ibc_Applications_Transfer_V1_QueryDenomTracesRequest, Ibc_Applications_Transfer_V1_QueryDenomTracesResponse>

  func params(
    _ request: Ibc_Applications_Transfer_V1_QueryParamsRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Ibc_Applications_Transfer_V1_QueryParamsRequest, Ibc_Applications_Transfer_V1_QueryParamsResponse>
}

extension Ibc_Applications_Transfer_V1_QueryClientProtocol {
  internal var serviceName: String {
    return "ibc.applications.transfer.v1.Query"
  }

  /// DenomTrace queries a denomination trace information.
  ///
  /// - Parameters:
  ///   - request: Request to send to DenomTrace.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func denomTrace(
    _ request: Ibc_Applications_Transfer_V1_QueryDenomTraceRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Ibc_Applications_Transfer_V1_QueryDenomTraceRequest, Ibc_Applications_Transfer_V1_QueryDenomTraceResponse> {
    return self.makeUnaryCall(
      path: "/ibc.applications.transfer.v1.Query/DenomTrace",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDenomTraceInterceptors() ?? []
    )
  }

  /// DenomTraces queries all denomination traces.
  ///
  /// - Parameters:
  ///   - request: Request to send to DenomTraces.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func denomTraces(
    _ request: Ibc_Applications_Transfer_V1_QueryDenomTracesRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Ibc_Applications_Transfer_V1_QueryDenomTracesRequest, Ibc_Applications_Transfer_V1_QueryDenomTracesResponse> {
    return self.makeUnaryCall(
      path: "/ibc.applications.transfer.v1.Query/DenomTraces",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeDenomTracesInterceptors() ?? []
    )
  }

  /// Params queries all parameters of the ibc-transfer module.
  ///
  /// - Parameters:
  ///   - request: Request to send to Params.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func params(
    _ request: Ibc_Applications_Transfer_V1_QueryParamsRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Ibc_Applications_Transfer_V1_QueryParamsRequest, Ibc_Applications_Transfer_V1_QueryParamsResponse> {
    return self.makeUnaryCall(
      path: "/ibc.applications.transfer.v1.Query/Params",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeParamsInterceptors() ?? []
    )
  }
}

internal protocol Ibc_Applications_Transfer_V1_QueryClientInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when invoking 'denomTrace'.
  func makeDenomTraceInterceptors() -> [ClientInterceptor<Ibc_Applications_Transfer_V1_QueryDenomTraceRequest, Ibc_Applications_Transfer_V1_QueryDenomTraceResponse>]

  /// - Returns: Interceptors to use when invoking 'denomTraces'.
  func makeDenomTracesInterceptors() -> [ClientInterceptor<Ibc_Applications_Transfer_V1_QueryDenomTracesRequest, Ibc_Applications_Transfer_V1_QueryDenomTracesResponse>]

  /// - Returns: Interceptors to use when invoking 'params'.
  func makeParamsInterceptors() -> [ClientInterceptor<Ibc_Applications_Transfer_V1_QueryParamsRequest, Ibc_Applications_Transfer_V1_QueryParamsResponse>]
}

internal final class Ibc_Applications_Transfer_V1_QueryClient: Ibc_Applications_Transfer_V1_QueryClientProtocol {
  internal let channel: GRPCChannel
  internal var defaultCallOptions: CallOptions
  internal var interceptors: Ibc_Applications_Transfer_V1_QueryClientInterceptorFactoryProtocol?

  /// Creates a client for the ibc.applications.transfer.v1.Query service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  internal init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Ibc_Applications_Transfer_V1_QueryClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

