//
//  RootView.swift
//  Kaizen
//
//  Created by Sean Green on 09/09/2026.
//

import SwiftUI

struct RootView: View {
    
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        if viewModel.currentUser != nil {
            DashboardView()
        } else {
            WelcomeView()
        }
    }
}

