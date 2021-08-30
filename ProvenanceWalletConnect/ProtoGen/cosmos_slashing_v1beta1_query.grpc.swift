//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: cosmos/slashing/v1beta1/query.proto
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


/// Query provides defines the gRPC querier service
///
/// Usage: instantiate `Cosmos_Slashing_V1beta1_QueryClient`, then call methods of this protocol to make API calls.
internal protocol Cosmos_Slashing_V1beta1_QueryClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Cosmos_Slashing_V1beta1_QueryClientInterceptorFactoryProtocol? { get }

  func params(
    _ request: Cosmos_Slashing_V1beta1_QueryParamsRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Cosmos_Slashing_V1beta1_QueryParamsRequest, Cosmos_Slashing_V1beta1_QueryParamsResponse>

  func signingInfo(
    _ request: Cosmos_Slashing_V1beta1_QuerySigningInfoRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Cosmos_Slashing_V1beta1_QuerySigningInfoRequest, Cosmos_Slashing_V1beta1_QuerySigningInfoResponse>

  func signingInfos(
    _ request: Cosmos_Slashing_V1beta1_QuerySigningInfosRequest,
    callOptions: CallOptions?
  ) -> UnaryCall<Cosmos_Slashing_V1beta1_QuerySigningInfosRequest, Cosmos_Slashing_V1beta1_QuerySigningInfosResponse>
}

extension Cosmos_Slashing_V1beta1_QueryClientProtocol {
  internal var serviceName: String {
    return "cosmos.slashing.v1beta1.Query"
  }

  /// Params queries the parameters of slashing module
  ///
  /// - Parameters:
  ///   - request: Request to send to Params.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func params(
    _ request: Cosmos_Slashing_V1beta1_QueryParamsRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Cosmos_Slashing_V1beta1_QueryParamsRequest, Cosmos_Slashing_V1beta1_QueryParamsResponse> {
    return self.makeUnaryCall(
      path: "/cosmos.slashing.v1beta1.Query/Params",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeParamsInterceptors() ?? []
    )
  }

  /// SigningInfo queries the signing info of given cons address
  ///
  /// - Parameters:
  ///   - request: Request to send to SigningInfo.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func signingInfo(
    _ request: Cosmos_Slashing_V1beta1_QuerySigningInfoRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Cosmos_Slashing_V1beta1_QuerySigningInfoRequest, Cosmos_Slashing_V1beta1_QuerySigningInfoResponse> {
    return self.makeUnaryCall(
      path: "/cosmos.slashing.v1beta1.Query/SigningInfo",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeSigningInfoInterceptors() ?? []
    )
  }

  /// SigningInfos queries signing info of all validators
  ///
  /// - Parameters:
  ///   - request: Request to send to SigningInfos.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func signingInfos(
    _ request: Cosmos_Slashing_V1beta1_QuerySigningInfosRequest,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Cosmos_Slashing_V1beta1_QuerySigningInfosRequest, Cosmos_Slashing_V1beta1_QuerySigningInfosResponse> {
    return self.makeUnaryCall(
      path: "/cosmos.slashing.v1beta1.Query/SigningInfos",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeSigningInfosInterceptors() ?? []
    )
  }
}

internal protocol Cosmos_Slashing_V1beta1_QueryClientInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when invoking 'params'.
  func makeParamsInterceptors() -> [ClientInterceptor<Cosmos_Slashing_V1beta1_QueryParamsRequest, Cosmos_Slashing_V1beta1_QueryParamsResponse>]

  /// - Returns: Interceptors to use when invoking 'signingInfo'.
  func makeSigningInfoInterceptors() -> [ClientInterceptor<Cosmos_Slashing_V1beta1_QuerySigningInfoRequest, Cosmos_Slashing_V1beta1_QuerySigningInfoResponse>]

  /// - Returns: Interceptors to use when invoking 'signingInfos'.
  func makeSigningInfosInterceptors() -> [ClientInterceptor<Cosmos_Slashing_V1beta1_QuerySigningInfosRequest, Cosmos_Slashing_V1beta1_QuerySigningInfosResponse>]
}

internal final class Cosmos_Slashing_V1beta1_QueryClient: Cosmos_Slashing_V1beta1_QueryClientProtocol {
  internal let channel: GRPCChannel
  internal var defaultCallOptions: CallOptions
  internal var interceptors: Cosmos_Slashing_V1beta1_QueryClientInterceptorFactoryProtocol?

  /// Creates a client for the cosmos.slashing.v1beta1.Query service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  internal init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Cosmos_Slashing_V1beta1_QueryClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

