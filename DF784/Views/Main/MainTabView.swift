//
//  MainTabView.swift
//  DF784
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var userProgress: UserProgress
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                JourneyView(userProgress: userProgress)
                    .tag(0)
                
                GamesHubView(userProgress: userProgress)
                    .tag(1)
                
                SettingsView(userProgress: userProgress)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs: [(icon: String, label: String)] = [
        ("flame.fill", "Journey"),
        ("gamecontroller.fill", "Games"),
        ("gearshape.fill", "Settings")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 22, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? AppColors.primaryAccent : AppColors.softWhite.opacity(0.5))
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                        
                        Text(tabs[index].label)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTab == index ? AppColors.primaryAccent : AppColors.softWhite.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.primaryBackground.opacity(0.98),
                            AppColors.primaryBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    MainTabView(userProgress: UserProgress())
}

