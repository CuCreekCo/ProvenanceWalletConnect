//
// DO NOT EDIT.
//
// Generated by the protocol buffer compiler.
// Source: cosmos/vesting/v1beta1/tx.proto
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


/// Msg defines the bank Msg service.
///
/// Usage: instantiate `Cosmos_Vesting_V1beta1_MsgClient`, then call methods of this protocol to make API calls.
internal protocol Cosmos_Vesting_V1beta1_MsgClientProtocol: GRPCClient {
  var serviceName: String { get }
  var interceptors: Cosmos_Vesting_V1beta1_MsgClientInterceptorFactoryProtocol? { get }

  func createVestingAccount(
    _ request: Cosmos_Vesting_V1beta1_MsgCreateVestingAccount,
    callOptions: CallOptions?
  ) -> UnaryCall<Cosmos_Vesting_V1beta1_MsgCreateVestingAccount, Cosmos_Vesting_V1beta1_MsgCreateVestingAccountResponse>
}

extension Cosmos_Vesting_V1beta1_MsgClientProtocol {
  internal var serviceName: String {
    return "cosmos.vesting.v1beta1.Msg"
  }

  /// CreateVestingAccount defines a method that enables creating a vesting
  /// account.
  ///
  /// - Parameters:
  ///   - request: Request to send to CreateVestingAccount.
  ///   - callOptions: Call options.
  /// - Returns: A `UnaryCall` with futures for the metadata, status and response.
  internal func createVestingAccount(
    _ request: Cosmos_Vesting_V1beta1_MsgCreateVestingAccount,
    callOptions: CallOptions? = nil
  ) -> UnaryCall<Cosmos_Vesting_V1beta1_MsgCreateVestingAccount, Cosmos_Vesting_V1beta1_MsgCreateVestingAccountResponse> {
    return self.makeUnaryCall(
      path: "/cosmos.vesting.v1beta1.Msg/CreateVestingAccount",
      request: request,
      callOptions: callOptions ?? self.defaultCallOptions,
      interceptors: self.interceptors?.makeCreateVestingAccountInterceptors() ?? []
    )
  }
}

internal protocol Cosmos_Vesting_V1beta1_MsgClientInterceptorFactoryProtocol {

  /// - Returns: Interceptors to use when invoking 'createVestingAccount'.
  func makeCreateVestingAccountInterceptors() -> [ClientInterceptor<Cosmos_Vesting_V1beta1_MsgCreateVestingAccount, Cosmos_Vesting_V1beta1_MsgCreateVestingAccountResponse>]
}

internal final class Cosmos_Vesting_V1beta1_MsgClient: Cosmos_Vesting_V1beta1_MsgClientProtocol {
  internal let channel: GRPCChannel
  internal var defaultCallOptions: CallOptions
  internal var interceptors: Cosmos_Vesting_V1beta1_MsgClientInterceptorFactoryProtocol?

  /// Creates a client for the cosmos.vesting.v1beta1.Msg service.
  ///
  /// - Parameters:
  ///   - channel: `GRPCChannel` to the service host.
  ///   - defaultCallOptions: Options to use for each service call if the user doesn't provide them.
  ///   - interceptors: A factory providing interceptors for each RPC.
  internal init(
    channel: GRPCChannel,
    defaultCallOptions: CallOptions = CallOptions(),
    interceptors: Cosmos_Vesting_V1beta1_MsgClientInterceptorFactoryProtocol? = nil
  ) {
    self.channel = channel
    self.defaultCallOptions = defaultCallOptions
    self.interceptors = interceptors
  }
}

