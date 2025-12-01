//
//  CameraView.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/9/25.
//

import SwiftUI
import SDKit
import Prefire

struct CameraView: View {
    let vm: ViewModel
    var body: some View {
        Text(vm.name)
            .font(.title)
        Divider()
        VStack {
            ForEach(vm.presets) { preset in
                PresetButton(preset, vm.preset(isActive: preset), handler: selectPresent)
            }
        }
    }
    
    private func selectPresent(value: CameraPreset) {
        self.vm.selectedPreset = value
    }
}

extension CameraView {
    @Observable
    
    class ViewModel {
        var name: String
        var selectedPreset: CameraPreset?
        var presets: [CameraPreset] = []
        
        init(name: String) {
            self.name = name
        }
        
        convenience init(name: String, presets: [CameraPreset]) {
            self.init(name: name)
            self.presets = presets
        }
        
        func preset(isActive preset: CameraPreset) -> Bool {
            return self.selectedPreset == preset
        }
    }
}

struct CameraView_Previews: PreviewProvider, PrefireProvider {
    
    static let presets = [
        CameraPreset(name: "Home", value: .presetID("1")),
        CameraPreset(name: "Lectern", value: .presetID("2")),
        CameraPreset(name: "Alter", value: .presetID("3")),
        CameraPreset(name: "Entry", value: .presetID("4"))
    ]
    
    static var previews = CameraView(vm: CameraView.ViewModel(name: "Camera 1", presets: presets))
    
}
