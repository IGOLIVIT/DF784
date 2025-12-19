//
//  ContentView.swift
//  DF784
//
//  Created by IGOR on 13/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var userProgress: UserProgress
    @State private var isLoading = true
    @State private var hasAppeared = false
    
    init() {
        _userProgress = StateObject(wrappedValue: UserProgress.load())
    }
    
    var body: some View {
        ZStack {
            // Always show background to prevent blank screen
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            if isLoading {
                SplashView()
                    .transition(.opacity)
            } else if !userProgress.hasCompletedOnboarding {
                OnboardingView(userProgress: userProgress)
                    .transition(.opacity)
            } else {
                MainTabView(userProgress: userProgress)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isLoading)
        .animation(.easeInOut(duration: 0.5), value: userProgress.hasCompletedOnboarding)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            
            // Simulate brief loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var glowAmount: CGFloat = 0.3
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Animated glow background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primaryAccent.opacity(glowAmount * 0.5),
                            AppColors.primaryAccent.opacity(glowAmount * 0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
            
            VStack(spacing: 20) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.primaryAccent.opacity(0.5),
                                    AppColors.secondaryAccent.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(glowAmount + 0.7)
                        .opacity(0.5)
                    
                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    // Icon
                    Image(systemName: "flame.fill")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowAmount = 0.6
            }
        }
    }
}

#Preview {
    ContentView()
}
