//
//  MessagingPush+AppDelegate.swift
//  demo-app
//
//  Created by Mitch Flindell on 18/11/2022.
//

import Foundation
#if canImport(UserNotifications) && canImport(UIKit)
import UserNotifications
import UIKit
#endif

#if canImport(UserNotifications) && canImport(UIKit)
@available(iOSApplicationExtension, unavailable)
public extension PushMessaging {
    
    /**
        Accept an action click on a notification
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
        
        let userInfo: [AnyHashable : Any] = response.notification.request.content.userInfo
        
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            return false
        }
    
        let key: String = response.actionIdentifier
        let deepLink: String = (userInfo[key] as? String)!
        let url = URL(string: deepLink)!
        
        if !UIApplication.shared.canOpenURL(url) {
            print("pls i cannot open url")
            completionHandler()
            return true
        }
        
        print("opening: \(url)")
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)

        completionHandler()
    
        return true;
    }
}
#endif
