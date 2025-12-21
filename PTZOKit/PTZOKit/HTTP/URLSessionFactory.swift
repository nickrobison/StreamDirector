//
//  URLSessionFactory.swift
//  PTZOKit
//
//  Created by Nick Robison on 12/21/25.
//

import Foundation

struct URLSessionFactory {
    private let username: String
    private let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func getSession() -> URLSession {
        let delegate = AuthDelegate(username: self.username, password: self.password)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: .main)
    }
}
