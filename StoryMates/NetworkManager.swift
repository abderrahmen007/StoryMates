//
//  NetworkManager.swift
//  StoryMates
//
//  Created by mac on 11/19/25.
//

import Foundation
import Combine

enum NetworkError: LocalizedError {
    case badURL
    case badServerResponse
    case invalidCredentials
    case emailAlreadyInUse
    case invalidToken
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .badURL:
            return "Invalid URL"
        case .badServerResponse:
            return "Server error occurred"
        case .invalidCredentials:
            return "Invalid credentials"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .invalidToken:
            return "Invalid or expired reset token"
        case .unknown(let message):
            return message
        }
    }
}

class NetworkManager: ObservableObject {
    // Update this to your local server URL
    let baseURL = "http://192.168.1.124:3001" // Example: Local development server
    
    func signup(name: String, email: String, password: String) async throws {
        let endpoints = ["/auth/signup"]
        var lastError: Error?
        
        for endpoint in endpoints {
            // Print the full URL for debugging
            let fullURL = "\(baseURL)\(endpoint)"
            print("Attempting to connect to: \(fullURL)")
            
            guard let url = URL(string: fullURL) else {
                print("❌ Failed to create URL from string: \(fullURL)")
                lastError = NetworkError.badURL
                continue
            }
        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Add timeout interval
            request.timeoutInterval = 10 // 10 seconds timeout
            
            let body: [String: String] = [
                "name": name,
                "email": email,
                "password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            // Debug: Print request details
            print("Signup Request URL: \(endpoint)")
            print("Signup Request Body: \(body)")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                // Debug: Print response for troubleshooting
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Signup Response Status: \(httpResponse.statusCode)")
                    print("Signup Response Body: \(responseString)")
                }
                
                if httpResponse.statusCode == 201 {
                    return
                } else if httpResponse.statusCode == 401 {
                    throw NetworkError.invalidCredentials
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        let errorMessage = errorResponse.message
                        if errorMessage.contains("already in use") {
                            throw NetworkError.emailAlreadyInUse
                        }
                        throw NetworkError.unknown(errorMessage)
                    } else {
                        if let errorString = String(data: data, encoding: .utf8), !errorString.isEmpty {
                            throw NetworkError.unknown(errorString)
                        }
                        throw NetworkError.unknown("Server error (Status: \(httpResponse.statusCode))")
                    }
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoints = ["/auth/login"]
        var lastError: Error?
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                continue
            }
        
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let body: [String: String] = [
                "email": email,
                "password": password
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("Login successful with status code: \(httpResponse.statusCode)")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Login success body:", responseString)
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    do {
                        let authResponse = try decoder.decode(AuthResponse.self, from: data)
                        print("Decoded AuthResponse:", authResponse)
                        return authResponse
                    } catch {
                        print("Login decoding error:", error)
                        if let responseString = String(data: data, encoding: .utf8) {
                            print("Login body (on decode error):", responseString)
                        }
                        lastError = NetworkError.badServerResponse
                        continue
                    }
                } else if httpResponse.statusCode == 401 {
                    throw NetworkError.invalidCredentials
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorResponse.message)
                    }
                    lastError = NetworkError.badServerResponse
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    func forgotPassword(email: String) async throws {
        let endpoints = ["/api/auth/forgot-password", "/auth/forgot-password"]
        var lastError: Error?
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = [
                "email": email
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    return
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorResponse.message)
                    }
                    lastError = NetworkError.badServerResponse
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
    
    func resetPassword(token: String, newPassword: String, email: String) async throws {
        let endpoints = ["/api/auth/reset-password", "/auth/reset-password"]
        var lastError: Error?
        
        for endpoint in endpoints {
            guard let url = URL(string: "\(baseURL)\(endpoint)") else {
                continue
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: String] = [
                "token": token,
                "newPassword": newPassword,
                "email": email
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.badServerResponse
                    continue
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    return
                } else if httpResponse.statusCode == 400 {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data),
                       errorResponse.message.contains("Invalid") || errorResponse.message.contains("expired") {
                        throw NetworkError.invalidToken
                    }
                    throw NetworkError.invalidToken
                } else if httpResponse.statusCode == 404 {
                    lastError = NetworkError.unknown("Endpoint not found: \(endpoint)")
                    continue
                } else {
                    if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                        throw NetworkError.unknown(errorResponse.message)
                    }
                    lastError = NetworkError.badServerResponse
                    continue
                }
            } catch {
                lastError = error
                continue
            }
        }
        
        throw lastError ?? NetworkError.badServerResponse
    }
}
