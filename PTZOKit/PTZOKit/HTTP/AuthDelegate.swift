//
//  AuthDelegate.swift
//  PTZOKit
//
//  Created by Nick Robison on 12/21/25.
//

import Foundation

final class AuthDelegate: NSObject, URLSessionTaskDelegate {
    private let username: String
    private let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
        super.init()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let authMethod = challenge.protectionSpace.authenticationMethod
        guard authMethod == NSURLAuthenticationMethodHTTPDigest else {
            return (.performDefaultHandling, nil)
        }
        
        let credential = URLCredential(user: self.username, password: self.password, persistence: .forSession)
        
        return (.useCredential, credential)
        
    }
}
