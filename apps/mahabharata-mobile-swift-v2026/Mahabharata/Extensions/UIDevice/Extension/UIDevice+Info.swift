//
//  UIDevice+Info.swift
//  UIDeviceExtension
//
//  Created by Mikhail Kulichkov on 25 Jul 2017.
//	Updated by Andrey Kozlov on 25 Mar 2019.
//  Copyright © 2017 Iron Water Studio. All rights reserved.
//	Changes history:
//		05 Feb 2019. Andrey Kozlov:
//			* added new static method authenticate() for biometric authtorization
//		25 Mar 2019. Andrey Kozlov:
//			* added new devices to deviceName
//

import UIKit
import LocalAuthentication

extension UIDevice {
    
    private struct IOSVersion: Comparable {
        let major: Int
        let minor: Int
        let release: Int
        let more: String
        
        init(string: String) {
            var components = string.components(separatedBy: CharacterSet(charactersIn: " .-_"))
            
            major = components.isEmpty ? 0 : Int(IOSVersion.digits(from: components.removeFirst())) ?? 0
            minor = components.isEmpty ? 0 : Int(IOSVersion.digits(from: components.removeFirst())) ?? 0
            release = components.isEmpty ? 0 : Int(IOSVersion.digits(from: components.removeFirst())) ?? 0
            more = "".appending(components.joined(separator: "."))
        }
        
        // IOSVersion Comparable Protocol
        static func <(lhs: UIDevice.IOSVersion, rhs: UIDevice.IOSVersion) -> Bool {
            if lhs.major < rhs.major {
                return true
            } else if lhs.major == rhs.major && lhs.minor < rhs.minor {
                return true
            } else if lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.release < rhs.release {
                return true
            }
            return  false
        }
        
        static func ==(lhs: UIDevice.IOSVersion, rhs: UIDevice.IOSVersion) -> Bool {
            if lhs.major != rhs.major {
                return false
            } else if lhs.minor != rhs.minor {
                return false
            } else if lhs.release != rhs.release {
                return false
            }
            return  true
        }
        
        // IOSVersion comparison functions
        func isNewer(than version: IOSVersion) -> Bool {
            return self > version
        }
        
        func isOlder(than version: IOSVersion) -> Bool {
            return self < version
        }
        
        // Helpers
        static func digits(from string: String) -> String {
            return string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        }
    }
    
    public enum DeviceName: String, CustomStringConvertible {
        case unknown = "Unknown device"
        case iPodTouch5 = "iPod Touch 5"
        case iPodTouch6 = "iPod Touch 6"
        case iPhone4 = "iPhone 4"
        case iPhone4s = "iPhone 4s"
        case iPhone5 = "iPhone 5"
        case iPhone5c = "iPhone 5c"
        case iPhone5s = "iPhone 5s"
        case iPhone6 = "iPhone 6"
        case iPhone6Plus = "iPhone 6+"
        case iPhone6s = "iPhone 6s"
        case iPhone6sPlus = "iPhone 6s+"
        case iPhone7 = "iPhone 7"
        case iPhone7Plus = "iPhone 7s"
        case iPhoneSE = "iPhone SE"
        case iPhone8 = "iPhone 8"
        case iPhone8Plus = "iPhone 8+"
        case iPhoneX = "iPhone X"
        case iPhoneXS = "iPhone XS"
        case iPhoneXSmax = "iPhone XS Max"
        case iPhoneXR = "iPhone XR"
        case iPad2 = "iPad 2"
        case iPad3 = "iPad 3"
        case iPad4 = "iPad 4"
        case iPadAir = "iPad Air"
        case iPadAir2 = "iPad Air 2"
        case iPad5 = "iPad 5"
        case iPad6 = "iPad 6"
        case iPadMini = "iPad Mini"
        case iPadMini2 = "iPad Mini 2"
        case iPadMini3 = "iPad Mini 3"
        case iPadMini4 = "iPad Mini 4"
        case iPadPro9_7Inch = "iPad Pro 9.7 Inch"
        case iPadPro12_9Inch = "iPad Pro 12.9 Inch"
        case iPadPro12_9Inch2Generation = "iPad Pro 12.9 Inch 2th Generation"
        case iPadPro10_5Inch = "iPad Pro 10.5 Inch"
        case iPadPro11_0Inch = "iPad Pro 11.0 Inch"
        case iPadPro12_9Inch3Generation = "iPad Pro 12.9 Inch 3rd Generation"
        case appleTV = "Apple TV"
        case appleTV4K = "Apple TV 4K"
        case homePod = "Home Pod"
        case simulator = "Simulator"
        
        public var description: String {
            return self.rawValue
        }
    }
    
    // Possible screen sizes
    // https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
    // http://socialcompare.com/en/comparison/apple-ipad-versions-compared-ipad-air-vs-ipad-mini
    public enum DeviceDisplay: Int, Comparable {
        case unknown
        case inch3_5
        case inch4
        case inch4_7
        case inch5_5
        case inch5_8
        case inch6_1
        case inch6_5
        case inch7_9
        case inch9_7
        case inch10_5
        case inch12_9
        
        // DeviceDisplay Comparable Protocol
        public static func <(lhs: UIDevice.DeviceDisplay, rhs: UIDevice.DeviceDisplay) -> Bool {
            return  lhs.rawValue < rhs.rawValue
        }
        
        public static func ==(lhs: UIDevice.DeviceDisplay, rhs: UIDevice.DeviceDisplay) -> Bool {
            return  lhs.rawValue == rhs.rawValue
        }
    }
    
    /// Possible biometric types
    public enum BiometricType: String {
        case none = "None"
        case touchID = "Touch ID"
        case faceID = "Face ID"
        case opticID = "Optic ID"
    }
    
    // https://stackoverflow.com/questions/26028918/ios-how-to-determine-the-current-iphone-device-model-in-swift
    static var deviceName: DeviceName {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return .iPodTouch5
        case "iPod7,1":                                 return .iPodTouch6
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return .iPhone4
        case "iPhone4,1":                               return .iPhone4s
        case "iPhone5,1", "iPhone5,2":                  return .iPhone5
        case "iPhone5,3", "iPhone5,4":                  return .iPhone5c
        case "iPhone6,1", "iPhone6,2":                  return .iPhone5s
        case "iPhone7,2":                               return .iPhone6
        case "iPhone7,1":                               return .iPhone6Plus
        case "iPhone8,1":                               return .iPhone6s
        case "iPhone8,2":                               return .iPhone6sPlus
        case "iPhone9,1", "iPhone9,3":                  return .iPhone7
        case "iPhone9,2", "iPhone9,4":                  return .iPhone7Plus
        case "iPhone8,4":                               return .iPhoneSE
        case "iPhone10,1", "iPhone10,4":                return .iPhone8
        case "iPhone10,2", "iPhone10,5":                return .iPhone8Plus
        case "iPhone10,3", "iPhone10,6":                return .iPhoneX
        case "iPhone11,2":                              return .iPhoneXS
        case "iPhone11,4", "iPhone11,6":                return .iPhoneXSmax
        case "iPhone11,8":                              return .iPhoneXR
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return .iPad2
        case "iPad3,1", "iPad3,2", "iPad3,3":           return .iPad3
        case "iPad3,4", "iPad3,5", "iPad3,6":           return .iPad4
        case "iPad4,1", "iPad4,2", "iPad4,3":           return .iPadAir
        case "iPad5,3", "iPad5,4":                      return .iPadAir2
        case "iPad6,11", "iPad6,12":                    return .iPad5
        case "iPad7,5", "iPad7,6":                      return .iPad6
        case "iPad2,5", "iPad2,6", "iPad2,7":           return .iPadMini
        case "iPad4,4", "iPad4,5", "iPad4,6":           return .iPadMini2
        case "iPad4,7", "iPad4,8", "iPad4,9":           return .iPadMini3
        case "iPad5,1", "iPad5,2":                      return .iPadMini4
        case "iPad6,3", "iPad6,4":                      return .iPadPro9_7Inch
        case "iPad6,7", "iPad6,8":                      return .iPadPro12_9Inch
        case "iPad7,1", "iPad7,2":                      return .iPadPro12_9Inch2Generation
        case "iPad7,3", "iPad7,4":                      return .iPadPro10_5Inch
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return .iPadPro11_0Inch
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return .iPadPro12_9Inch3Generation
        case "AppleTV5,3":                              return .appleTV
        case "AppleTV6,2":								return .appleTV4K
        case "AudioAccessory1,1":						return .homePod
        case "i386", "x86_64":                          return simulatorModel()//.simulator
        default:                                        return .unknown
        }
    }
    
    // Returns true when device is iPad
    // otherwise false (when iPhone or iPod)
    static var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var orient: UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    
    static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    static var displaySize: DeviceDisplay {
        // Check deviceName
        switch self.deviceName {
        case .iPhone4, .iPhone4s:
            return .inch3_5
        case .iPhone5, .iPhone5s, .iPhoneSE, .iPodTouch5, .iPodTouch6:
            return .inch4
        case .iPhone6, .iPhone6s, .iPhone7, .iPhone8:
            return .inch4_7
        case .iPhone6Plus, .iPhone6sPlus, .iPhone7Plus, .iPhone8Plus:
            return .inch5_5
        case .iPhoneX, .iPhoneXS:
            return .inch5_8
        case .iPhoneXR:
            return .inch6_1
        case .iPhoneXSmax:
            return .inch6_5
        case .iPadMini, .iPadMini2, .iPadMini3, .iPadMini4:
            return .inch7_9
        case .iPad2, .iPad3, .iPad4, .iPadAir, .iPadAir2, .iPadPro9_7Inch:
            return .inch9_7
        case .iPadPro10_5Inch:
            return .inch10_5
        case .iPadPro12_9Inch, .iPadPro12_9Inch2Generation:
            return .inch12_9
        default:
            return .unknown
        }
    }
    
    
    /**
     Shows screen size depending on scale factor
     */
    static var displayResolution: CGSize {
        var width = UIScreen.main.nativeBounds.size.width
        var height = UIScreen.main.nativeBounds.size.height
        
        // Fixing downsampling/upsampling when using "Display Zoom"
        // see https://www.paintcodeapp.com/news/ultimate-guide-to-iphone-resolutions
        switch UIDevice.deviceName {
        case .iPhone6, .iPhone6s, .iPhone7, .iPhone8:
            if width == 640.0 {
                width = 750.0
                height = 1334.0
            }
        case .iPhone6Plus, .iPhone6sPlus, .iPhone7Plus, .iPhone8Plus:
            width = 1080.0
            height = 1920.0
        case .iPhoneX, .iPhoneXS:
            width = 1125
            height = 2436
        case .iPhoneXR:
            width = 828
            height = 1792
        case .iPhoneXSmax:
            width = 1242
            height = 2688
        default:
            break
        }
        
        return CGSize(width: width, height: height)
    }
    
    // MARK: - Device display comparison
    
    static func isDisplaySmaller(than display: DeviceDisplay) -> Bool {
        return UIDevice.displaySize.rawValue < display.rawValue
    }
    
    static func isDisplayBigger(than display: DeviceDisplay) -> Bool {
        return UIDevice.displaySize.rawValue > display.rawValue
    }
    
    // MARK: - iOS version
    
    static var iOSVersion: String {
        let currentVersion = IOSVersion(string: UIDevice.current.systemVersion)
        return "\(currentVersion.major).\(currentVersion.minor).\(currentVersion.release)\(currentVersion.more != "" ? ".\(currentVersion.more)" : "")"
    }
    
    func isNewer(than version: String) -> Bool {
        return IOSVersion(string: UIDevice.current.systemVersion) > IOSVersion(string: version)
    }
    
    func isOlder(than version: String) -> Bool {
        return IOSVersion(string: UIDevice.current.systemVersion) < IOSVersion(string: version)
    }
    
    // MARK: - Biometric
    
    /// Detection supported biometric type (TouchID, FaceID)
    static func biometricType() -> BiometricType {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch(authContext.biometryType) {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            case .opticID:
                return .opticID
            @unknown default:
                return .none
            }
        } else {
            return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
        }
    }
    
    /// Show FaceID or TouchID system overlay/popup to recognize face or finger touch
    static func authenticate(reason: String, success: @escaping () -> (), failure: @escaping (Error?) -> ()) {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (isSuccess, error) in
                //DispatchQueue.main.async {
                isSuccess ? success() : failure(error)
                //}
            }
        }
    }
    
    // MARK: - Helpers
    
    // TODO: check sizes for iphone8 and add here
    private static func simulatorModel() -> DeviceName {
        switch max(UIScreen.main.nativeBounds.height, UIScreen.main.nativeBounds.height) {
        case 960.0:
            return .iPhone4s
        case 1136.0:
            return .iPhone5s
        case 1334.0:
            return .iPhone7
        case 2208.0:
            return .iPhone7Plus
        case 1024.0:
            return .iPad2
        case 2048.0:
            return .iPadAir2
        case 2732.0:
            return .iPadPro12_9Inch
        default:
            return .unknown
        }
    }
}
