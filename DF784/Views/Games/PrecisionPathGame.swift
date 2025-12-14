//
//  PrecisionPathGame.swift
//  DF784
//

import SwiftUI

struct PrecisionPathGame: View {
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
                PrecisionPathGameplay(
                    difficulty: difficulty,
                    level: level,
                    onComplete: { won, finalScore in
                        didWin = won
                        score = finalScore
                        if won {
                            userProgress.completeLevel(game: .precisionPath, difficulty: difficulty, level: level, score: finalScore)
                        } else {
                            userProgress.addAttempt(game: .precisionPath, difficulty: difficulty, level: level)
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
                    game: .precisionPath,
                    difficulty: difficulty,
                    gameProgress: userProgress.gameProgress[.precisionPath] ?? GameProgress(),
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
                    game: .precisionPath,
                    gameProgress: userProgress.gameProgress[.precisionPath] ?? GameProgress(),
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

// MARK: - Precision Path Gameplay
struct PrecisionPathGameplay: View {
    let difficulty: Difficulty
    let level: Int
    let onComplete: (Bool, Int) -> Void
    let onExit: () -> Void
    
    @State private var targets: [MovingTarget] = []
    @State private var score = 0
    @State private var tapsRemaining = 0
    @State private var targetsHit = 0
    @State private var targetsCaught = 0
    @State private var timeRemaining: Double = 0
    @State private var gameActive = false
    @State private var showCountdown = true
    @State private var countdownValue = 3
    @State private var timer: Timer?
    @State private var gameTimer: Timer?
    @State private var isPaused = false
    
    private var speed: Double {
        let baseSpeed: Double
        switch difficulty {
        case .calm: baseSpeed = 2.0
        case .focused: baseSpeed = 1.5
        case .intense: baseSpeed = 1.0
        }
        return baseSpeed - (Double(level - 1) * 0.1)
    }
    
    private var targetCount: Int {
        switch difficulty {
        case .calm: return 5 + level
        case .focused: return 7 + level
        case .intense: return 10 + level
        }
    }
    
    private var gameDuration: Double {
        switch difficulty {
        case .calm: return 30
        case .focused: return 25
        case .intense: return 20
        }
    }
    
    private var requiredHits: Int {
        return Int(Double(targetCount) * 0.6)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Game area
                if gameActive {
                    ForEach(targets) { target in
                        TargetView(target: target)
                            .position(target.position)
                            .onTapGesture {
                                hitTarget(target)
                            }
                    }
                }
                
                // HUD
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Score: \(score)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text("Hits: \(targetsHit)/\(requiredHits)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(AppColors.softWhite)
                        
                        Spacer()
                        
                        PauseButton {
                            pauseGame()
                        }
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(String(format: "%.1fs", timeRemaining))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(timeRemaining < 5 ? AppColors.primaryAccent : AppColors.softWhite)
                            
                            Text("Level \(level)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.softWhite.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    
                    Spacer()
                }
                
                // Countdown overlay
                if showCountdown {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                        
                        Text("\(countdownValue)")
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryAccent)
                            .shadow(color: AppColors.primaryAccent.opacity(0.5), radius: 20)
                    }
                }
                
                // Pause menu
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
        }
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
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            updateTargets()
            
            if timeRemaining <= 0 {
                endGame()
            }
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
        gameActive = true
        spawnTargets()
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            updateTargets()
            
            if timeRemaining <= 0 {
                endGame()
            }
        }
    }
    
    private func spawnTargets() {
        let screenSize = UIScreen.main.bounds
        let margin: CGFloat = 60
        
        for i in 0..<targetCount {
            let delay = Double(i) * (gameDuration / Double(targetCount))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard gameActive else { return }
                
                let startX = CGFloat.random(in: margin...(screenSize.width - margin))
                let startY = CGFloat.random(in: (margin + 100)...(screenSize.height - margin - 150))
                
                let target = MovingTarget(
                    position: CGPoint(x: startX, y: startY),
                    velocity: CGPoint(
                        x: CGFloat.random(in: -2...2) * CGFloat(3 - speed),
                        y: CGFloat.random(in: -2...2) * CGFloat(3 - speed)
                    ),
                    size: CGFloat.random(in: 50...70),
                    lifespan: speed * 2
                )
                targets.append(target)
            }
        }
    }
    
    private func updateTargets() {
        let screenSize = UIScreen.main.bounds
        let margin: CGFloat = 60
        
        for i in targets.indices {
            var target = targets[i]
            target.position.x += target.velocity.x
            target.position.y += target.velocity.y
            target.age += 0.1
            
            // Bounce off edges
            if target.position.x < margin || target.position.x > screenSize.width - margin {
                target.velocity.x *= -1
            }
            if target.position.y < margin + 100 || target.position.y > screenSize.height - margin - 150 {
                target.velocity.y *= -1
            }
            
            targets[i] = target
        }
        
        // Remove expired targets
        targets.removeAll { $0.age > $0.lifespan }
    }
    
    private func hitTarget(_ target: MovingTarget) {
        guard gameActive else { return }
        
        if let index = targets.firstIndex(where: { $0.id == target.id }) {
            targets.remove(at: index)
            targetsHit += 1
            
            let points = Int(100 * (target.lifespan - target.age) / target.lifespan)
            score += max(points, 10)
            
            // Haptic feedback
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
    }
    
    private func endGame() {
        gameTimer?.invalidate()
        gameActive = false
        
        let didWin = targetsHit >= requiredHits
        onComplete(didWin, score)
    }
}

struct MovingTarget: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var size: CGFloat
    var lifespan: Double
    var age: Double = 0
    
    var opacity: Double {
        let fadeStart = lifespan * 0.7
        if age > fadeStart {
            return 1.0 - ((age - fadeStart) / (lifespan - fadeStart))
        }
        return 1.0
    }
}

struct TargetView: View {
    let target: MovingTarget
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primaryAccent.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: target.size * 0.3,
                        endRadius: target.size
                    )
                )
                .frame(width: target.size * 1.5, height: target.size * 1.5)
                .scaleEffect(pulse ? 1.2 : 1.0)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primaryAccent,
                            AppColors.primaryAccent.opacity(0.7)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: target.size / 2
                    )
                )
                .frame(width: target.size, height: target.size)
            
            Circle()
                .fill(AppColors.softWhite.opacity(0.3))
                .frame(width: target.size * 0.3, height: target.size * 0.3)
                .offset(x: -target.size * 0.15, y: -target.size * 0.15)
        }
        .opacity(target.opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Shared Game Views
struct DifficultySelectorView: View {
    let game: GameType
    let gameProgress: GameProgress
    let onSelectDifficulty: (Difficulty) -> Void
    let onBack: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - fixed at top
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.softWhite)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 20)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    VStack(spacing: 12) {
                        Image(systemName: game.icon)
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.primaryAccent)
                        
                        Text(game.rawValue)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                        
                        Text(game.description)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.softWhite.opacity(0.6))
                    }
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : -20)
                    
                    VStack(spacing: 16) {
                        Text("Select Difficulty")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.softWhite)
                        
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            let isUnlocked = isDifficultyUnlocked(difficulty)
                            
                            Button(action: {
                                if isUnlocked {
                                    onSelectDifficulty(difficulty)
                                }
                            }) {
                                HStack {
                                    Image(systemName: difficulty.icon)
                                        .font(.system(size: 24))
                                        .foregroundColor(isUnlocked ? difficulty.color : Color.gray)
                                        .frame(width: 50)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(difficulty.rawValue)
                                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                                            .foregroundColor(isUnlocked ? AppColors.softWhite : Color.gray)
                                        
                                        Text("\(gameProgress.completedLevels(for: difficulty))/\(difficulty.levelCount) completed")
                                            .font(.system(size: 13, weight: .medium, design: .rounded))
                                            .foregroundColor(isUnlocked ? AppColors.softWhite.opacity(0.6) : Color.gray.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    if !isUnlocked {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(Color.gray)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.softWhite.opacity(0.5))
                                    }
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity)
                                .cardStyle()
                            }
                            .disabled(!isUnlocked)
                        }
                    }
                    .padding(.horizontal, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 30)
                    
                    Spacer().frame(height: 50)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = true
            }
        }
    }
    
    private func isDifficultyUnlocked(_ difficulty: Difficulty) -> Bool {
        switch difficulty {
        case .calm: return true
        case .focused: return gameProgress.completedLevels(for: .calm) >= 3
        case .intense: return gameProgress.completedLevels(for: .focused) >= 4
        }
    }
}

struct LevelSelectorView: View {
    let game: GameType
    let difficulty: Difficulty
    let gameProgress: GameProgress
    let onSelectLevel: (Int) -> Void
    let onBack: () -> Void
    
    @State private var isVisible = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.softWhite)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softWhite)
                    
                    Text(game.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.softWhite.opacity(0.6))
                }
                
                Spacer()
                
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(1...difficulty.levelCount, id: \.self) { level in
                        let isUnlocked = gameProgress.isLevelUnlocked(difficulty: difficulty, level: level)
                        let isCompleted = gameProgress.levels[difficulty]?[level]?.completed ?? false
                        
                        Button(action: {
                            if isUnlocked {
                                onSelectLevel(level)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        isCompleted ? AppColors.secondaryAccent.opacity(0.2) :
                                        isUnlocked ? Color.white.opacity(0.08) :
                                        Color.gray.opacity(0.1)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(
                                                isCompleted ? AppColors.secondaryAccent.opacity(0.5) :
                                                isUnlocked ? Color.white.opacity(0.15) :
                                                Color.gray.opacity(0.2),
                                                lineWidth: 1
                                            )
                                    )
                                
                                VStack(spacing: 8) {
                                    if isCompleted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppColors.secondaryAccent)
                                    } else if !isUnlocked {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(Color.gray.opacity(0.5))
                                    }
                                    
                                    Text("\(level)")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(
                                            isUnlocked ? AppColors.softWhite :
                                            Color.gray.opacity(0.5)
                                        )
                                }
                            }
                            .frame(height: 90)
                        }
                        .disabled(!isUnlocked)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer().frame(height: 120)
            }
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                isVisible = true
            }
        }
    }
}

struct GameResultView: View {
    let didWin: Bool
    let score: Int
    let onPlayAgain: () -> Void
    let onBack: () -> Void
    
    @State private var isVisible = false
    @State private var iconScale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (didWin ? AppColors.secondaryAccent : AppColors.primaryAccent).opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                
                Image(systemName: didWin ? "trophy.fill" : "arrow.counterclockwise")
                    .font(.system(size: 80))
                    .foregroundColor(didWin ? AppColors.secondaryAccent : AppColors.primaryAccent)
                    .scaleEffect(iconScale)
            }
            
            VStack(spacing: 16) {
                Text(didWin ? "Level Complete!" : "Try Again")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
                
                Text("Score: \(score)")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(didWin ? AppColors.secondaryAccent : AppColors.primaryAccent)
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: onPlayAgain) {
                    Text(didWin ? "Next Level" : "Try Again")
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button(action: onBack) {
                    Text("Back to Levels")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)
            
            Spacer().frame(height: 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                isVisible = true
            }
            
            // Haptic
            if didWin {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

#Preview {
    PrecisionPathGame(userProgress: UserProgress())
}
