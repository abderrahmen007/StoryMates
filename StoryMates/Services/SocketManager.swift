//
//  SocketManager.swift
//  StoryMates
//
//  Created by mac on 12/08/25.
//

import Foundation
import SocketIO
import Combine

class WebSocketService: ObservableObject {
    static let shared = WebSocketService()
    
    // Explicitly use SocketIO.SocketManager to avoid ambiguity
    private var manager: SocketIO.SocketManager?
    private var socket: SocketIOClient?
    
    // Publish received notifications
    // Using [String: Any] to match JSON dictionary
    let notificationSubject = PassthroughSubject<[String: Any], Never>()
    
    private init() {}
    
    func connect(userId: String) {
        // Ensure URL matches backend configuration
        // Using "http://localhost:3001" or IP if testing on device
        // Adjust IP as needed matching NetworkManager
        // For Simulator, use localhost. If real device, use local IP.
        guard let url = URL(string: "http://172.18.12.187:3001") else { return }
        
        manager = SocketIO.SocketManager(socketURL: url, config: [
            .log(true),
            .compress,
            .path("/socket.io"), // Standard Socket.IO path
            .forceWebsockets(true),
            .connectParams(["EIO": "3"]) // Ensure compatibility if needed
        ])
        
        // Namespace must match backend: /notifications
        socket = manager?.socket(forNamespace: "/notifications")
        
        setupHandlers(userId: userId)
        socket?.connect()
    }
    
    private func setupHandlers(userId: String) {
        socket?.on(clientEvent: .connect) { [weak self] data, ack in
            print("✅ [WebSocketService] Connected")
            // Join room matching backend logic
            self?.socket?.emit("joinNotificationRoom", userId)
        }
        
        socket?.on(clientEvent: .error) { data, ack in
            print("❌ [WebSocketService] Error: \(data)")
        }
        
        socket?.on("newNotification") { [weak self] data, ack in
            print("🔔 [WebSocketService] Notification received: \(data)")
            if let notificationData = data.first as? [String: Any] {
                DispatchQueue.main.async {
                    self?.notificationSubject.send(notificationData)
                }
            }
        }
    }
    
    func disconnect() {
        socket?.disconnect()
    }
}
