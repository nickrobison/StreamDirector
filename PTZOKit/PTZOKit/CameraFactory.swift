//
//  CameraFactory.swift
//  PTZOKit
//
//  Created by Nick Robison on 12/21/25.
//

import Foundation
import SDKit

struct CameraFactory<C: APIProtocol> {
    
    typealias Value = PTZOCamera<C>
    typealias Args = CameraRecord
    
    var sessionFactory: URLSessionFactory
    var clientFactory: any ClientFactory<C>
    var clock: any Clock<Duration>
    
    func create(_ record: CameraRecord) -> PTZOCamera<C> {
        let url = URL(string: "http://\(record.hostname):\(record.port)")!
        let delegate = AuthDelegate(username: record.configuration.username, password: record.configuration.password)
        // TODO: Which queue to use?
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: .main)
        
        let client = clientFactory.create((url, session))
        return PTZOCamera(name: record.name, client: client, clock: clock)
    }

    
}
