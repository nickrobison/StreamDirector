//
//  MockDevice.swift
//  BMKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SDKit
import SwiftUI

struct MockDevice: VideoDevice {
    
    let name: String
    func makeController() -> some View {
        MockDeviceController()
    }
    
    
}

extension MockDevice: Identifiable {
    var id: String {
        self.name
    }
    
    
}

struct MockDeviceController: View {
    
    var body: some View {
        Text("I'm a device controller")
    }
}
