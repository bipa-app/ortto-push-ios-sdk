//
//  TokenRegistration.swift
//  
//
//  Created by Mitch Flindell on 25/11/2022.
// Registration class adapter for the Ortto API 

import Foundation

struct TokenRegistration: Codable {
    let dataSourceInstanceIDHash: String
    let contactID: String?
    let associationEmail: String?
    let associationPhone: String?
    let associationExternalID: String?
    let session: String?
    let firstName: String?
    let lastName: String?
    let acceptGDPR: Bool
    let skipNonExistingContacts: Bool = false
    let permission: Bool
    let platform: String = "ios"
    let deviceToken: String
    let pushTokenType: String //= "apns"
    
    enum CodingKeys: String, CodingKey {
        case dataSourceInstanceIDHash = "h"
        case contactID = "c"
        case associationEmail = "e"
        case associationPhone = "p"
        case associationExternalID = "ei"
        case session = "s"
        case firstName = "first"
        case lastName = "last"
        case acceptGDPR = "ag"
        case skipNonExistingContacts = "sne"
        case permission = "pm"
        case platform = "pl"
        case deviceToken = "ptk"
        case pushTokenType = "ptkt"
    }
}

public struct RegistrationResponse: Codable {
    let sessionID: String
    
    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
    }
}
