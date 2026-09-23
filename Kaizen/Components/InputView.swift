//
//  InputView.swift
//  Kaizen
//
//  Created by Sean Green on 08/09/2026.
//

import SwiftUI

struct InputView: View {
    @Binding var text: String
    let title: String
    let plcaeholder: String
    var isSecureField: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12){
            Text(title)
                .foregroundStyle(KaizenTheme.muted)
                .fontWeight(.semibold)
                .font(.footnote)
            
            if isSecureField{
                SecureField(plcaeholder, text: $text)
                    .font(.system(size: 14))
                        
                    
            } else {
                TextField(plcaeholder, text: $text)
                    .font(.system(size: 14))
            }
            
            Divider()
            }
        }
    }


#Preview {
    InputView(text: .constant(""), title: "Email Address", plcaeholder: "name@example.com")
}
