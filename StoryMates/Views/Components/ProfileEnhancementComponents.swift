import SwiftUI

// MARK: - Level Progress View
struct LevelProgressView: View {
    let level: Int
    let currentXP: Int
    let nextLevelXP: Int
    
    var progress: Double {
        Double(currentXP) / Double(nextLevelXP)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // Level Badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: .yellow.opacity(0.5), radius: 8, x: 0, y: 0)
                    
                    VStack(spacing: 2) {
                        Text("LVL")
                            .font(.custom("PressStart2P-Regular", size: 8))
                            .foregroundColor(.black)
                        Text("\(level)")
                            .font(.custom("PressStart2P-Regular", size: 16))
                            .foregroundColor(.black)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Level \(level)")
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(currentXP) / \(nextLevelXP) XP")
                            .font(.custom("PressStart2P-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // XP Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.4))
                                .frame(height: 20)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 20)
                                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                            
                            // Pixelated border
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 2)
                                .frame(height: 20)
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
        )
    }
}

// MARK: - Achievement Badge View
struct AchievementBadgeView: View {
    let achievementId: String
    let isUnlocked: Bool
    
    var achievementInfo: (icon: String, name: String, color: Color) {
        switch achievementId {
        case "first_game":
            return ("gamecontroller.fill", "First Game", .blue)
        case "collector":
            return ("square.stack.3d.up.fill", "Collector", .purple)
        case "completionist":
            return ("checkmark.seal.fill", "Completionist", .green)
        case "social":
            return ("person.3.fill", "Social", .orange)
        case "speedrunner":
            return ("hare.fill", "Speedrunner", .red)
        case "on_fire":
            return ("flame.fill", "On Fire", .orange)
        case "critic":
            return ("pencil.and.scribble", "Critic", .cyan)
        case "mission_master":
            return ("target", "Mission Master", .yellow)
        case "dedicated":
            return ("calendar", "Dedicated", .purple)
        case "veteran":
            return ("medal.fill", "Veteran", .yellow)
        default:
            return ("star.fill", "Achievement", .yellow)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievementInfo.color : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .shadow(color: isUnlocked ? achievementInfo.color.opacity(0.5) : .clear, radius: 8)
                
                Image(systemName: achievementInfo.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .white : .gray)
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .offset(x: 18, y: 18)
                }
            }
            
            Text(achievementInfo.name)
                .font(.custom("PressStart2P-Regular", size: 8))
                .foregroundColor(isUnlocked ? .white : .gray)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 70)
        }
    }
}

// MARK: - Activity Row View
struct ActivityRowView: View {
    let activity: RecentActivity
    
    var activityInfo: (icon: String, text: String, color: Color) {
        switch activity.type {
        case "added_game":
            return ("plus.circle.fill", "Added", .blue)
        case "started_game":
            return ("play.circle.fill", "Started", .green)
        case "completed_game":
            return ("checkmark.circle.fill", "Completed", .yellow)
        case "rated_game":
            return ("star.circle.fill", "Rated", .orange)
        default:
            return ("circle.fill", "Updated", .gray)
        }
    }
    
    var timeAgo: String {
        let now = Date()
        let interval = now.timeIntervalSince(activity.timestamp)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Game Cover
            AsyncImage(url: URL(string: activity.gameCover)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 70)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: activityInfo.icon)
                        .font(.system(size: 12))
                        .foregroundColor(activityInfo.color)
                    
                    Text(activityInfo.text)
                        .font(.custom("PressStart2P-Regular", size: 10))
                        .foregroundColor(activityInfo.color)
                }
                
                Text(activity.gameName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
