//
//  MessagingPush.swift
//  demo-app
//
//  Created by Mitch Flindell on 18/11/2022.
//

import Foundation
#if canImport(UserNotifications) && canImport(UIKit)
import UIKit
import UserNotifications
#endif

struct RegistrationRequestBody: Codable {
    let token: String
    let profile_id: String
}

// Used for rich push
protocol MessagingServiceProtocol {
    
    func clearDeviceToken()
    
    #if canImport(UserNotifications)
    @discardableResult
    func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool

    func serviceExtensionTimeWillExpire()
    #endif
}

public class MessagingService: MessagingServiceProtocol {
    
    public private(set) static var shared = MessagingService()
    
    internal var deviceManager: DeviceManager?
    
    init() {
    }
    
    public func registerDeviceToken(token: String, tokenType: String) {
    
        // Ensure the user ID is not empty
        guard let id = Ortto.shared.identifier else {
            Ortto.log().info("MessagingService@registerDeviceToken.fail id=empty")
            return
        }
        
        Ortto.log().debug("MessagingService@registerDeviceToken.debug token=\(token) type=\(tokenType)")
            
        Ortto.shared.deviceManager.registerDeviceToken(
            user: id,
            sessionID: Ortto.shared.prefsManager.sessionID,
            deviceToken: token,
            tokenType: tokenType
        ) { (response: RegistrationResponse?) in
            guard let sessionID = response?.sessionID else {
                return
            }
            
            Ortto.shared.prefsManager.setSessionID(sessionID)
        }
    }
    
    public func clearDeviceToken() {
        deviceManager?.clearDeviceToken()
    }
    
    #if canImport(UserNotifications)
    public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        guard let pushPayload = PushNotificationPayload.parse(request.content) else {
            Ortto.log().warn("MessagingService@didReceive.content.parse-fail")
            return false
        }


        var userInfo: [String:String] = [:]

        var myActionList: [UNNotificationAction] = [        ]
        for action: ActionItem in pushPayload.actions {
            myActionList.append(UNNotificationAction(
                identifier: action.action,
                title: action.title,
                options: [.foreground]
            ))
            userInfo[action.action] = action.link
        }

        // Define the notification type
        let category = UNNotificationCategory(
            identifier: request.content.categoryIdentifier,
            actions: myActionList,
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        let content = UNMutableNotificationContent()
        content.title = pushPayload.title
        content.body = pushPayload.body
        content.sound = .default
        content.userInfo = userInfo
        content.categoryIdentifier = request.content.categoryIdentifier

        
        getMediaAttachment(for: pushPayload.image!) { [weak self] image in
            guard
                let self = self,
                let image = image,
                let fileURL = self.saveImageAttachment(
                    image: image,
                    forIdentifier: "attachment.png")
            else {
                print("nah dog")
                return
            }
            
            let imageAttachment = try? UNNotificationAttachment(
                identifier: "image",
                url: fileURL,
                options: nil)
            
            if let imageAttachment = imageAttachment {
                content.attachments = [imageAttachment]
            }
        }
       
        
        Task.init{
            let handled: Bool = await setCategories(newCategory: category)
            contentHandler(content)
        }
    
        return true
    }
        
        private func saveImageAttachment(
          image: UIImage,
          forIdentifier identifier: String
        ) -> URL? {

          let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
          let directoryPath = tempDirectory.appendingPathComponent(
            ProcessInfo.processInfo.globallyUniqueString,
            isDirectory: true)

          do {
            try FileManager.default.createDirectory(
              at: directoryPath,
              withIntermediateDirectories: true,
              attributes: nil)

            let fileURL = directoryPath.appendingPathComponent(identifier)

            guard let imageData = image.pngData() else {
              return nil
            }

            try imageData.write(to: fileURL)
              return fileURL
            } catch {
              return nil
          }
        }
    
    private func getMediaAttachment(for urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        guard let imageData  = try? Data(contentsOf: url) else {
            completion(nil)
            return
        }
                
        let img: UIImage = UIImage(data: imageData)!
        
        return completion(img)
    }
    
    func setCategories(newCategory: UNNotificationCategory) async -> Bool {
        return await withCheckedContinuation {continuation in
            UNUserNotificationCenter.current().getNotificationCategories { categories in
                var allCategories: Set<UNNotificationCategory> = categories
                allCategories.insert(newCategory)
            
                UNUserNotificationCenter.current().setNotificationCategories(allCategories)
                
                UNUserNotificationCenter.current().getNotificationCategories { categories in
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    public func serviceExtensionTimeWillExpire() {
        // TODO: Implement cancellation of image downloads
        //        RichPushRequestHandler.shared.stopAll()
        //        implementation?.serviceExtensionTimeWillExpire()
    }
    
    #endif
    
  
}
