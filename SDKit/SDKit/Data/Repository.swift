//
//  Repository.swift
//  SDKit
//
//  Created by Nick Robison on 11/26/25.
//

import Foundation

public protocol Repository: Sendable {
    associatedtype Entity: Sendable & Identifiable where Entity.ID: Sendable
    
    func create(_ entity: Entity) async throws -> Entity
    func get(by id: Entity.ID) async throws -> Entity?
    func delete(by id: Entity.ID) async throws
    func list() async throws -> [Entity]
}
