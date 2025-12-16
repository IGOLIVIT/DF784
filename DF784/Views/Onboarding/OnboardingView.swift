//
//  OnboardingView.swift
//  DF784
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var userProgress: UserProgress
    @State private var currentPage = 0
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            AnimatedBackgroundView()
            
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "flame.fill",
                        title: "Master Your Focus",
                        description: "Embark on a journey of precision and mindfulness. Each challenge refines your skills and strengthens your inner calm.",
                        pageIndex: 0
                    )
                    .tag(0)
                    
                    OnboardingPage(
                        icon: "sparkles",
                        title: "Progress Through Balance",
                        description: "Every level you complete builds your energy. Every pattern you recognize unlocks new stages of mastery.",
                        pageIndex: 1
                    )
                    .tag(1)
                    
                    OnboardingPage(
                        icon: "trophy.fill",
                        title: "Achieve True Mastery",
                        description: "Three unique challenges await. Timing, recognition, and balance — master them all to reach your full potential.",
                        pageIndex: 2
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 10) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(currentPage == index ? AppColors.primaryAccent : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Continue button (only on last page)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        userProgress.hasCompletedOnboarding = true
                        userProgress.save()
                    }
                }) {
                    Text("Continue")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
                .opacity(currentPage == 2 ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                Spacer().frame(height: 50)
            }
            .padding(.top, 60)
        }
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                isVisible = true
            }
        }
    }
}

struct OnboardingPage: View {
    let icon: String
    let title: String
    let description: String
    let pageIndex: Int
    
    @State private var isVisible = false
    @State private var iconScale: CGFloat = 0.5
    @State private var glowAmount: CGFloat = 0.3
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 40) {
                Spacer(minLength: 40)
                
                // Animated icon container
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.primaryAccent.opacity(glowAmount * 0.4),
                                    AppColors.primaryAccent.opacity(glowAmount * 0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                    
                    // Icon background circle
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
                        .frame(width: 140, height: 140)
                        .overlay(
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
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                        iconScale = 1.0
                    }
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        glowAmount = 0.6
                    }
                }
                
                VStack(spacing: 20) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.softWhite)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                    
                    Text(description)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(AppColors.softWhite.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 15)
                }
                
                Spacer(minLength: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
            iconScale = 0.5
        }
    }
}

#Preview {
    OnboardingView(userProgress: UserProgress())
}

