//
//  MessagingPushInstance.swift
//
//  Created by Mitch Flindell on 18/11/2022.
//

import Foundation
import Alamofire

public protocol ApiManagerInterface {
    /**
     Register a new device with Orttos API
     */
    func registerDeviceToken(user: UserIdentifier, sessionID: String?, deviceToken: String, tokenType: String, completion: @escaping (RegistrationResponse?) -> Void)
}

internal class ApiManager: ApiManagerInterface {
    
    internal func debug(name: String, _ model: Codable) {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(model)
            let jsonString = String(data: encoded, encoding: .utf8)!

            print("ApiManager.debug \(name): \(jsonString)")
        } catch let error {
            debugPrint(error)
        }
    }
    
    /**
     Send an Identify request to Ortto
     */
    func registerIdentity(user: UserIdentifier, sessionID: String?, completion: @escaping (RegistrationResponse?) -> Void) {
        
        let url = URL(string: Ortto.shared.apiEndpoint!)!.appendingPathComponent("-/events/push-mobile-session")
        
        let identityRegistration = PushMobileSessionRequest(
            appKey: Ortto.shared.appKey!,
            contactID: user.contactID,
            associationEmail: user.email,
            associationPhone: user.phone,
            associationExternalID: user.externalID,
            sessionID: sessionID,
            firstName: user.firstName,
            lastName: user.lastName,
            acceptGDPR: user.acceptsGDPR,
            skipNonExistingContacts: Ortto.shared.skipNonExistingContacts
        )
        
        debug(name: "registerIdentity", identityRegistration)
        
        let headers: HTTPHeaders = [
            .accept("application/json"),
            .userAgent(Alamofire.HTTPHeader.defaultUserAgent.value)
        ]

        AF.request(url.absoluteString, method: .post, parameters: identityRegistration, encoder: JSONParameterEncoder.default, headers: headers)
            .validate()
            .responseJSON { response in
                guard let data = response.data else { return }
                guard let statusCode = response.response?.statusCode else { return }

                let json = String(data: data, encoding: String.Encoding.utf8)
                Ortto.log().info("ApiManager@registerIdentity status=\(statusCode) body=\(json)")
                
                switch (response.result) {
                    case .success(let value):
                        let decoder = JSONDecoder()
                        do {
                            let registration = try decoder.decode(RegistrationResponse.self, from: data)
                            completion(registration)
                        } catch let error {
                            Ortto.log().error("ApiManager@registerIdentity.decode.error \(error.localizedDescription)")
                        }
                    case .failure(let error):
                        Ortto.log().error("ApiManager@registerIdentity.request.fail \(error.localizedDescription)")
                }
            }
    }
    
    // device token
    public func registerDeviceToken(user: UserIdentifier, sessionID: String?, deviceToken: String, tokenType: String = "apn", completion: @escaping (RegistrationResponse?) -> Void) {
        
        guard let endpoint = Ortto.shared.apiEndpoint else {
            return
        }
        
        let url = URL(string: endpoint)!.appendingPathComponent("-/events/push-permission")
        
        let tokenRegistration = PushPermissionRequest(
            appKey: Ortto.shared.appKey!,
            permission: getPermission(),
            sessionID: sessionID!,
            deviceToken: deviceToken,
            pushTokenType: tokenType
        )
        
        debug(name: "registerDeviceToken", tokenRegistration)
        
        let headers: HTTPHeaders = [
            .accept("application/json"),
            .userAgent(Alamofire.HTTPHeader.defaultUserAgent.value)
        ]

        AF.request(url.absoluteString, method: .post, parameters: tokenRegistration, encoder: JSONParameterEncoder.default, headers: headers)
            .validate()
            .responseJSON{ response in
                guard let data = response.data else { return }
                guard let statusCode = response.response?.statusCode else { return }
                
                let json = String(data: data, encoding: String.Encoding.utf8)
                Ortto.log().info("ApiManager@registerDeviceToken status=\(statusCode) body=\(json)")
                
                switch (response.result) {
                    case .success(let value):
                        let decoder = JSONDecoder()
                        do {
                            let registration = try decoder.decode(RegistrationResponse.self, from: data)
                            completion(registration)
                        } catch let error {
                            Ortto.log().error("ApiManager@registerDeviceToken.decode.error \(error.localizedDescription)")
                        }
                    case .failure(let error):
                        Ortto.log().error("ApiManager@registerDeviceToken.request.fail \(error.localizedDescription)")
                }
            }
            
            
    }
    
    private func getPermission() -> Bool {
        switch (Ortto.shared.permission) {
        case .Automatic:
            return Ortto.shared.prefsManager.hasToken();
        case .Accept:
            return true;
        case .Deny:
            return false;
        }
    }

}
