//
//  ContentView.swift
//  Kaizen
//
//  Created by Sean Green on 24/08/2026.
//

import SwiftUI

struct WelcomeView: View {
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            // MARK: Background
            
            ZStack{
                
            }
            
            // MARK: Content
            VStack (alignment: .center, spacing: 32) {
                // App Name
                Text("Kaizen")
                    
                    .font(.largeTitle)
                    .fontWeight(.heavy)
            
                // Slogan
                Text("The future of productivity is here.")
                    .font(.title2)
                    .fontWeight(.heavy)
                
                // Get Started Button
                Button(
                    action: {
                        
                    },
                    label:  {
                        Text("Get Started")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding()
                            .foregroundStyle(.white)
                            .background(.gray)
                            
                    }
                    )
                    }
        }
    }
}

#Preview {
    WelcomeView()
}
