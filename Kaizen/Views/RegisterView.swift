//
//  RegisterView.swift
//  Kaizen
//
//  Created by Sean Green on 08/09/2026.
//

import SwiftUI

struct RegisterView: View {
    
    @EnvironmentObject var viewModel : AuthViewModel
    @State private var email = ""
    @State private var fullname = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.dismiss) var dismiss
    
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
                    
                    InputView(text: $fullname,
                              title: "Full Name",
                              plcaeholder: "Joe Bloggs")
                    .autocapitalization(.words)
                    
                    InputView(text: $password,
                              title: "Password",
                              plcaeholder: "Enter Your Password",
                              isSecureField: true)
                    
                    InputView(text: $confirmPassword,
                              title: "Confirm Password",
                              plcaeholder: "Confirm Your Password",
                              isSecureField: true)
                        
                    
                }
                .padding(.horizontal)
                .padding(.top, 12)
                }
                
                //Register button
            
            Button {
                Task{
                    await viewModel.register(
                        email: email,
                        password: password,
                        confirmPassword: confirmPassword
                    )
                }
            } label: {
                HStack{
                    Text("REGISTER")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width:UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color(.systemBlue))
            .cornerRadius(10)
            .padding(.top, 24)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
                
                Spacer()
                
                
                //sign in button
                
            Button {
                dismiss()
            } label: {
                HStack(spacing: 2) {
                    Text("Already have an account?")
                    Text("Sign In")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
            
            }
        }
    }


#Preview {
    RegisterView()
}
