//
//  VideoDevice.swift
//  SDKit
//
//  Created by Nick Robison on 11/9/25.
//

import Foundation
import SwiftUI

public protocol VideoDevice: Identifiable, Sendable {
    associatedtype Body: View
    @ViewBuilder func makeController() -> Self.Body
}
