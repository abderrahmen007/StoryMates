//
//  LevelUpAnimationView.swift
//  StoryMates
//
//  Created by Claude on 12/15/24.
//

import SwiftUI

struct LevelUpAnimationView: View {
    let newLevel: Int
    let xpAwarded: Int
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var levelScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Confetti particles
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // Level Up Text
                Text("LEVEL UP!")
                    .font(.custom("PressStart2P-Regular", size: 32))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)
                    .shadow(color: .yellow.opacity(0.5), radius: 20)
                    .opacity(textOpacity)
                
                // Level Badge
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.6), Color.clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                    
                    // Main badge
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: .yellow.opacity(0.8), radius: 20)
                    
                    VStack(spacing: 4) {
                        Text("LVL")
                            .font(.custom("PressStart2P-Regular", size: 16))
                            .foregroundColor(.black)
                        Text("\(newLevel)")
                            .font(.custom("PressStart2P-Regular", size: 48))
                            .foregroundColor(.black)
                    }
                }
                .scaleEffect(levelScale)
                
                // XP Awarded
                if xpAwarded > 0 {
                    Text("+\(xpAwarded) XP")
                        .font(.custom("PressStart2P-Regular", size: 18))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.5), radius: 5)
                        .opacity(textOpacity)
                }
                
                Spacer()
                
                // Continue button
                Button(action: onDismiss) {
                    Text("AWESOME!")
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.yellow)
                        .cornerRadius(10)
                        .shadow(color: .yellow.opacity(0.5), radius: 10)
                }
                .opacity(textOpacity)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Animate in sequence
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            levelScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1.0
            }
            showConfetti = true
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.yellow, .orange, .red, .green, .blue, .purple, .pink]
        
        for _ in 0..<50 {
            let particle = ConfettiParticle(
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -20
                ),
                endPosition: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + 50
                )
            )
            particles.append(particle)
        }
        
        // Animate particles falling
        for i in particles.indices {
            let delay = Double.random(in: 0...1)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: Double.random(in: 2...4))) {
                    particles[i].position = particles[i].endPosition
                    particles[i].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var endPosition: CGPoint
    var opacity: Double = 1.0
}

// MARK: - Achievement Unlocked View
struct AchievementUnlockedView: View {
    let achievementId: String
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var badgeScale: CGFloat = 0.3
    
    var achievementInfo: (icon: String, name: String, description: String, color: Color) {
        switch achievementId {
        case "first_game":
            return ("gamecontroller.fill", "First Game", "Added your first game to collection", .blue)
        case "collector":
            return ("square.stack.3d.up.fill", "Collector", "Own 10+ games in collection", .purple)
        case "completionist":
            return ("checkmark.seal.fill", "Completionist", "Completed 100% of a game", .green)
        case "social":
            return ("person.3.fill", "Social Butterfly", "Matched with 5 teammates", .orange)
        case "speedrunner":
            return ("hare.fill", "Speedrunner", "Complete a game within 1 week", .red)
        case "on_fire":
            return ("flame.fill", "On Fire", "7-day login streak", .orange)
        case "critic":
            return ("pencil.and.scribble", "Critic", "Write 10 reviews", .cyan)
        case "mission_master":
            return ("target", "Mission Master", "Complete 100 missions", .yellow)
        case "dedicated":
            return ("calendar", "Dedicated", "30-day login streak", .purple)
        case "veteran":
            return ("medal.fill", "Veteran", "Reach level 10", .yellow)
        default:
            return ("star.fill", "Achievement", "Unknown achievement", .yellow)
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 25) {
                Text("ACHIEVEMENT UNLOCKED!")
                    .font(.custom("PressStart2P-Regular", size: 14))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 5)
                
                // Achievement Badge
                ZStack {
                    // Glow
                    Circle()
                        .fill(achievementInfo.color.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Badge
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [achievementInfo.color, achievementInfo.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(color: achievementInfo.color.opacity(0.8), radius: 15)
                    
                    Image(systemName: achievementInfo.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                .scaleEffect(badgeScale)
                
                VStack(spacing: 8) {
                    Text(achievementInfo.name)
                        .font(.custom("PressStart2P-Regular", size: 16))
                        .foregroundColor(.white)
                    
                    Text(achievementInfo.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Text("+50 XP")
                    .font(.custom("PressStart2P-Regular", size: 14))
                    .foregroundColor(.green)
                
                Button(action: onDismiss) {
                    Text("NICE!")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(achievementInfo.color)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(achievementInfo.color, lineWidth: 2)
                    )
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                badgeScale = 1.0
            }
        }
    }
}

// MARK: - XP Gained Toast
struct XPGainedToast: View {
    let xpAmount: Int
    let multiplier: Double
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("+\(xpAmount) XP")
                    .font(.custom("PressStart2P-Regular", size: 14))
                    .foregroundColor(.green)
                
                if multiplier > 1.0 {
                    Text("\(String(format: "%.1f", multiplier))x Streak Bonus!")
                        .font(.custom("PressStart2P-Regular", size: 8))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 2)
                )
        )
        .shadow(color: .green.opacity(0.3), radius: 10)
    }
}

// MARK: - Streak Display View
struct StreakDisplayView: View {
    let currentStreak: Int
    let multiplier: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .foregroundColor(currentStreak >= 7 ? .orange : .gray)
                .font(.system(size: 18))
            
            Text("\(currentStreak)")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(currentStreak >= 7 ? .orange : .white)
            
            if multiplier > 1.0 {
                Text("\(String(format: "%.1f", multiplier))x")
                    .font(.custom("PressStart2P-Regular", size: 10))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(currentStreak >= 7 ? Color.orange : Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LevelUpAnimationView(newLevel: 5, xpAwarded: 100) {}
    }
}
