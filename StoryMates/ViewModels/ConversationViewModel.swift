//
//  ConversationViewModel.swift
//  StoryMates
//
//  Created by Mac Mini 10 on 23/11/2025.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class ConversationViewModel: ObservableObject {
    
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message]         = []
    @Published var selectedConversation: Conversation?
    @Published var messageInput: String        = ""
    @Published var error: String?              = nil
    
    @Published var isAddingNewConversation      = false
    @Published var newConversationTitleInput   = ""
    @Published var isEditingMode: Bool = false
    @Published var editingMessageId: String? = nil
    private let repo = AiConversationRepository.shared
    
    // MARK: - Logging util
    private func log(_ msg: String) {
        print("🟩 [ViewModel] \(msg)")
    }
    
    
    
    // ===============================================================
    // MARK: - Load conversations
    // ===============================================================
    
    func loadConversations(userId: String) {
        log("📌 loadConversations() called → userId=\(userId)")
        error = nil
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ loadConversations(): Missing access token")
                    error = "No access token. Please login again."
                    return
                }
                
                log("➡️ Calling repo.getConversations() ...")
                let list = try await repo.getConversations(userId: userId, token: token)
                
                log("✅ Loaded \(list.count) conversations")
                
                conversations = list
                
                // Auto-select newest conversation
                selectedConversation = list.max(by: { $0.id < $1.id })
                
                if let c = selectedConversation {
                    log("📌 Auto-selected conversation id=\(c.id)")
                    loadMessages(conversationId: c.id, userId: userId)
                } else {
                    log("⚠️ No conversations to auto-select")
                }
                
            } catch {
                log("❌ loadConversations() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    
    
    // ===============================================================
    // MARK: - Select conversation
    // ===============================================================
    
    func selectConversation(_ c: Conversation, userId: String) {
        log("📌 selectConversation() → id=\(c.id)")
        selectedConversation = c
        loadMessages(conversationId: c.id, userId: userId)
    }
    
    
    // ===============================================================
    // MARK: - Load messages
    // ===============================================================
    
    func loadMessages(conversationId: String, userId: String) {
        log("📌 loadMessages() → convId=\(conversationId), userId=\(userId)")
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ loadMessages(): Missing access token")
                    return
                }
                
                log("➡️ Calling repo.getMessages() ...")
                let msgs = try await repo.getMessages(
                    conversationId: conversationId,
                    userId: userId,
                    token: token
                )
                
                log("✅ Loaded \(msgs.count) messages for conv \(conversationId)")
                messages = msgs
                
            } catch {
                log("❌ loadMessages() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    
    
    // ===============================================================
    // MARK: - Send Message
    // ===============================================================
    
    func sendMessage(userId: String) {
        log("📌 sendMessage() called")
        
        guard let conv = selectedConversation else {
            log("❌ sendMessage(): No selected conversation")
            return
        }
        
        let content = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        log("✏️ Message input: '\(content)'")
        
        if content.isEmpty {
            log("❌ sendMessage(): Message is empty")
            return
        }
        
        // Temporary UI message
        let temp = Message(
            id: "pending-\(UUID().uuidString)",
            conversationId: conv.id,
            sender: "user",
            content: content,
            timestamp: String(Date().timeIntervalSince1970)
        )
        
        log("📌 Appending temporary message id=\(temp.id)")
        messages.append(temp)
        messageInput = ""
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ sendMessage(): Missing token")
                    return
                }
                
                log("➡️ Sending message to server ...")
                
                let real = try await repo.createMessage(
                    conversationId: conv.id,
                    dto: CreateMessageDto(userId: userId, content: content),
                    token: token
                )
                
                log("✅ Server returned real message id=\(real.id)")
                
                // Replace temporary message
                if let idx = messages.firstIndex(where: { $0.id == temp.id }) {
                    messages[idx] = real
                    log("🔄 Replaced temporary message with real one")
                }
                
                loadMessages(conversationId: conv.id, userId: userId)
                
            } catch {
                log("❌ sendMessage() failed: \(error.localizedDescription)")
                
                // Remove temp msg
                messages.removeAll { $0.id == temp.id }
                self.error = error.localizedDescription
            }
        }
    }
    
    
    
    func sendOrEditMessage(userId: String) {
        let content = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        log("📌 sendOrEditMessage() called → content: '\(content)'")
        
        guard !content.isEmpty else {
            log("❌ Message is empty")
            return
        }
        
        guard let conv = selectedConversation else {
            log("❌ No selected conversation")
            return
        }
        
        if isEditingMode, let msgId = editingMessageId {
            // ===== Edit mode =====
            log("✏️ Editing message id=\(msgId)")
            Task {
                do {
                    guard let token = AuthManager.shared.accessToken else {
                        log("❌ Missing token")
                        return
                    }
                    
                    let updated = try await repo.editMessage(
                        messageId: msgId,
                        newText: content,
                        token: token
                    )
                    
                    if let idx = messages.firstIndex(where: { $0.id == msgId }) {
                        messages[idx] = updated
                        log("✅ Message updated in UI")
                    }
                    
                    // Reset editing mode
                    editingMessageId = nil
                    isEditingMode = false
                    messageInput = ""
                    
                } catch {
                    log("❌ editMessage() failed: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                }
            }
            
        } else {
            // ===== New message mode =====
            log("✏️ Sending new message")
            
            let temp = Message(
                id: "pending-\(UUID().uuidString)",
                conversationId: conv.id,
                sender: "user",
                content: content,
                timestamp: String(Date().timeIntervalSince1970)
            )
            
            messages.append(temp)
            messageInput = ""
            
            Task {
                do {
                    guard let token = AuthManager.shared.accessToken else {
                        log("❌ Missing token")
                        return
                    }
                    
                    let real = try await repo.createMessage(
                        conversationId: conv.id,
                        dto: CreateMessageDto(userId: userId, content: content),
                        token: token
                    )
                    
                    if let idx = messages.firstIndex(where: { $0.id == temp.id }) {
                        messages[idx] = real
                        log("🔄 Replaced temporary message with real one")
                    }
                    
                    loadMessages(conversationId: conv.id, userId: userId)
                    
                } catch {
                    log("❌ sendMessage() failed: \(error.localizedDescription)")
                    messages.removeAll { $0.id == temp.id }
                    self.error = error.localizedDescription
                }
            }
        }
    }

    
    // ===============================================================
    // MARK: - New Conversation
    // ===============================================================
    
    func createNewConversation(title: String = "New Conversation", userId: String) {
        log("📌 createNewConversation() → title='\(title)', userId=\(userId)")
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ createNewConversation(): Missing token")
                    return
                }
                
                let dto = CreateConversationDto(title: title, userId: userId)
                log("➡️ Calling repo.createConversation() ...")
                
                let newConv = try await repo.createConversation(dto: dto, token: token)
                log("✅ Created new conversation id=\(newConv.id)")
                
                conversations.append(newConv)
                selectedConversation = newConv
                
                isAddingNewConversation = false
                
            } catch {
                log("❌ createNewConversation() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
                isAddingNewConversation = false
            }
        }
    }
    
    
    // ===============================================================
    // MARK: - Edit Message
    // ===============================================================
    
    func editMessage(messageId: String, newText: String, userId: String) {
        log("📌 editMessage() → msgId=\(messageId), newText='\(newText)'")
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ editMessage(): Missing token")
                    return
                }
                
                log("➡️ Calling repo.editMessage() ...")
                let updated = try await repo.editMessage(
                    messageId: messageId,
                    newText: newText,
                    token: token
                )
                
                if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[idx] = updated
                    log("✅ Message updated in UI")
                }
                
            } catch {
                log("❌ editMessage() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    
    
    
    
    
    // ===============================================================
    // MARK: - Delete Message
    // ===============================================================
    
    func deleteMessage(conversationId:String , messageId: String, userId: String) {
        log("📌 deleteMessage() → msgId=\(messageId)")
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ deleteMessage(): Missing token")
                    return
                }
                
                log("➡️ Calling repo.deleteMessage() ...")
                try await repo.deleteMessage(conversationId: conversationId, messageId: messageId, token: token)
                
                messages.removeAll { $0.id == messageId }
                log("🗑️ Message removed from UI")
                
            } catch {
                log("❌ deleteMessage() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    
    
    // ===============================================================
    // MARK: - Edit Conversation Title
    // ===============================================================
    
    func editConversationTitle(conversationId: String, newTitle: String) {
        log("📌 editConversationTitle() → convId=\(conversationId), newTitle='\(newTitle)'")
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ editConversationTitle(): Missing token")
                    return
                }
                
                log("➡️ Calling repo.editConversation() ...")
                let updated = try await repo.editConversation(
                    conversationId: conversationId,
                    title: newTitle,
                    token: token
                )
                
                if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[idx] = updated
                    log("🔄 Conversation title updated in list")
                }
                
                if selectedConversation?.id == conversationId {
                    selectedConversation = updated
                    log("📌 Updated selectedConversation title")
                }
                
            } catch {
                log("❌ editConversationTitle() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
    
    
    // ===============================================================
    // MARK: - Delete Conversation
    // ===============================================================
    
    func deleteConversation(conversationId: String) {
        log("📌 deleteConversation() → convId=\(conversationId)")
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    log("❌ deleteConversation(): Missing token")
                    return
                }
                
                log("➡️ Calling repo.deleteConversation() ...")
                try await repo.deleteConversation(conversationId: conversationId, token: token)
                
                conversations.removeAll { $0.id == conversationId }
                log("🗑️ Conversation removed from UI")
                
                if selectedConversation?.id == conversationId {
                    selectedConversation = conversations.max(by: { $0.id < $1.id })
                    
                    if let c = selectedConversation {
                        log("📌 New selectedConversation: \(c.id)")
                        loadMessages(conversationId: c.id, userId: c.userId)
                    } else {
                        log("📌 No conversations left → clearing message list")
                        messages = []
                    }
                }
                
            } catch {
                log("❌ deleteConversation() error: \(error.localizedDescription)")
                self.error = error.localizedDescription
            }
        }
    }
}
