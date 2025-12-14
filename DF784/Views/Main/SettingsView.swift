//
//  SettingsView.swift
//  DF784
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var userProgress: UserProgress
    @State private var isVisible = false
    @State private var showResetConfirmation = false
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                        
                        Text("Your journey statistics")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.6))
                    }
                    .padding(.top, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : -20)
                    
                    // Statistics Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistics")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            StatRow(
                                icon: "gamecontroller.fill",
                                label: "Games Played",
                                value: "\(userProgress.totalGamesPlayed)"
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            StatRow(
                                icon: "checkmark.circle.fill",
                                label: "Levels Completed",
                                value: "\(userProgress.totalCompletedLevels)"
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            StatRow(
                                icon: "trophy.fill",
                                label: "Achievements Unlocked",
                                value: "\(userProgress.unlockedAchievements)/\(Achievement.all.count)"
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            StatRow(
                                icon: "flame.fill",
                                label: "Energy Level",
                                value: "\(userProgress.energyLevel)"
                            )
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            StatRow(
                                icon: "star.fill",
                                label: "Current Stage",
                                value: "\(userProgress.currentStage)"
                            )
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    
                    // Game-specific stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Game Details")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                            .padding(.horizontal, 20)
                        
                        ForEach(GameType.allCases, id: \.self) { game in
                            GameStatCard(
                                game: game,
                                progress: userProgress.gameProgress[game] ?? GameProgress()
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 30)
                    
                    // All Achievements
                    VStack(alignment: .leading, spacing: 16) {
                        Text("All Achievements")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 12) {
                            ForEach(userProgress.achievements) { achievement in
                                AchievementRow(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 40)
                    
                    // Reset Progress Button
                    VStack(spacing: 12) {
                        Button(action: {
                            showResetConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset Progress")
                            }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AppColors.primaryAccent.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        Text("This will erase all your progress and achievements")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                    .opacity(isVisible ? 1 : 0)
                    
                    Spacer().frame(height: 120)
                }
            }
        }
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                userProgress.reset()
            }
        } message: {
            Text("This will permanently erase all your progress, achievements, and statistics. This action cannot be undone.")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primaryAccent)
                .frame(width: 30)
            
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softWhite)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.softWhite)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

struct GameStatCard: View {
    let game: GameType
    let progress: GameProgress
    
    private var totalAttempts: Int {
        var total = 0
        for difficulty in Difficulty.allCases {
            for level in 1...difficulty.levelCount {
                total += progress.levels[difficulty]?[level]?.attempts ?? 0
            }
        }
        return total
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: game.icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.primaryAccent)
                
                Text(game.rawValue)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.softWhite.opacity(0.5))
                    Text("\(progress.totalCompletedLevels())")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.secondaryAccent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Attempts")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.softWhite.opacity(0.5))
                    Text("\(totalAttempts)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softWhite)
                }
                
                Spacer()
                
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    VStack(spacing: 4) {
                        Text("\(progress.completedLevels(for: difficulty))")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(difficulty.color)
                        
                        Text(String(difficulty.rawValue.prefix(1)))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.4))
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: achievement.unlocked ? "trophy.fill" : "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(achievement.unlocked ? AppColors.primaryAccent : Color.gray.opacity(0.5))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(achievement.unlocked ? AppColors.softWhite : AppColors.softWhite.opacity(0.5))
                
                Text(achievement.description)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(AppColors.softWhite.opacity(0.4))
            }
            
            Spacer()
            
            if achievement.unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.secondaryAccent)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    achievement.unlocked ?
                    AppColors.secondaryAccent.opacity(0.08) :
                    Color.white.opacity(0.03)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            achievement.unlocked ?
                            AppColors.secondaryAccent.opacity(0.2) :
                            Color.white.opacity(0.05),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    SettingsView(userProgress: UserProgress())
}

