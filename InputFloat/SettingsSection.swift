//
//  SettingsSection.swift
//  InputFloat
//

import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .opacity(0.8)
     
            content
                .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white)))
        }
        .padding()
        .cornerRadius(8)
    }
}

