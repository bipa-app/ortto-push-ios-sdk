//
//  PreferencesManager.swift
//  
//
//  Created by Mitch Flindell on 25/11/2022.
//

import Foundation

public class PreferencesManager {
    
    private var defaults: UserDefaults
    
    public var sessionID: String?
    
    public var user: UserIdentifier?
    
    public init () {
        defaults = UserDefaults.standard
        sessionID = defaults.string(forKey: "sessionID")
        
        if let encodedUser = defaults.object(forKey: "user") as? Data {
            let decoder = JSONDecoder()
            if let loadedUser = try? decoder.decode(UserIdentifier.self, from: encodedUser) {
                print(loadedUser.email!)
                self.user = loadedUser
            }
        }
    }
    
    public func setSessionID(_ sessionID: String) -> Void {
        self.sessionID = sessionID
        defaults.set(sessionID, forKey: "sessionID")
    }
        
    public func setUser(_ user: UserIdentifier) {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(user)
            
            defaults.set(encoded, forKey: "user")
        } catch let error {
            print(error.localizedDescription)
        }
    }
}
