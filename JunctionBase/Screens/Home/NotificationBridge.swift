//
//  NotificationBridge.swift
//  JunctionBase
//
//  Created by Dean_SSONG on 8/24/25.
//


//
//  NotificationBridge.swift
//  JunctionBase
//
//  Created by Dean_SSONG on 8/24/25.
//

import Foundation
import UserNotifications

final class NotificationBridge: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationBridge()
    private override init() { super.init() }

    /// Call once at app launch to receive notification events
    func start() {
        UNUserNotificationCenter.current().delegate = self
    }

    // Foreground delivery while app is open (always show banner/sound/badge)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.identifier
        let cat = notification.request.content.categoryIdentifier
        completionHandler([.banner, .sound, .badge])
    }

    // Handle tap on notification (background/foreground/cold start)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let id = response.notification.request.identifier
        let cat = response.notification.request.content.categoryIdentifier

        // Reopen camera on our categories
        if cat == "OPEN_CAMERA" || cat == "FIRE_ALERT" {
            NotificationCenter.default.post(name: Notification.Name("OpenCamera"), object: nil)
        }
        completionHandler()
    }
}
