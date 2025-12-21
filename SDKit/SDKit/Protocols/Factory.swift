//
//  Factory.swift
//  SDKit
//
//  Created by Nick Robison on 12/21/25.
//

import Foundation

public protocol Factory {
    associatedtype Value
    associatedtype Args
    
    func create(_ args: Args) -> Value
}
