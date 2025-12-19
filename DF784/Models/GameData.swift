//
//  GameData.swift
//  DF784
//

import Foundation
import SwiftUI
import Combine

// MARK: - Difficulty Levels
enum Difficulty: String, CaseIterable, Codable {
    case calm = "Calm"
    case focused = "Focused"
    case intense = "Intense"
    
    var levelCount: Int {
        switch self {
        case .calm: return 5
        case .focused: return 7
        case .intense: return 10
        }
    }
    
    var color: Color {
        switch self {
        case .calm: return Color("SecondaryAccent")
        case .focused: return Color("PrimaryAccent")
        case .intense: return Color("PrimaryAccent").opacity(0.8)
        }
    }
    
    var icon: String {
        switch self {
        case .calm: return "leaf.fill"
        case .focused: return "flame.fill"
        case .intense: return "bolt.fill"
        }
    }
}

// MARK: - Game Types
enum GameType: String, CaseIterable, Codable {
    case precisionPath = "Precision Path"
    case patternFlow = "Pattern Flow"
    case balanceTrial = "Balance Trial"
    
    var description: String {
        switch self {
        case .precisionPath: return "Accuracy and timing"
        case .patternFlow: return "Pattern recognition"
        case .balanceTrial: return "Controlled decisions"
        }
    }
    
    var icon: String {
        switch self {
        case .precisionPath: return "scope"
        case .patternFlow: return "square.grid.3x3.fill"
        case .balanceTrial: return "scale.3d"
        }
    }
}

// MARK: - Level Progress
struct LevelProgress: Codable {
    var completed: Bool = false
    var bestScore: Int = 0
    var attempts: Int = 0
}

// MARK: - Game Progress
struct GameProgress: Codable {
    var levels: [Difficulty: [Int: LevelProgress]]
    
    init() {
        levels = [:]
        for difficulty in Difficulty.allCases {
            levels[difficulty] = [:]
            for level in 1...difficulty.levelCount {
                levels[difficulty]![level] = LevelProgress()
            }
        }
    }
    
    func completedLevels(for difficulty: Difficulty) -> Int {
        return levels[difficulty]?.values.filter { $0.completed }.count ?? 0
    }
    
    func totalCompletedLevels() -> Int {
        return Difficulty.allCases.reduce(0) { $0 + completedLevels(for: $1) }
    }
    
    func isLevelUnlocked(difficulty: Difficulty, level: Int) -> Bool {
        if level == 1 {
            switch difficulty {
            case .calm: return true
            case .focused: return completedLevels(for: .calm) >= 3
            case .intense: return completedLevels(for: .focused) >= 4
            }
        }
        return levels[difficulty]?[level - 1]?.completed ?? false
    }
    
    mutating func completeLevel(difficulty: Difficulty, level: Int, score: Int) {
        if levels[difficulty] == nil {
            levels[difficulty] = [:]
        }
        var progress = levels[difficulty]![level] ?? LevelProgress()
        progress.completed = true
        progress.bestScore = max(progress.bestScore, score)
        progress.attempts += 1
        levels[difficulty]![level] = progress
    }
    
    mutating func addAttempt(difficulty: Difficulty, level: Int) {
        if levels[difficulty] == nil {
            levels[difficulty] = [:]
        }
        var progress = levels[difficulty]![level] ?? LevelProgress()
        progress.attempts += 1
        levels[difficulty]![level] = progress
    }
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    var unlocked: Bool = false
    var unlockedDate: Date?
    
    static let all: [Achievement] = [
        Achievement(id: "first_step", title: "First Step", description: "Complete your first level"),
        Achievement(id: "calm_master", title: "Calm Master", description: "Complete all Calm levels in any game"),
        Achievement(id: "focused_adept", title: "Focused Adept", description: "Complete all Focused levels in any game"),
        Achievement(id: "intense_warrior", title: "Intense Warrior", description: "Complete all Intense levels in any game"),
        Achievement(id: "precision_expert", title: "Precision Expert", description: "Complete 10 levels in Precision Path"),
        Achievement(id: "pattern_seer", title: "Pattern Seer", description: "Complete 10 levels in Pattern Flow"),
        Achievement(id: "balance_keeper", title: "Balance Keeper", description: "Complete 10 levels in Balance Trial"),
        Achievement(id: "triple_crown", title: "Triple Crown", description: "Complete at least one level in each game"),
        Achievement(id: "dedication", title: "Dedication", description: "Play 50 levels total"),
        Achievement(id: "mastery", title: "True Mastery", description: "Complete all levels in all games")
    ]
}

// MARK: - User Progress
class UserProgress: ObservableObject, Codable {
    @Published var hasCompletedOnboarding: Bool = false
    @Published var gameProgress: [GameType: GameProgress] = [:]
    @Published var achievements: [Achievement] = Achievement.all
    @Published var totalGamesPlayed: Int = 0
    @Published var energyLevel: Int = 1
    @Published var currentStage: Int = 1
    
    enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case gameProgress
        case achievements
        case totalGamesPlayed
        case energyLevel
        case currentStage
    }
    
    init() {
        for gameType in GameType.allCases {
            gameProgress[gameType] = GameProgress()
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasCompletedOnboarding = (try? container.decode(Bool.self, forKey: .hasCompletedOnboarding)) ?? false
        gameProgress = (try? container.decode([GameType: GameProgress].self, forKey: .gameProgress)) ?? {
            var progress: [GameType: GameProgress] = [:]
            for gameType in GameType.allCases {
                progress[gameType] = GameProgress()
            }
            return progress
        }()
        achievements = (try? container.decode([Achievement].self, forKey: .achievements)) ?? Achievement.all
        totalGamesPlayed = (try? container.decode(Int.self, forKey: .totalGamesPlayed)) ?? 0
        energyLevel = (try? container.decode(Int.self, forKey: .energyLevel)) ?? 1
        currentStage = (try? container.decode(Int.self, forKey: .currentStage)) ?? 1
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hasCompletedOnboarding, forKey: .hasCompletedOnboarding)
        try container.encode(gameProgress, forKey: .gameProgress)
        try container.encode(achievements, forKey: .achievements)
        try container.encode(totalGamesPlayed, forKey: .totalGamesPlayed)
        try container.encode(energyLevel, forKey: .energyLevel)
        try container.encode(currentStage, forKey: .currentStage)
    }
    
    var totalCompletedLevels: Int {
        gameProgress.values.reduce(0) { $0 + $1.totalCompletedLevels() }
    }
    
    var unlockedAchievements: Int {
        achievements.filter { $0.unlocked }.count
    }
    
    func calculateEnergyLevel() -> Int {
        let completed = totalCompletedLevels
        if completed >= 50 { return 10 }
        if completed >= 40 { return 9 }
        if completed >= 32 { return 8 }
        if completed >= 25 { return 7 }
        if completed >= 19 { return 6 }
        if completed >= 14 { return 5 }
        if completed >= 10 { return 4 }
        if completed >= 6 { return 3 }
        if completed >= 3 { return 2 }
        return 1
    }
    
    func calculateStage() -> Int {
        let unlocked = unlockedAchievements
        if unlocked >= 8 { return 5 }
        if unlocked >= 6 { return 4 }
        if unlocked >= 4 { return 3 }
        if unlocked >= 2 { return 2 }
        return 1
    }
    
    func updateProgress() {
        energyLevel = calculateEnergyLevel()
        currentStage = calculateStage()
        checkAchievements()
        save()
    }
    
    func completeLevel(game: GameType, difficulty: Difficulty, level: Int, score: Int) {
        gameProgress[game]?.completeLevel(difficulty: difficulty, level: level, score: score)
        totalGamesPlayed += 1
        updateProgress()
    }
    
    func addAttempt(game: GameType, difficulty: Difficulty, level: Int) {
        gameProgress[game]?.addAttempt(difficulty: difficulty, level: level)
        totalGamesPlayed += 1
        save()
    }
    
    private func checkAchievements() {
        // First Step
        if totalCompletedLevels >= 1 {
            unlockAchievement("first_step")
        }
        
        // Calm Master
        for game in GameType.allCases {
            if gameProgress[game]?.completedLevels(for: .calm) == Difficulty.calm.levelCount {
                unlockAchievement("calm_master")
                break
            }
        }
        
        // Focused Adept
        for game in GameType.allCases {
            if gameProgress[game]?.completedLevels(for: .focused) == Difficulty.focused.levelCount {
                unlockAchievement("focused_adept")
                break
            }
        }
        
        // Intense Warrior
        for game in GameType.allCases {
            if gameProgress[game]?.completedLevels(for: .intense) == Difficulty.intense.levelCount {
                unlockAchievement("intense_warrior")
                break
            }
        }
        
        // Game-specific achievements
        if gameProgress[.precisionPath]?.totalCompletedLevels() ?? 0 >= 10 {
            unlockAchievement("precision_expert")
        }
        if gameProgress[.patternFlow]?.totalCompletedLevels() ?? 0 >= 10 {
            unlockAchievement("pattern_seer")
        }
        if gameProgress[.balanceTrial]?.totalCompletedLevels() ?? 0 >= 10 {
            unlockAchievement("balance_keeper")
        }
        
        // Triple Crown
        let hasPlayedAll = GameType.allCases.allSatisfy { game in
            (gameProgress[game]?.totalCompletedLevels() ?? 0) >= 1
        }
        if hasPlayedAll {
            unlockAchievement("triple_crown")
        }
        
        // Dedication
        if totalGamesPlayed >= 50 {
            unlockAchievement("dedication")
        }
        
        // True Mastery
        let totalPossible = GameType.allCases.count * Difficulty.allCases.reduce(0) { $0 + $1.levelCount }
        if totalCompletedLevels >= totalPossible {
            unlockAchievement("mastery")
        }
    }
    
    private func unlockAchievement(_ id: String) {
        if let index = achievements.firstIndex(where: { $0.id == id && !$0.unlocked }) {
            achievements[index].unlocked = true
            achievements[index].unlockedDate = Date()
        }
    }
    
    func reset() {
        hasCompletedOnboarding = false
        gameProgress = [:]
        for gameType in GameType.allCases {
            gameProgress[gameType] = GameProgress()
        }
        achievements = Achievement.all
        totalGamesPlayed = 0
        energyLevel = 1
        currentStage = 1
        save()
    }
    
    // MARK: - Persistence
    private static let saveKey = "UserProgress"
    
    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: Self.saveKey)
        }
    }
    
    static func load() -> UserProgress {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else {
            return UserProgress()
        }
        do {
            let decoded = try JSONDecoder().decode(UserProgress.self, from: data)
            return decoded
        } catch {
            // If decoding fails, clear corrupted data and return fresh instance
            UserDefaults.standard.removeObject(forKey: saveKey)
            return UserProgress()
        }
    }
}

