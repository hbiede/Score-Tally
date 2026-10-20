//
// OrientationSupport
// ScoreTally
//
// Created on 10/8/26
//

import UIKit

/// iPhone Duo model identifiers. Landscape is limited to these so the outer display reads
/// correctly when the phone is propped up in tent mode; other iPhones stay portrait-only.
private let duoModelIdentifiers: Set<String> = [
    "iPhone19,4"
]

extension UIDevice {
    /// The hardware model identifier, such as "iPhone19,4"
    var modelIdentifier: String {
        if let simulatorModel = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorModel
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    var isDuo: Bool {
        duoModelIdentifiers.contains(modelIdentifier)
    }

    /// Narrows the Info.plist orientations, which allow landscape on iPhone so the Duo can use it
    var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if userInterfaceIdiom == .pad {
            return .all
        }

        return isDuo ? .allButUpsideDown : .portrait
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    // Used before iOS 27, which moved this to the scene delegate
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        UIDevice.current.supportedInterfaceOrientations
    }
}

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    @available(iOS 27.0, *)
    func supportedInterfaceOrientations(for windowScene: UIWindowScene) -> UIInterfaceOrientationMask {
        UIDevice.current.supportedInterfaceOrientations
    }
}
