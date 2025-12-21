//
//  ClientFactory.swift
//  PTZOKit
//
//  Created by Nick Robison on 12/21/25.
//

import Foundation
import SDKit
import OpenAPIURLSession

protocol ClientFactory<C>: Factory where Value == C, Args == (URL, URLSession)  {
    associatedtype C: APIProtocol
}

struct ClientFactoryImpl: ClientFactory {
    typealias C = Client
    
    func create(_ args: (URL, URLSession)) -> Client {
        let (url, session) = args
        let config = URLSessionTransport.Configuration(session: session)
        let transport = URLSessionTransport(configuration: config)
        let client = Client(serverURL: url, transport: transport)
        return client
    }
    
}

