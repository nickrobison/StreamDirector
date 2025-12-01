//
//  RoundedRectButton.swift
//  SDKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SwiftUI

public struct RoundedRectButton: ButtonStyle {
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
//            .frame(maxWidth: .infinity)
            .foregroundStyle(.tint)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.tint, lineWidth: 2))
    }
}

extension ButtonStyle where Self == RoundedRectButton {
    public static var roundedRect: Self {
        return .init()
    }
}

struct RoundedRectButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Button("Button 1") {
                
            }
            .buttonStyle(.roundedRect)
            Button("Button 2") {
                
            }
            .buttonStyle(.roundedRect)
            .tint(.pink)
            Button("Button Long One") {
                
            }
            .buttonStyle(.roundedRect)
            .tint(.green)
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
    }
}
