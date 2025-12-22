//
//  CameraView.swift
//  PTZOKit
//
//  Created by Nick Robison on 11/9/25.
//

import SwiftUI
import SDKit
import Prefire
import Clocks

struct CameraView<C: APIProtocol>: View {
    typealias Camera = PTZOCamera<C>
    var camera: Camera
    
    var body: some View {
        Text("Hello")
            .font(.title)
        Divider()
        Text("Presets?")
        PresetView<Camera>(handler: camera)
    }
    
//    private func selectPresent(value: CameraPreset) {
//        self.vm.selectedPreset = value
//    }
}

struct CameraView_Previews: PreviewProvider, PrefireProvider {
    private static let clock = TestClock()
    
    static var camera: PTZOCamera<MockClient> {
        let client = MockClient()
        
        return PTZOCamera(name:" Test", client: client, clock: clock)
    }
    
    static var previews = CameraView(camera: camera)
    
}
