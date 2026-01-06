//
//  ZegoSignalingPluginProtocol.swift
//  Pods-ZegoUIKitSDK
//
//  Created by zego on 2022/12/15.
//

import Foundation

public protocol ZegoSignalingPluginProtocol: ZegoPluginProtocol {
    
    func initWith(appID: UInt32, appSign: String?)

    func connectUser(userID: String,
                     userName: String,
                     token: String?,
                     callback: ConnectUserCallback?)
    
    func disconnectUser()
    
    func renewToken(_ token: String, callback: RenewTokenCallback?)
    
    func sendInvitation(with invitees: [String],
                        timeout: UInt32,
                        data: String?,
                        notificationConfig: ZegoSignalingPluginNotificationConfig?,
                        callback: InvitationCallback?)
    
    func cancelInvitation(with invitees: [String],
                          invitationID: String,
                          data: String?,
                          callback: CancelInvitationCallback?)
    
    func refuseInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?)
    
    func acceptInvitation(with invitationID: String, data: String?, callback: ResponseInvitationCallback?)
    
    // MARK: - Room
    func joinRoom(with roomID: String, roomName: String?, callBack: RoomCallback?)
    
    func leaveRoom(by roomID: String, callBack: RoomCallback?)
    
    func setUsersInRoomAttributes(with attributes: [String: String],
                                  userIDs: [String],
                                  roomID: String,
                                  callback: SetUsersInRoomAttributesCallback?)
    
    func queryUsersInRoomAttributes(by roomID: String,
                                    count: UInt32,
                                    nextFlag: String,
                                    callback: QueryUsersInRoomAttributesCallback?)
    
    func updateRoomProperty(_ attributes: [String: String],
                            roomID: String,
                            isForce: Bool,
                            isDeleteAfterOwnerLeft: Bool,
                            isUpdateOwner: Bool,
                            callback: RoomPropertyOperationCallback?)
    
    func deleteRoomProperties(by keys: [String],
                              roomID: String,
                              isForce: Bool,
                              callback: RoomPropertyOperationCallback?)
    
    func beginRoomPropertiesBatchOperation(with roomID: String,
                                           isDeleteAfterOwnerLeft: Bool,
                                           isForce: Bool,
                                           isUpdateOwner: Bool)
    
    func endRoomPropertiesBatchOperation(with roomID: String,
                                         callback: EndRoomBatchOperationCallback?)
    
    func queryRoomProperties(by roomID: String, callback: QueryRoomPropertyCallback?)
    
    func sendRoomMessage(_ text: String, roomID: String, callback: SendRoomMessageCallback?)
    
    func sendRoomCommand(_ command: String, roomID: String, callback: SendRoomMessageCallback?)
    
    func enableNotifyWhenAppRunningInBackgroundOrQuit(_ enable: Bool,
                                                      isSandboxEnvironment: Bool,
                                                      certificateIndex: ZegoSignalingPluginMultiCertificate)
    
    func setRemoteNotificationsDeviceToken(_ deviceToken: Data)
    
    func registerPluginEventHandler(_ delegate: ZegoSignalingPluginEventHandler)
    
    // MARK: for AppleCallKit
    func setVoipToken(_ token: Data, isSandboxEnvironment: Bool)
    
}

@objc public protocol ZegoSignalingPluginEventHandler: AnyObject {
    func onConnectionStateChanged(_ state: ZegoSignalingPluginConnectionState)
  
    func onIMRoomStateChanged(_ state:Int,
                              event:Int,
                              roomID:String)
  
    func onTokenWillExpire(in second: UInt32)
    
    // MARK: - Invitation
    func onCallInvitationReceived(_ callID: String,
                                  inviterID: String,
                                  data: String)
    
    func onCallInvitationCancelled(_ callID: String,
                                  inviterID: String,
                                  data: String)
    
    func onCallInvitationAccepted(_ callID: String,
                                  inviteeID: String,
                                  data: String)
    
    func onCallInvitationRejected(_ callID: String,
                                  inviteeID: String,
                                  data: String)
    
    func onCallInvitationTimeout(_ callID: String)
    
    func onCallInviteesAnsweredTimeout(_ callID: String, invitees: [String])
    
    // MARK: - Room
    func onUsersInRoomAttributesUpdated(_ attributesMap: [String: [String: String]],
                                            editor: String,
                                            roomID: String)
    
    // action: 0 - set, 1 - delete
    func onRoomPropertiesUpdated(_ setProperties: [[String: String]],
                                     deleteProperties: [[String: String]],
                                     roomID: String)
    
    func onRoomMemberLeft(_ userIDList: [String], roomID: String)
    
    func onRoomMemberJoined(_ userIDList: [String], roomID: String)
    
    func onInRoomTextMessageReceived(_ messages: [ZegoSignalingInRoomTextMessage],
                                         roomID: String)
    func onInRoomCommandMessageReceived(_ messages: [ZegoSignalingInRoomCommandMessage],
                                         roomID: String)
    
    
}

public protocol ZegoCallPluginProtocol: ZegoPluginProtocol {
  
  func initWith(appID: UInt32, appSign: String, userID: String, userName: String, callPluginConfig: ZegoCallPluginConfig)

  func initWith(appID: UInt32, appSign: String, userID: String, userName: String)

  func unInit()

  func logoutUser()

  func sendInvitationWithUIChange( invitees:[ZegoPluginCallUser],
                                   invitationType: ZegoPluginCallType,
                                   customData: String,
                                   timeout: Int,
                                   notificationConfig: ZegoSignalingPluginNotificationConfig,
                                   source:String,
                                   callback: ZegoPluginCallback?)
  
  func registerCallKitDelegate(delegate: AnyObject)
  
}
