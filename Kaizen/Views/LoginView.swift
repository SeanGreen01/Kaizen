//
//  LoginView.swift
//  Kaizen
//
//  Created by Sean Green on 08/09/2026.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel : AuthViewModel
    @State private var email = ""
    @State private var password = ""
    var body: some View {
        NavigationStack {
            VStack{
                // image
                Image("Kaizen-2")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 120)
                    .padding(.vertical, 32)
                
                
                
                //form fields
                
                VStack(spacing: 24) {
                    InputView(text: $email,
                              title: "Email Address",
                              plcaeholder: "name@example.com")
                    .autocapitalization(.none)
                    
                    InputView(text: $password,
                              title: "Password",
                              plcaeholder: "Enter Your Password",
                              isSecureField: true)
                        
                    
                }
                .padding(.horizontal)
                .padding(.top, 12)
                }
                
                //Register button
            
            Button {
                Task{
                    await viewModel.login(
                        email: email,
                        password: password
                    )
                }
            } label: {
                HStack{
                    Text("SIGN IN")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width:UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color(.systemBlue))
            .cornerRadius(10)
            .padding(.top, 24)
                
                Spacer()
                
                
                //sign in button
                
            NavigationLink {
                RegisterView()
                    .navigationBarBackButtonHidden(true)
            } label: {
                HStack(spacing: 2) {
                    Text("Don't have an account?")
                    Text("Register")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
            
            }
        }
    }
    

#Preview {
    LoginView()
}
