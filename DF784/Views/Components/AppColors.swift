//
//  AppColors.swift
//  DF784
//

import SwiftUI

struct AppColors {
    static let primaryBackground = Color("PrimaryBackground")
    static let primaryAccent = Color("PrimaryAccent")
    static let secondaryAccent = Color("SecondaryAccent")
    static let softWhite = Color("SoftWhite")
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                primaryBackground,
                primaryBackground.opacity(0.95),
                Color(red: 0.12, green: 0.05, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [primaryAccent, primaryAccent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var secondaryGradient: LinearGradient {
        LinearGradient(
            colors: [secondaryAccent, secondaryAccent.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Animated Background View
struct AnimatedBackgroundView: View {
    @State private var animate = false
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // Animated glow orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primaryAccent.opacity(0.15),
                            AppColors.primaryAccent.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? 50 : -50, y: animate ? -100 : -150)
                .opacity(glowOpacity)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.secondaryAccent.opacity(0.1),
                            AppColors.secondaryAccent.opacity(0.03),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: animate ? -80 : -30, y: animate ? 200 : 250)
                .opacity(glowOpacity * 0.8)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.primaryAccent.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: animate ? 100 : 150, y: animate ? 100 : 50)
                .opacity(glowOpacity * 0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowOpacity = 0.5
            }
        }
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.softWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? AppColors.accentGradient : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .leading, endPoint: .trailing))
                    .shadow(color: isEnabled ? AppColors.primaryAccent.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(AppColors.softWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppColors.secondaryGradient)
                    .shadow(color: AppColors.secondaryAccent.opacity(0.3), radius: 6, x: 0, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
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
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var primaryColor: Color = AppColors.primaryAccent
    var secondaryColor: Color = AppColors.secondaryAccent
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    AngularGradient(
                        colors: [primaryColor, secondaryColor, primaryColor],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Pause Menu
struct PauseMenuView: View {
    let onResume: () -> Void
    let onExit: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { }
            
            VStack(spacing: 30) {
                // Pause icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppColors.primaryAccent.opacity(0.3),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.primaryAccent)
                }
                
                Text("Paused")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.softWhite)
                
                VStack(spacing: 16) {
                    Button(action: onResume) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    Button(action: onExit) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Exit Game")
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, 40)
            }
            .scaleEffect(isVisible ? 1 : 0.8)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Pause Button
struct PauseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "pause.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.softWhite)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

