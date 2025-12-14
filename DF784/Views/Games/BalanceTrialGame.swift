//
//  BalanceTrialGame.swift
//  DF784
//

import SwiftUI

struct BalanceTrialGame: View {
    @ObservedObject var userProgress: UserProgress
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedDifficulty: Difficulty?
    @State private var selectedLevel: Int?
    @State private var isPlaying = false
    @State private var showResult = false
    @State private var didWin = false
    @State private var score = 0
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            
            if isPlaying, let difficulty = selectedDifficulty, let level = selectedLevel {
                BalanceTrialGameplay(
                    difficulty: difficulty,
                    level: level,
                    onComplete: { won, finalScore in
                        didWin = won
                        score = finalScore
                        if won {
                            userProgress.completeLevel(game: .balanceTrial, difficulty: difficulty, level: level, score: finalScore)
                        } else {
                            userProgress.addAttempt(game: .balanceTrial, difficulty: difficulty, level: level)
                        }
                        withAnimation {
                            isPlaying = false
                            showResult = true
                        }
                    },
                    onExit: {
                        withAnimation {
                            isPlaying = false
                            selectedLevel = nil
                        }
                    }
                )
            } else if showResult {
                GameResultView(
                    didWin: didWin,
                    score: score,
                    onPlayAgain: {
                        showResult = false
                        isPlaying = true
                    },
                    onBack: {
                        showResult = false
                        selectedLevel = nil
                    }
                )
            } else if let difficulty = selectedDifficulty {
                LevelSelectorView(
                    game: .balanceTrial,
                    difficulty: difficulty,
                    gameProgress: userProgress.gameProgress[.balanceTrial] ?? GameProgress(),
                    onSelectLevel: { level in
                        selectedLevel = level
                        isPlaying = true
                    },
                    onBack: {
                        selectedDifficulty = nil
                    }
                )
            } else {
                DifficultySelectorView(
                    game: .balanceTrial,
                    gameProgress: userProgress.gameProgress[.balanceTrial] ?? GameProgress(),
                    onSelectDifficulty: { difficulty in
                        selectedDifficulty = difficulty
                    },
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Balance Trial Gameplay
struct BalanceTrialGameplay: View {
    let difficulty: Difficulty
    let level: Int
    let onComplete: (Bool, Int) -> Void
    let onExit: () -> Void
    
    @State private var leftValue: Double = 50
    @State private var isPaused = false
    @State private var rightValue: Double = 50
    @State private var balancePosition: Double = 0 // -1 to 1, 0 is balanced
    @State private var timeRemaining: Double = 30
    @State private var score = 0
    @State private var isGameActive = false
    @State private var showCountdown = true
    @State private var countdownValue = 3
    @State private var timer: Timer?
    @State private var gameTimer: Timer?
    @State private var lastBalanceTime: Double = 0
    @State private var balanceStreak: Double = 0
    
    private var toleranceWindow: Double {
        let base: Double
        switch difficulty {
        case .calm: base = 0.35
        case .focused: base = 0.25
        case .intense: base = 0.15
        }
        return base - (Double(level - 1) * 0.02)
    }
    
    private var driftSpeed: Double {
        let base: Double
        switch difficulty {
        case .calm: base = 0.3
        case .focused: base = 0.5
        case .intense: base = 0.8
        }
        return base + (Double(level - 1) * 0.05)
    }
    
    private var gameDuration: Double {
        switch difficulty {
        case .calm: return 30
        case .focused: return 25
        case .intense: return 20
        }
    }
    
    private var isBalanced: Bool {
        abs(balancePosition) <= toleranceWindow
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            VStack(spacing: 0) {
                // HUD - Fixed at top
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Score: \(score)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("Streak: \(Int(balanceStreak))s")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.secondaryAccent)
                    }
                    .foregroundColor(AppColors.softWhite)
                    
                    Spacer()
                    
                    PauseButton {
                        pauseGame()
                    }
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.1fs", max(0, timeRemaining)))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(timeRemaining < 5 ? AppColors.primaryAccent : AppColors.softWhite)
                        
                        Text("Level \(level)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 10)
                
                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Balance indicator zone
                        ZStack {
                            // Tolerance zone indicator
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            AppColors.secondaryAccent.opacity(0.15),
                                            AppColors.secondaryAccent.opacity(0.3),
                                            AppColors.secondaryAccent.opacity(0.15),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(toleranceWindow * 2), height: 160)
                            
                            // Center line
                            Rectangle()
                                .fill(AppColors.secondaryAccent.opacity(0.5))
                                .frame(width: 2, height: 140)
                            
                            // Balance beam
                            BalanceBeam(
                                position: balancePosition,
                                width: min(geometry.size.width * 0.7, 280),
                                isBalanced: isBalanced
                            )
                            .offset(x: CGFloat(balancePosition) * min(geometry.size.width * 0.35, 140))
                        }
                        .frame(height: 160)
                        .padding(.top, 20)
                        
                        // Value indicators
                        HStack(spacing: 40) {
                            ValueIndicator(
                                value: leftValue,
                                label: "Energy",
                                color: AppColors.primaryAccent
                            )
                            
                            ValueIndicator(
                                value: rightValue,
                                label: "Focus",
                                color: AppColors.secondaryAccent
                            )
                        }
                        .padding(.vertical, 10)
                        
                        // Control buttons
                        HStack(spacing: 30) {
                            BalanceButton(
                                label: "Energy",
                                icon: "flame.fill",
                                color: AppColors.primaryAccent,
                                onPress: {
                                    adjustLeft()
                                }
                            )
                            
                            BalanceButton(
                                label: "Focus",
                                icon: "sparkles",
                                color: AppColors.secondaryAccent,
                                onPress: {
                                    adjustRight()
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer().frame(height: max(safeAreaBottom + 20, 40))
                    }
                }
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .overlay(
            Group {
                if showCountdown {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            Text("\(countdownValue)")
                                .font(.system(size: 120, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primaryAccent)
                                .shadow(color: AppColors.primaryAccent.opacity(0.5), radius: 20)
                            
                            Text("Keep the balance centered!")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.softWhite.opacity(0.8))
                        }
                    }
                }
                
                if isPaused {
                    PauseMenuView(
                        onResume: {
                            resumeGame()
                        },
                        onExit: {
                            gameTimer?.invalidate()
                            timer?.invalidate()
                            onExit()
                        }
                    )
                }
            }
        )
        .onAppear {
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
            gameTimer?.invalidate()
        }
    }
    
    private func pauseGame() {
        isPaused = true
        gameTimer?.invalidate()
    }
    
    private func resumeGame() {
        isPaused = false
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func startCountdown() {
        countdownValue = 3
        showCountdown = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countdownValue -= 1
            if countdownValue <= 0 {
                timer?.invalidate()
                showCountdown = false
                startGame()
            }
        }
    }
    
    private func startGame() {
        timeRemaining = gameDuration
        isGameActive = true
        balancePosition = 0
        leftValue = 50
        rightValue = 50
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateGame()
        }
    }
    
    private func updateGame() {
        guard isGameActive else { return }
        
        timeRemaining -= 0.05
        
        // Natural drift - values drift randomly
        let driftAmount = driftSpeed * 0.05
        leftValue += Double.random(in: -driftAmount...driftAmount * 1.5)
        rightValue += Double.random(in: -driftAmount...driftAmount * 1.5)
        
        // Clamp values
        leftValue = max(0, min(100, leftValue))
        rightValue = max(0, min(100, rightValue))
        
        // Calculate balance position based on difference
        let diff = (leftValue - rightValue) / 100.0
        balancePosition = diff
        
        // Score if balanced
        if isBalanced {
            balanceStreak += 0.05
            if balanceStreak > 0.5 {
                score += 1
            }
        } else {
            balanceStreak = max(0, balanceStreak - 0.1)
        }
        
        // Check game end
        if timeRemaining <= 0 {
            endGame()
        }
        
        // Check fail condition - if too unbalanced for too long
        if abs(balancePosition) > 0.9 {
            endGame()
        }
    }
    
    private func adjustLeft() {
        guard isGameActive else { return }
        leftValue -= 8
        rightValue += 3
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func adjustRight() {
        guard isGameActive else { return }
        rightValue -= 8
        leftValue += 3
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    private func endGame() {
        gameTimer?.invalidate()
        isGameActive = false
        
        // Win if survived and has decent score
        let didWin = timeRemaining <= 0 && score >= Int(gameDuration * 5)
        onComplete(didWin, score)
    }
}

struct BalanceBeam: View {
    let position: Double
    let width: CGFloat
    let isBalanced: Bool
    
    var body: some View {
        ZStack {
            // Glow effect
            Capsule()
                .fill(
                    isBalanced ?
                    AppColors.secondaryAccent.opacity(0.3) :
                    AppColors.primaryAccent.opacity(0.3)
                )
                .frame(width: width + 20, height: 30)
                .blur(radius: 10)
            
            // Main beam
            Capsule()
                .fill(
                    LinearGradient(
                        colors: isBalanced ?
                        [AppColors.secondaryAccent, AppColors.secondaryAccent.opacity(0.7)] :
                        [AppColors.primaryAccent, AppColors.primaryAccent.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: width, height: 16)
            
            // Center indicator
            Circle()
                .fill(AppColors.softWhite)
                .frame(width: 24, height: 24)
                .shadow(color: Color.black.opacity(0.3), radius: 4)
        }
        .rotationEffect(.degrees(position * 10))
        .animation(.spring(response: 0.3), value: position)
    }
}

struct ValueIndicator: View {
    let value: Double
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: value / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(value))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
            }
            
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.softWhite.opacity(0.7))
        }
    }
}

struct BalanceButton: View {
    let label: String
    let icon: String
    let color: Color
    let onPress: () -> Void
    
    var body: some View {
        Button(action: onPress) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(BalanceButtonStyle())
    }
}

struct BalanceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    BalanceTrialGame(userProgress: UserProgress())
}
