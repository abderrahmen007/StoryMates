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
    
    private let repo = AiConversationRepository.shared
    
    // MARK: - public interface (same names as Android)
    
    func loadConversations(userId: String) {
        error = nil
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else {
                    error = "No access token. Please login again."
                    return
                }
                let list = try await repo.getConversations(userId: userId, token: token)
                conversations = list
                selectedConversation = list.max(by: { $0.id < $1.id })
                if let c = selectedConversation {
                    loadMessages(conversationId: c.id, userId: userId)
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func selectConversation(_ c: Conversation, userId: String) {
        selectedConversation = c
        loadMessages(conversationId: c.id, userId: userId)
    }
    
    func loadMessages(conversationId: String, userId: String) {
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                messages = try await repo.getMessages(conversationId: conversationId,
                                                    userId: userId,
                                                    token: token)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func sendMessage(userId: String) {
        guard let conv = selectedConversation else { return }
        let content = messageInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.isEmpty { return }
        
        // optimistic insert
        let temp = Message(id: "pending-\(UUID().uuidString)",
                         conversationId: conv.id,
                         sender: "user",
                         content: content,
                         timestamp: String(Date().timeIntervalSince1970))
        messages.append(temp)
        messageInput = ""
        
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                let real = try await repo.createMessage(conversationId: conv.id,
                                                      dto: CreateMessageDto(userId: userId,
                                                                          content: content),
                                                      token: token)
                // replace temp
                if let idx = messages.firstIndex(where: { $0.id == temp.id }) {
                    messages[idx] = real
                }
                loadMessages(conversationId: conv.id, userId: userId)
            } catch {
                messages.removeAll { $0.id == temp.id }
                self.error = error.localizedDescription
            }
        }
    }
    
    func createNewConversation(title: String = "New Conversation", userId: String) {
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                let dto     = CreateConversationDto(title: title, userId: userId)
                let newConv = try await repo.createConversation(dto: dto, token: token)
                
                conversations.append(newConv)
                selectedConversation = newConv
                isAddingNewConversation = false
            } catch {
                self.error = error.localizedDescription
                isAddingNewConversation = false
            }
        }
    }
    
    func editMessage(messageId: String, newText: String, userId: String) {
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                let updated = try await repo.editMessage(messageId: messageId,
                                                       newText: newText,
                                                       token: token)
                if let idx = messages.firstIndex(where: { $0.id == messageId }) {
                    messages[idx] = updated
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func deleteMessage(messageId: String, userId: String) {
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                try await repo.deleteMessage(messageId: messageId, token: token)
                messages.removeAll { $0.id == messageId }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func editConversationTitle(conversationId: String, newTitle: String) {
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                let updated = try await repo.editConversation(conversationId: conversationId,
                                                            title: newTitle,
                                                            token: token)
                if let idx = conversations.firstIndex(where: { $0.id == conversationId }) {
                    conversations[idx] = updated
                }
                if selectedConversation?.id == conversationId {
                    selectedConversation = updated
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func deleteConversation(conversationId: String) {
        Task {
            do {
                guard let token = AuthManager.shared.accessToken else { return }
                try await repo.deleteConversation(conversationId: conversationId, token: token)
                
                conversations.removeAll { $0.id == conversationId }
                
                if selectedConversation?.id == conversationId {
                    selectedConversation = conversations.max(by: { $0.id < $1.id })
                    if let c = selectedConversation {
                        loadMessages(conversationId: c.id, userId: c.userId)
                    } else {
                        messages = []
                    }
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
