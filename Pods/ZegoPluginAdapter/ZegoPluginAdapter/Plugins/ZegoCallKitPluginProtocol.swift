//
//  ZegoSignalingPluginProtocol.swift
//  Pods-ZegoUIKitSDK
//
//  Created by zego on 2022/12/15.
//

import Foundation

public protocol ZegoCallKitPluginProtocol: ZegoPluginProtocol {
    
    
    // MARK: CallKit
    
    // 开启 voip, 并传入环境
    func enableVoIP(isSandboxEnvironment: Bool)

    // 注册 CallKit 的回调
    func registerPluginEventHandler(_ delegate: ZegoCallKitPluginEventHandler)
    
    func reportIncomingCall(with uuid: UUID, title: String, hasVideo: Bool, identifier: String)

    func reportCallEnded(with uuid: UUID, reason: Int)
    
    
    func endCall(with uuid: UUID)
    
    func endAllCalls()
}

@objc public protocol ZegoCallKitPluginEventHandler: AnyObject {

    // MARK: CallKit
    func didReceiveIncomingPush(_ uuid: UUID, invitationID: String, data: String)
    
    func onCallKitStartCall(_ action: CallKitAction)
    
    func onCallKitAnswerCall(_ action: CallKitAction)
    
    func onCallKitEndCall(_ action: CallKitAction)
    
    func onCallKitSetHeldCall(_ action: CallKitAction)
    
    func onCallKitSetMutedCall(_ action: CallKitAction)
    
    func onCallKitSetGroupCall(_ action: CallKitAction)
    
    func onCallKitPlayDTMFCall(_ action: CallKitAction)
    
    func onCallKitTimeOutPerforming(_ action: CallKitAction)
}
