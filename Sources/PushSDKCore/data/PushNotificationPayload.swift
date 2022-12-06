//
//  PushNotificationPayload.swift
//  
//
//  Created by Mitch Flindell on 25/11/2022.
//

import Foundation
#if canImport(UserNotifications) && canImport(UIKit)
import UserNotifications
#endif

public struct ActionItem: Codable {
    public let action: String
    public let title: String
    public let link: String
}

public class PushNotificationPayload: Codable {
    
    public var actions: [ActionItem] = []
    let title: String
    let body: String
    let image: String?
    let link: String?
    let notificationID: String
    
    public init(
          title: String,
          body: String,
          image: String,
          link: String,
          actions: [ActionItem],
          notificationID: String
    ) {
        self.title = title
        self.body = body
        self.image = image
        self.link = link
        self.actions = actions
        self.notificationID = notificationID
    }
    
    enum CodingKeys: String, CodingKey {
        case actions = "actions"
        case title = "title"
        case body = "body"
        case image = "image"
        case link = "link"
        case notificationID = "ortto_notification_id"
    }
    
    #if canImport(UserNotifications)
    public static func parse(_ content: UNNotificationContent) -> PushNotificationPayload? {
        let actionsJson = content.userInfo["actions"] as? String
        let jsonData = actionsJson!.data(using: .utf8)!
        let actions: [ActionItem] = try! JSONDecoder().decode([ActionItem].self, from: jsonData)
        let payload = PushNotificationPayload(
            title: content.userInfo["title"] as? String ?? content.title,
            body: content.userInfo["body"] as? String ?? content.body,
            image: (content.userInfo["image"] as? String)!,
            link: (content.userInfo["link"] as? String)!,
            actions: actions,
            notificationID: (content.userInfo["ortto_notification_id"] as? String)!
        )
        
        return payload
    }
    #endif
}
