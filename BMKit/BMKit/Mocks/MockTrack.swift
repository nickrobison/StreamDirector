//
//  MockTrack.swift
//  BMKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SDKit

// TODO: Get rid of this. Only for previews
struct MockTrack: VideoTrack {
    let name: String
    
    let input: (any SDKit.VideoDevice)?
    
    init(name: String, input: (any SDKit.VideoDevice)?) {
        self.name = name
        self.input = input
    }
}

extension MockTrack: Identifiable {
    var id: String {
        self.name
    }
}
