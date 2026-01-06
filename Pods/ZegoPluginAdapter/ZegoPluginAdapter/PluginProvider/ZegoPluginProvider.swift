//
//  ZegoPluginProvider.swift
//  Pods-ZegoUIKitSDK
//
//  Created by zego on 2022/12/15.
//

import Foundation

public protocol ZegoPluginProvider {
    func getPlugin() -> ZegoPluginProtocol?
}

public struct ZegoSignalingProvider {

}

public struct ZegoCallKitProvider {

}

public struct ZegoUIKitPrebuiteCallProvider {

}
