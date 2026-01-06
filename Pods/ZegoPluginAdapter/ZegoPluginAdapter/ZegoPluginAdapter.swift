//
//  ZegoPluginAdapter.swift
//  Pods-ZegoUIKitSDK
//
//  Created by zego on 2022/12/15.
//

import UIKit

public class ZegoPluginAdapter {
    public static let shared = ZegoPluginAdapter()
    
    private var plugins = [ZegoPluginType: ZegoPluginProtocol]()
    
    public static func installPlugins(_ plugins: [ZegoPluginProtocol]) {
            for plugin in plugins {
                ZegoPluginAdapter.shared.plugins[plugin.pluginType] = plugin
            }
        }
        
    public static var signalingPlugin: ZegoSignalingPluginProtocol? {
        return getPlugin(.signaling) as? ZegoSignalingPluginProtocol
    }

    public static var callkitPlugin: ZegoCallKitPluginProtocol? {
        return getPlugin(.callkit) as? ZegoCallKitPluginProtocol
    }
  
    public static var callPlugin: ZegoCallPluginProtocol? {
        return getPlugin(.call) as? ZegoCallPluginProtocol
    }
    
    private static func getPlugin(_ type: ZegoPluginType) -> ZegoPluginProtocol? {
        // get plugin from ZegoPluginAdapter
        if let plugin = ZegoPluginAdapter.shared.plugins[type] {
            return plugin
        }
        
        // get plugin from PluginProvider
        let provider = getPluginProvider(with: type)
        guard let plugin = provider?.getPlugin() else {
            return nil
        }
        // install plugin into ZegoPluginAdapter
        // and will get plugin from ZegoPluginAdapter next time.
        ZegoPluginAdapter.installPlugins([plugin])
        return plugin
    }
    
    private static func getPluginProvider(with type: ZegoPluginType) -> ZegoPluginProvider? {
        switch type {
        case .signaling:
            return ZegoSignalingProvider() as? ZegoPluginProvider
        case .callkit:
            return ZegoCallKitProvider() as? ZegoPluginProvider
        case .call:
            return ZegoUIKitPrebuiteCallProvider() as? ZegoPluginProvider
        }
      
    }
}
