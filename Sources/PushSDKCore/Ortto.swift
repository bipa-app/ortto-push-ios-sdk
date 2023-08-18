//
//  Ortto.swift
//
//  Created by Mitch Flindell on 17/11/2022.
//

import Alamofire
import Foundation

let version: String = "1.2.2"

public protocol OrttoInterface {
    var appKey: String? { get }
    var apiEndpoint: String? { get }

    func identify(_ user: UserIdentifier)
}

public enum PushPermission: String {
    case Accept = "accept"
    case Deny = "deny"
    case Automatic = "automatic"
}

public class Ortto: OrttoInterface {
    public var appKey: String?
    public var apiEndpoint: String?
    public var identifier: UserIdentifier?

    public private(set) static var shared = Ortto()
    internal var apiManager = ApiManager()
    internal var prefsManager = PreferencesManager()
    public var permission = PushPermission.Automatic

    private var logger: OrttoLogger = PrintLogger()

    /**
     Overwrite Logging service
     */
    public func setLogger(customLogger: OrttoLogger) {
        logger = customLogger
    }

    public static func log() -> OrttoLogger {
        return shared.logger
    }

    private init() {}

    public static func initialize(appKey: String, endpoint: String?) {
        if var endpoint = endpoint {
            if endpoint.last == "/" {
                endpoint = String(endpoint.dropLast())
            }
            shared.apiEndpoint = endpoint
        }

        shared.appKey = appKey
    }

    public func clearData() {
        prefsManager.clearAll()
    }

    /**
     Identify the current user via Ortto API
     */
    public func identify(_ user: UserIdentifier) {
        prefsManager.setUser(user)
        identifier = user

        apiManager.registerIdentity(
            user: user,
            sessionID: prefsManager.sessionID
        ) { (response: RegistrationResponse?) in
            guard let sessionID = response?.sessionID else {
                return
            }
            self.logger.info("identify.success \(sessionID)")

            self.prefsManager.setSessionID(sessionID)
        }
    }

    /**
     Set explicit permission to send push notifications
     */
    public func setPermission(_ permission: PushPermission) {
        prefsManager.setPermission(permission)
        self.permission = permission
    }

    public func getToken() -> String? {
        return prefsManager.token?.value
    }

    /**
     Send push token to Ortto API
     */
    internal func updatePushToken(token: PushToken, force: Bool = false) {
        // Skip registration of the token if it is the same
        if token.value == prefsManager.token?.value && !force {
            Ortto.log().info("Ortto@updatePushToken.skip")
            return
        }

        prefsManager.setToken(token)

        // get the latest token, send it off
        apiManager.registerDeviceToken(
            sessionID: prefsManager.sessionID,
            deviceToken: token.value,
            tokenType: token.type
        ) { (response: RegistrationResponse?) in
            guard let sessionID = response?.sessionID else {
                return
            }

            self.prefsManager.setSessionID(sessionID)
        }
    }

    /**
     Update push token
     */
    internal func dispatchPushRequest(_ token: PushToken) {
        updatePushToken(token: token)
    }

    /**
     Update push token
     */
    public func dispatchPushRequest() {
        guard let token = prefsManager.token else {
            return
        }

        updatePushToken(token: token, force: true)
    }

    /**
     * Retrieve the utm_X parameters from the deep link
     */
    public func retrieveUtmParameters(_ encodedUrl: String) -> LinkUtm? {
        guard let url = URL(string: encodedUrl) else {
            Ortto.log().error("could not decode tracking_url: \(encodedUrl)")
            return nil
        }

        guard let components = URLComponents(string: url.absoluteString) else { return nil }
        guard let queryItems = components.queryItems else { return nil }

        let utm = LinkUtm(queryItems)

        return utm
    }

    /**
     Track the clicking of a link and return the utm values for the developer to use for marketing
     */
    public func trackLinkClick(_ encodedUrl: String, completionHandler: @escaping () -> Void) {
        guard let url = URL(string: encodedUrl) else {
            Ortto.log().error("could not decode tracking_url: \(encodedUrl)")

            return
        }

        guard let components = URLComponents(string: url.absoluteString) else { return }
        guard let queryItems = components.queryItems else { return }

        let items = queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }

        guard let trackingUrl = items["tracking_url"] else {
            Ortto.log().error("could not get tracking_url: \(encodedUrl)")

            return
        }

        let urlStr = "data:application/octet-stream;base64," + urlSafeBase64(trackingUrl)

        guard let burl = URL(string: urlStr) else {
            Ortto.log().error("could not get url: \(urlStr)")
            return
        }
        guard let data = try? Data(contentsOf: burl),
              let trackingUrlFinal = String(data: data, encoding: .utf8)
        else {
            Ortto.log().error("could not get trackingUrlFinal: \(urlStr)")
            return
        }

        guard var urlComponents = URLComponents(string: trackingUrlFinal) else {
            Ortto.log().error("could not get urlComponents: \(trackingUrlFinal)")
            return
        }
        for item in apiManager.getTrackingQueryItems() {
            urlComponents.queryItems?.append(item)
        }

        if let url = urlComponents.url {
            AF.request(url, method: .get)
                .validate()
                .responseJSON { response in
                    if let response = response.response {
                        Ortto.log().info("Ortto@trackLinkClick statusCode=\(response.statusCode)")

                        response.statusCode == 200 ? completionHandler() : ()
                    }
                }
        }
    }

    private func urlSafeBase64(_ url: String) -> String {
        var st = url.replacingOccurrences(of: "_", with: "/")
            .replacingOccurrences(of: "-", with: "+")
        let remainder = url.count % 4
        if remainder > 0 {
            st = url.padding(
                toLength: url.count + 4 - remainder,
                withPad: "=",
                startingAt: 0
            )
        }

        return st
    }
}
