//
//  WebAppLoadingView.swift
//  WebAppWrapper
//
//  Created by CB on 19/1/2025.
//

import SwiftUI

struct WebAppLoadingView: View {
    @State private var isAnimating = false
    @State private var progress: CGFloat = 0
    @State private var logoScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            VStack {
                GeometryReader { gm in
                    VStack {
                        Spacer()
                        Image("app-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 110, height: 110)
                            .scaleEffect(logoScale)
                            .rotationEffect(Angle(degrees: isAnimating ? 0 : -90))
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: gm.size.width, height: 4)
                                .opacity(0.3)
                                .foregroundStyle(.gray)
                            
                            Rectangle()
                                .frame(width: gm.size.width * progress, height: 4)
                                .foregroundStyle(.black)
                        }
                        .frame(height: 60)
                        
                        Spacer()
                    }
                    
                }
            }
            .padding(.horizontal, 10)
        }
        .onAppear {
            // logo animation
            withAnimation(.spring(response: 0.7, dampingFraction: 0.3)) {
                logoScale = 1
            }
            
            // rotation
            withAnimation(.linear(duration: 1)) {
                isAnimating = true
            }
            
            // progress bar
            withAnimation(.linear(duration: 2)) {
                progress = 1
            }
        }
    }
}

#Preview {
    WebAppLoadingView()
}
