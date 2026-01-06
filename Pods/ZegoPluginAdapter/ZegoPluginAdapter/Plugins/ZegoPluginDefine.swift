//
//  ZegoPluginDefine.swift
//  Pods-ZegoUIKitSDK
//
//  Created by zego on 2022/12/15.
//

import Foundation

public typealias ConnectUserCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

public typealias RenewTokenCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

public typealias InvitationCallback = (_ errorCode: UInt,
                                       _ errorMessage: String,
                                       _ invitationID: String,
                                       _ errorInvitees: [String]) -> ()

public typealias CancelInvitationCallback = (_ errorCode: UInt,
                                             _ errorMessage: String,
                                             _ errorInvitees: [String]) -> ()

public typealias ResponseInvitationCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

public typealias RoomCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

// errorKeysMap, userID: errorKeys
public typealias SetUsersInRoomAttributesCallback = (_ errorCode: UInt,
                                                     _ errorMessage: String,
                                                     _ errorUserList: [String],
                                                     _ attributesMap: [String: [String: String]],
                                                     _ errorKeysMap: [String: [String]]) -> ()

// attributesMap, userID: attributes
public typealias QueryUsersInRoomAttributesCallback = (_ errorCode: UInt,
                                                       _ errorMessage: String,
                                                       _ nextFlag: String,
                                                       _ attributesMap: [String: [String: String]]) -> ()

public typealias RoomPropertyOperationCallback = (_ errorCode: UInt,
                                                  _ errorMessage: String,
                                                  _ errorKeys: [String]) -> ()

public typealias EndRoomBatchOperationCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()


public typealias QueryRoomPropertyCallback = (_ errorCode: UInt,
                                              _ errorMessage: String,
                                              _ properties: [String: String]) -> ()

public typealias SendRoomMessageCallback = (_ errorCode: UInt, _ errorMessage: String) -> ()

public typealias ZegoPluginCallback = (_ data: Dictionary<String, AnyObject>?) -> ()


public enum ZegoPluginType: Int {
    case signaling
    case callkit
    case call
}

@objc public enum ZegoSignalingPluginConnectionState: UInt {
    case disconnected
    case connecting
    case connected
    case reconnecting
}


@objc public enum ZegoPluginCallType: Int {
  case voiceCall = 0
  case videoCall = 1
}

public class ZegoSignalingInRoomTextMessage: NSObject {
    public var messageID: Int64 = 0
    public var timestamp: UInt64 = 0
    public var orderKey: Int64 = 0
    public var senderUserID: String = ""
    public var text: String = ""
    
    public init(messageID: Int64,
                timestamp: UInt64,
                orderKey: Int64,
                senderUserID: String,
                text: String) {
        self.messageID = messageID
        self.timestamp = timestamp
        self.orderKey = orderKey
        self.senderUserID = senderUserID
        self.text = text
    }
}

@objc public class ZegoPluginCallUser: NSObject {
    
  @objc public var userID: String = ""
  @objc public var userName: String = ""
  @objc public var avatar: String = ""
    
  @objc public init(userID: String,
                userName: String,
                    avatar: String? = nil) {
        self.userID = userID
        self.userName = userName
        self.avatar = avatar ?? ""
    }
}

@objc public class ZegoCallPluginConfig : NSObject {
    @objc public var invitationConfig: AnyObject
    @objc public var resourceID: String = ""
    
    @objc public init(invitationConfig: AnyObject,
                resourceID: String) {
        self.invitationConfig = invitationConfig
        self.resourceID = resourceID
    }
}

public class ZegoSignalingInRoomCommandMessage: NSObject {
    public var messageID: Int64 = 0
    public var timestamp: UInt64 = 0
    public var orderKey: Int64 = 0
    public var senderUserID: String = ""
    public var command: String = ""
    
    public init(messageID: Int64,
                timestamp: UInt64,
                orderKey: Int64,
                senderUserID: String,
                command: String) {
        self.messageID = messageID
        self.timestamp = timestamp
        self.orderKey = orderKey
        self.senderUserID = senderUserID
        self.command = command
    }
}

@objcMembers
public class ZegoSignalingPluginNotificationConfig: NSObject {
    public let resourceID: String
    public var title: String
    public var message: String
    
    public init(resourceID: String, title: String? = nil, message: String? = nil) {
        self.resourceID = resourceID
        self.title = title ?? ""
        self.message = message ?? ""
    }
}

@objc public enum ZegoSignalingPluginMultiCertificate: UInt32 {
    case firstCertificate = 1
    case secondCertificate = 2
}

public class CallKitAction: NSObject {
    
    public let fulfillAction: () -> ()
    public let failAction: () -> ()
    
    public init(_ fulfillAction: @escaping () -> (), failAction: @escaping () -> ()) {
        self.fulfillAction = fulfillAction
        self.failAction = failAction
    }
    
    /// Report successful execution of the receiver.
    public func fulfill() {
        fulfillAction()
    }
    
    /// Report failed execution of the receiver.
    public func fail() {
        failAction()
    }
}
