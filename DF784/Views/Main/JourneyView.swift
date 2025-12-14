//
//  JourneyView.swift
//  DF784
//

import SwiftUI

struct JourneyView: View {
    @ObservedObject var userProgress: UserProgress
    @State private var isVisible = false
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Your Journey")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                        
                        Text("Progress through mastery")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.6))
                    }
                    .padding(.top, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : -20)
                    
                    // Main Progress Ring
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppColors.primaryAccent.opacity(0.2),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 80,
                                    endRadius: 160
                                )
                            )
                            .frame(width: 320, height: 320)
                            .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                        
                        ProgressRing(
                            progress: energyProgress,
                            lineWidth: 14,
                            size: 200
                        )
                        
                        VStack(spacing: 8) {
                            Text("Energy Level")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.softWhite.opacity(0.6))
                            
                            Text("\(userProgress.energyLevel)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Stage \(userProgress.currentStage)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.secondaryAccent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppColors.secondaryAccent.opacity(0.15))
                                )
                        }
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        StatCard(
                            icon: "checkmark.circle.fill",
                            value: "\(userProgress.totalCompletedLevels)",
                            label: "Levels Completed",
                            color: AppColors.secondaryAccent
                        )
                        
                        StatCard(
                            icon: "trophy.fill",
                            value: "\(userProgress.unlockedAchievements)",
                            label: "Achievements",
                            color: AppColors.primaryAccent
                        )
                        
                        StatCard(
                            icon: "flame.fill",
                            value: "\(userProgress.totalGamesPlayed)",
                            label: "Games Played",
                            color: AppColors.primaryAccent
                        )
                        
                        StatCard(
                            icon: "star.fill",
                            value: difficultyUnlocked,
                            label: "Difficulty Unlocked",
                            color: AppColors.secondaryAccent
                        )
                    }
                    .padding(.horizontal, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 30)
                    
                    // Achievements Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Achievements")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentAchievements) { achievement in
                                    AchievementCard(achievement: achievement)
                                }
                                
                                if recentAchievements.isEmpty {
                                    EmptyAchievementCard()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 40)
                    
                    // Game Progress Overview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Game Progress")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                        
                        ForEach(GameType.allCases, id: \.self) { game in
                            GameProgressRow(
                                game: game,
                                progress: userProgress.gameProgress[game] ?? GameProgress()
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 50)
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isVisible = true
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    private var energyProgress: Double {
        return Double(userProgress.energyLevel) / 10.0
    }
    
    private var difficultyUnlocked: String {
        let calm = userProgress.gameProgress.values.first { $0.completedLevels(for: .calm) >= 3 } != nil
        let focused = userProgress.gameProgress.values.first { $0.completedLevels(for: .focused) >= 4 } != nil
        
        if focused { return "Intense" }
        if calm { return "Focused" }
        return "Calm"
    }
    
    private var recentAchievements: [Achievement] {
        userProgress.achievements
            .filter { $0.unlocked }
            .sorted { ($0.unlockedDate ?? .distantPast) > ($1.unlockedDate ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softWhite)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softWhite.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardStyle()
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.primaryAccent)
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
                    .lineLimit(1)
                
                Text(achievement.description)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.softWhite.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 140)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .cardStyle()
    }
}

struct EmptyAchievementCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 28))
                .foregroundColor(AppColors.softWhite.opacity(0.3))
            
            VStack(spacing: 4) {
                Text("Keep Playing")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softWhite.opacity(0.5))
                
                Text("Complete levels to earn achievements")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.softWhite.opacity(0.4))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 140)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .cardStyle()
    }
}

struct GameProgressRow: View {
    let game: GameType
    let progress: GameProgress
    
    private var totalLevels: Int {
        Difficulty.allCases.reduce(0) { $0 + $1.levelCount }
    }
    
    private var completedLevels: Int {
        progress.totalCompletedLevels()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: game.icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.primaryAccent)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(AppColors.primaryAccent.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(game.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(completedLevels) / CGFloat(totalLevels), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            Text("\(completedLevels)/\(totalLevels)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softWhite.opacity(0.6))
        }
        .padding(16)
        .cardStyle()
    }
}

#Preview {
    JourneyView(userProgress: UserProgress())
}

