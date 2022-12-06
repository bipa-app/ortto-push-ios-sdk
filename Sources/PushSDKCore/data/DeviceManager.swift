//
//  MessagingPushInstance.swift
//
//  Created by Mitch Flindell on 18/11/2022.
//

import Foundation
import Alamofire

public protocol DeviceManagerInterface {
    /**
     Register a new device with Orttos API
     */
    func registerDeviceToken(user: UserIdentifier, sessionID: String?, deviceToken: String, tokenType: String, completion: @escaping (RegistrationResponse?) -> Void)
        
    /**
     Clear the device permissions from Orttos API
     */
    func clearDeviceToken()
}

public class DeviceManager: DeviceManagerInterface {
    
    public func clearDeviceToken() {
        // TODO:
    }
    
    // device token
    public func registerDeviceToken(user: UserIdentifier, sessionID: String?, deviceToken: String, tokenType: String = "apns", completion: @escaping (RegistrationResponse?) -> Void) {
        
        guard let endpoint = Ortto.shared.apiEndpoint else {
            return
        }
        
        let url = URL(string: "\(endpoint)/-/events/push-permission")!

        let tokenRegistration = TokenRegistration(
            dataSourceInstanceIDHash: Ortto.shared.dataSourceId!,
            contactID: user.contactID,
            associationEmail: user.email,
            associationPhone: user.phone,
            associationExternalID: user.externalID,
            session: sessionID,
            firstName: user.firstName,
            lastName: user.lastName,
            acceptGDPR: user.acceptsGDPR,
            permission: true,
            deviceToken: deviceToken,
            pushTokenType: tokenType
        )
        
        let headers: HTTPHeaders = [
            .accept("application/json"),
            .userAgent("Demo App")
        ]

        AF.request(url, method: .post, parameters: tokenRegistration, encoder: JSONParameterEncoder.default, headers: headers)
            .validate()
            .responseJSON { response in
                guard let data = response.data else { return }
                
                let decoder = JSONDecoder()
                do {
                    let registration = try decoder.decode(RegistrationResponse.self, from: data)
                    debugPrint(registration)
                    completion(registration)
                } catch let error {
                    debugPrint(error)
                }
            }
    }

}
