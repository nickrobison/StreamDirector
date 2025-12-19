//
//  RoundedRectButton.swift
//  SDKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SwiftUI

public struct RoundedRectButton: ButtonStyle {
    
    let maxWidth: CGFloat?
    
    init(fullWidth: Bool) {
        self.maxWidth = fullWidth ? .infinity : nil
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: maxWidth)
            .foregroundStyle(.tint)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.tint, lineWidth: 2))
    }
}

extension ButtonStyle where Self == RoundedRectButton {
    public static var roundedRect: Self {
        return .init(fullWidth: false)
    }
    
    public static var fullWidthRoundedRect: Self {
        return .init(fullWidth: true)
    }
    
    public static func roundedRect(fullWidth: Bool = false) -> Self {
        .init(fullWidth: fullWidth)
    }
    
}

struct RoundedRectButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button("Button 1") {
                
            }
            .buttonStyle(.roundedRect(fullWidth: true))
            Button("Button 2") {
                
            }
            .buttonStyle(.roundedRect)
            .tint(.pink)
            Button("Button Long One") {
                
            }
            .buttonStyle(.roundedRect(fullWidth: false))
            .tint(.green)
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
    }
}
