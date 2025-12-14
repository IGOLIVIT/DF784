//
//  GamesHubView.swift
//  DF784
//

import SwiftUI

struct GamesHubView: View {
    @ObservedObject var userProgress: UserProgress
    @State private var isVisible = false
    @State private var selectedGame: GameType?
    @State private var showPrecisionPath = false
    @State private var showPatternFlow = false
    @State private var showBalanceTrial = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AnimatedBackgroundView()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Games")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.softWhite)
                            
                            Text("Choose your challenge")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.softWhite.opacity(0.6))
                        }
                        .padding(.top, 20)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : -20)
                        
                        // Game Cards
                        VStack(spacing: 20) {
                            GameCard(
                                game: .precisionPath,
                                progress: userProgress.gameProgress[.precisionPath] ?? GameProgress(),
                                onTap: {
                                    showPrecisionPath = true
                                }
                            )
                            
                            GameCard(
                                game: .patternFlow,
                                progress: userProgress.gameProgress[.patternFlow] ?? GameProgress(),
                                onTap: {
                                    showPatternFlow = true
                                }
                            )
                            
                            GameCard(
                                game: .balanceTrial,
                                progress: userProgress.gameProgress[.balanceTrial] ?? GameProgress(),
                                onTap: {
                                    showBalanceTrial = true
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 30)
                        
                        Spacer().frame(height: 120)
                    }
                }
                
                // Navigation Links
                NavigationLink(destination: PrecisionPathGame(userProgress: userProgress), isActive: $showPrecisionPath) {
                    EmptyView()
                }
                .hidden()
                
                NavigationLink(destination: PatternFlowGame(userProgress: userProgress), isActive: $showPatternFlow) {
                    EmptyView()
                }
                .hidden()
                
                NavigationLink(destination: BalanceTrialGame(userProgress: userProgress), isActive: $showBalanceTrial) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }
}

struct GameCard: View {
    let game: GameType
    let progress: GameProgress
    let onTap: () -> Void
    
    @State private var glowAmount: CGFloat = 0.3
    
    private var totalLevels: Int {
        Difficulty.allCases.reduce(0) { $0 + $1.levelCount }
    }
    
    private var completedLevels: Int {
        progress.totalCompletedLevels()
    }
    
    private var progressPercent: Double {
        guard totalLevels > 0 else { return 0 }
        return Double(completedLevels) / Double(totalLevels)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main content area
                HStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppColors.primaryAccent.opacity(glowAmount),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(AppColors.primaryAccent.opacity(0.15))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.primaryAccent.opacity(0.3), lineWidth: 1)
                            )
                        
                        Image(systemName: game.icon)
                            .font(.system(size: 30))
                            .foregroundColor(AppColors.primaryAccent)
                    }
                    
                    // Text content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.rawValue)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                        
                        Text(game.description)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.6))
                        
                        // Progress bar
                        HStack(spacing: 10) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progressPercent, height: 6)
                                }
                            }
                            .frame(height: 6)
                            
                            Text("\(completedLevels)/\(totalLevels)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.softWhite.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.softWhite.opacity(0.3))
                }
                .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(GameCardButtonStyle())
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowAmount = 0.5
            }
        }
    }
}

// MARK: - Game Card Button Style
struct GameCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    GamesHubView(userProgress: UserProgress())
}
