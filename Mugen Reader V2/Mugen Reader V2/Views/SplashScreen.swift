//
//  splashView.swift
//  Mugen Reader V2
//
//  Created by  User on 17.05.2025.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            NavigationView{
                ContentViewListViewOnly()
            }
        } else {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    Spacer()
                    
                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .shadow(radius: 10)
                    
                    VStack(spacing: 15) {
                        Text("Mugen Reader V2")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Text("Luong - Luan - Quoc - Huy")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.isActive = true
                        }
                    }) {
                        Text("Bắt đầu")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
    }
}

