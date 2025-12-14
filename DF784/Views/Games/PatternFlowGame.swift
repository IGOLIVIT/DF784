//
//  PatternFlowGame.swift
//  DF784
//

import SwiftUI

struct PatternFlowGame: View {
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
                PatternFlowGameplay(
                    difficulty: difficulty,
                    level: level,
                    onComplete: { won, finalScore in
                        didWin = won
                        score = finalScore
                        if won {
                            userProgress.completeLevel(game: .patternFlow, difficulty: difficulty, level: level, score: finalScore)
                        } else {
                            userProgress.addAttempt(game: .patternFlow, difficulty: difficulty, level: level)
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
                    game: .patternFlow,
                    difficulty: difficulty,
                    gameProgress: userProgress.gameProgress[.patternFlow] ?? GameProgress(),
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
                    game: .patternFlow,
                    gameProgress: userProgress.gameProgress[.patternFlow] ?? GameProgress(),
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

// MARK: - Pattern Flow Gameplay
struct PatternFlowGameplay: View {
    let difficulty: Difficulty
    let level: Int
    let onComplete: (Bool, Int) -> Void
    let onExit: () -> Void
    
    @State private var gridSize: Int = 3
    @State private var pattern: [Int] = []
    @State private var userPattern: [Int] = []
    @State private var isShowingPattern = true
    @State private var currentShowIndex = 0
    @State private var score = 0
    @State private var round = 1
    @State private var totalRounds = 3
    @State private var isInputEnabled = false
    @State private var highlightedCell: Int? = nil
    @State private var showCountdown = true
    @State private var countdownValue = 3
    @State private var timer: Timer?
    @State private var isCorrect: Bool? = nil
    @State private var isPaused = false
    
    private var patternLength: Int {
        let base: Int
        switch difficulty {
        case .calm: base = 3
        case .focused: base = 4
        case .intense: base = 5
        }
        return base + level - 1 + (round - 1)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // HUD
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Round \(round)/\(totalRounds)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("Score: \(score)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .foregroundColor(AppColors.softWhite)
                
                Spacer()
                
                PauseButton {
                    isPaused = true
                }
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Level \(level)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text(difficulty.rawValue)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(difficulty.color)
                }
                .foregroundColor(AppColors.softWhite)
            }
            .padding(.horizontal, 20)
            .padding(.top, 70)
            
            Spacer()
            
            // Status text
            Text(isShowingPattern ? "Watch the pattern..." : "Repeat the pattern!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.softWhite)
                .opacity(showCountdown ? 0 : 1)
            
            // Grid
            VStack(spacing: 12) {
                ForEach(0..<gridSize, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            let index = row * gridSize + col
                            PatternCell(
                                index: index,
                                isHighlighted: highlightedCell == index,
                                isSelected: userPattern.contains(index),
                                isCorrect: isCorrect,
                                isInputEnabled: isInputEnabled,
                                onTap: {
                                    cellTapped(index)
                                }
                            )
                        }
                    }
                }
            }
            .padding(20)
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<patternLength, id: \.self) { index in
                    Circle()
                        .fill(
                            index < userPattern.count ?
                            (isCorrect == true ? AppColors.secondaryAccent :
                             isCorrect == false ? AppColors.primaryAccent :
                             AppColors.softWhite) :
                            Color.white.opacity(0.2)
                        )
                        .frame(width: 10, height: 10)
                }
            }
            .opacity(showCountdown ? 0 : 1)
            
            Spacer()
        }
        .overlay(
            Group {
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
                
                if isPaused {
                    PauseMenuView(
                        onResume: {
                            isPaused = false
                        },
                        onExit: {
                            timer?.invalidate()
                            onExit()
                        }
                    )
                }
            }
        )
        .onAppear {
            setupGrid()
            startCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func setupGrid() {
        switch difficulty {
        case .calm: gridSize = 3
        case .focused: gridSize = 4
        case .intense: gridSize = 4
        }
        
        if difficulty == .intense && level > 5 {
            gridSize = 5
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
                startRound()
            }
        }
    }
    
    private func startRound() {
        generatePattern()
        showPattern()
    }
    
    private func generatePattern() {
        pattern = []
        let totalCells = gridSize * gridSize
        var usedIndices: Set<Int> = []
        
        for _ in 0..<patternLength {
            var newIndex: Int
            repeat {
                newIndex = Int.random(in: 0..<totalCells)
            } while usedIndices.contains(newIndex) && usedIndices.count < totalCells
            
            pattern.append(newIndex)
            usedIndices.insert(newIndex)
        }
    }
    
    private func showPattern() {
        isShowingPattern = true
        isInputEnabled = false
        currentShowIndex = 0
        userPattern = []
        isCorrect = nil
        
        showNextInPattern()
    }
    
    private func showNextInPattern() {
        if currentShowIndex >= pattern.count {
            // Pattern shown, enable input
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isShowingPattern = false
                isInputEnabled = true
            }
            return
        }
        
        highlightedCell = pattern[currentShowIndex]
        
        let delay: Double
        switch difficulty {
        case .calm: delay = 0.8
        case .focused: delay = 0.6
        case .intense: delay = 0.4
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay * 0.6) {
            highlightedCell = nil
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * 0.4) {
                currentShowIndex += 1
                showNextInPattern()
            }
        }
    }
    
    private func cellTapped(_ index: Int) {
        guard isInputEnabled else { return }
        
        userPattern.append(index)
        
        // Haptic
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Check if this tap is correct
        let currentIndex = userPattern.count - 1
        if pattern[currentIndex] != index {
            // Wrong!
            isCorrect = false
            isInputEnabled = false
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete(false, score)
            }
            return
        }
        
        // Check if pattern complete
        if userPattern.count == pattern.count {
            isCorrect = true
            isInputEnabled = false
            
            let roundScore = patternLength * 50
            score += roundScore
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            if round >= totalRounds {
                // Game complete!
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete(true, score)
                }
            } else {
                // Next round
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    round += 1
                    isCorrect = nil
                    startRound()
                }
            }
        }
    }
}

struct PatternCell: View {
    let index: Int
    let isHighlighted: Bool
    let isSelected: Bool
    let isCorrect: Bool?
    let isInputEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 12)
                .fill(cellColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(isHighlighted ? 1.1 : 1.0)
                .animation(.spring(response: 0.3), value: isHighlighted)
        }
        .disabled(!isInputEnabled)
    }
    
    private var cellColor: Color {
        if isHighlighted {
            return AppColors.primaryAccent
        }
        if isSelected {
            if isCorrect == true {
                return AppColors.secondaryAccent.opacity(0.6)
            } else if isCorrect == false {
                return AppColors.primaryAccent.opacity(0.6)
            }
            return AppColors.softWhite.opacity(0.3)
        }
        return Color.white.opacity(0.08)
    }
    
    private var borderColor: Color {
        if isHighlighted {
            return AppColors.primaryAccent
        }
        if isSelected {
            return Color.white.opacity(0.3)
        }
        return Color.white.opacity(0.1)
    }
}

#Preview {
    PatternFlowGame(userProgress: UserProgress())
}
