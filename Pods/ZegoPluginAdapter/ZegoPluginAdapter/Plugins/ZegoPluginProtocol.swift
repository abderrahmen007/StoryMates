//
//  ZegoPluginProtocol.swift
//  Pods-ZegoUIKitSDK
//
//  Created by zego on 2022/12/15.
//

import Foundation

public protocol ZegoPluginProtocol {
    var pluginType: ZegoPluginType { get }
    var version: String { get }
}
