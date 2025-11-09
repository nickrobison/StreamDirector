//
//  PresetView.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/9/25.
//

import SwiftUI

struct PresetView: View {
    
    typealias ClickHandler = (CameraPreset) -> ()
    
    private let preset: CameraPreset
    private let isActive: Bool
    private let color: Color
    private let handle: ClickHandler
    
    init(_ preset: CameraPreset, _ isActive: Bool, handler: @escaping ClickHandler) {
        self.preset = preset
        self.isActive = isActive
        self.color = isActive ? .green : .blue
        self.handle = handler
        
    }
    
    var body: some View {
        Button(preset.name) {
            self.handle(preset)
        }
        .foregroundStyle(self.color)
        .padding()
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(self.color, lineWidth: 2))
        
    }
}

#Preview {
    let preset = CameraPreset(name: "Home", value: .presetID("1"))
    VStack {
        PresetView(preset, false){ pv in
        }
        PresetView(preset, true) { pv in
        }
    }
    
}
