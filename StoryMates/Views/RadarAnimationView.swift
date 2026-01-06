//
//  RadarAnimationView.swift
//  StoryMates
//
//  Radar animation for Nearby Teammates feature
//

import SwiftUI

struct RadarAnimationView: View {
    let nearbyUsers: [NetworkManager.NearbyUser]
    let range: Int
    var onUserTapped: ((NetworkManager.NearbyUser) -> Void)? = nil
    
    @State private var pulsePhases: [Double] = [0, 0.33, 0.66]
    @State private var sweepAngle: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Pulsing circles
                ForEach(0..<3, id: \.self) { index in
                    PulseCircle(phase: pulsePhases[index])
                        .stroke(Color.cyan.opacity(0.4 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: size, height: size)
                }
                
                // Range circles with distance labels
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .frame(width: size * fraction, height: size * fraction)
                }
                
                // Distance labels
                distanceLabels(size: size, center: center)
                
                // Radar sweep wedge with gradient
                RadarSweepWedge(angle: sweepAngle, sweepWidth: 60)
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0),
                                Color.green.opacity(0.4)
                            ]),
                            center: .center,
                            startAngle: .degrees(sweepAngle - 60),
                            endAngle: .degrees(sweepAngle)
                        )
                    )
                    .frame(width: size, height: size)
                
                // Simple sweep line
                Path { path in
                    path.move(to: center)
                    path.addLine(to: CGPoint(
                        x: center.x + cos(sweepAngle * .pi / 180) * size / 2,
                        y: center.y + sin(sweepAngle * .pi / 180) * size / 2
                    ))
                }
                .stroke(Color.green.opacity(0.8), lineWidth: 2)
                
                // Center dot (you)
                ZStack {
                    Circle()
                        .fill(Color.yellow.opacity(0.3))
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 16, height: 16)
                        .shadow(color: .yellow.opacity(0.6), radius: 8)
                    Text("YOU")
                        .font(.system(size: 5, weight: .bold))
                        .foregroundColor(.black)
                }
                
                // User dots
                ForEach(nearbyUsers) { user in
                    let position = userPosition(for: user, in: size, range: range)
                    
                    NearbyUserDot(user: user)
                        .position(x: center.x + position.x, y: center.y + position.y)
                        .onTapGesture {
                            onUserTapped?(user)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            startAnimations()
        }
    }
    
    private func distanceLabels(size: Double, center: CGPoint) -> some View {
        let fractions: [(Double, String)] = [
            (0.25, "\(range / 4)km"),
            (0.5, "\(range / 2)km"),
            (0.75, "\(range * 3 / 4)km"),
            (1.0, "\(range)km")
        ]
        
        return ForEach(fractions, id: \.0) { fraction, label in
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .position(
                    x: center.x + (size / 2 * fraction) - 15,
                    y: center.y - 8
                )
        }
    }
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            pulsePhases = pulsePhases.map { phase in
                (phase + 1).truncatingRemainder(dividingBy: 1)
            }
        }
        
        // Sweep animation
        sweepAngle = 0
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            sweepAngle = 360
        }
    }
    
    private func userPosition(for user: NetworkManager.NearbyUser, in size: Double, range: Int) -> CGPoint {
        // Safely unwrap optional distance; default to 0 if unknown
        let userDistance = user.distance ?? 0
        let distanceRatio = min(userDistance / Double(range), 0.9)
        let radius = (size / 2) * distanceRatio
        let angle = Double(user.id.hashValue % 360) * .pi / 180
        
        return CGPoint(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
    }
}

struct RadarSweepWedge: Shape {
    var angle: Double
    var sweepWidth: Double = 60
    
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(angle - sweepWidth),
            endAngle: .degrees(angle),
            clockwise: false
        )
        path.closeSubpath()
        
        return path
    }
}

struct PulseCircle: Shape {
    var phase: Double
    
    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let scale = 0.2 + phase * 0.8
        let size = min(rect.width, rect.height) * scale
        let origin = CGPoint(
            x: rect.midX - size / 2,
            y: rect.midY - size / 2
        )
        
        var path = Path()
        path.addEllipse(in: CGRect(origin: origin, size: CGSize(width: size, height: size)))
        return path
    }
}

struct NearbyUserDot: View {
    let user: NetworkManager.NearbyUser
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color.cyan.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .scaleEffect(isAnimating ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                
                // Main dot
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            // Name label with distance
            VStack(spacing: 1) {
                Text(user.name.prefix(6))
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                if let d = user.distance {
                    Text(String(format: "%.0fkm", d))
                        .font(.system(size: 6))
                        .foregroundColor(.cyan)
                } else {
                    Text("--km")
                        .font(.system(size: 6))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.7))
            .cornerRadius(4)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
