//
//  Ortto.swift
//
//  Created by Mitch Flindell on 17/11/2022.
//

import Foundation

public protocol OrttoInterface {
    var dataSourceId: String? { get }
    var apiEndpoint: String? { get }

    func identify(userIdentifier: UserIdentifier)
}

public class Ortto: OrttoInterface {
    public var dataSourceId: String?
    public var apiEndpoint: String?
    public var identifier: UserIdentifier?
    
    public private(set) static var shared = Ortto()
    public var deviceManager = DeviceManager()
    public var prefsManager = PreferencesManager()
    
    private var logger: Logger {
        PrintLogger()
    }
    
    public static func log() -> Logger {
        return shared.logger
    }
    
    private init() {
    }
    
    public static func initialize(datasourceID: String, endpoint: String?) {
        if let endpoint = endpoint {
            shared.apiEndpoint = endpoint
        }
        
        shared.dataSourceId = datasourceID
    }
    
    public func identify(userIdentifier: UserIdentifier) {
        prefsManager.setUser(userIdentifier)
        identifier = userIdentifier
    }
}
