//
//  TrackState.swift
//  BMKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SwiftUI

enum TrackState {
    case program
    case preview
    case none
}

extension TrackState {

    var color: Color {
        switch self {
        case .program:
            .red
        case .preview:
            .green
        case .none:
            .accentColor
        }
    }
}
