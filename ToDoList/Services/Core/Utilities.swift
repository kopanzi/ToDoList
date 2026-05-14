import Foundation
import UIKit

final class Utilities {
    
    static let shared = Utilities()
    private init() {}
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        
        // ✨ SENIOR FIX: iOS 13 ve sonrası için modern, uyarısız (warning-free) pencere bulma yöntemi
        let window = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first
        
        let currentController = controller ?? window?.rootViewController
        
        if let navigationController = currentController as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = currentController as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = currentController?.presentedViewController {
            return topViewController(controller: presented)
        }
        return currentController
    }
}

