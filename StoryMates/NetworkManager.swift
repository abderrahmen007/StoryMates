// NetworkManager.swift
import Foundation

class NetworkManager: ObservableObject {
    let baseURL = "https://your-vercel-app.vercel.app/api" // Your NestJS backend URL
    
    func registerUser(username: String, email: String, password: String) async throws -> [String: Any] {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "username": username,
            "email": email,
            "password": password
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json ?? [:]
    }
}