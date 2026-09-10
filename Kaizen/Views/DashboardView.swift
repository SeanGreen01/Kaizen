//
//  DashboardView.swift
//  Kaizen
//
//  Created by Sean Green on 09/09/2026.
//

import SwiftUI

struct DashboardView: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                Text("Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome to Kaizen")
                    .font(.title3)
                
                Spacer()
                
                Button("Sign Out") {
                    viewModel.logout()
                }
                .foregroundStyle(.red)
            }
            .padding()
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(AuthViewModel())
}
