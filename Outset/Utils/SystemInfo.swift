//
//  SystemInfo.swift
//  Outset
//
//  Created by Bart E Reardon on 5/9/2023.
//

import Foundation

public var osVersion: String {
    // Returns the OS version
    let osVersion = ProcessInfo().operatingSystemVersion
    let version = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    return version
}

public var osBuildVersion: String {
    // Returns the current OS build from sysctl
    var size = 0
    sysctlbyname("kern.osversion", nil, &size, nil, 0)
    var osversion = [CChar](repeating: 0, count: size)
    sysctlbyname("kern.osversion", &osversion, &size, nil, 0)
    return String(cString: osversion)

}

public var deviceSerialNumber: String {
    // Returns the current devices serial number
    let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice") )
      guard platformExpert > 0 else {
        return "Serial Unknown"
      }
      guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
        return "Serial Unknown"
      }
      IOObjectRelease(platformExpert)
      return serialNumber
}

public var marketingModel: String {
    return !marketingModelARM.isEmpty ? marketingModelARM : marketingModelIntel
}

public var marketingModelARM: String {
    if #available(macOS 12.0, *) {
        let appleSiliconProduct = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/AppleARMPE/product")
        let cfKeyValue = IORegistryEntryCreateCFProperty(appleSiliconProduct, "product-description" as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(appleSiliconProduct)
        let keyValue: AnyObject? = cfKeyValue?.takeUnretainedValue()
        if keyValue != nil, let data = keyValue as? Data {
            return String(data: data, encoding: String.Encoding.utf8)?.trimmingCharacters(in: CharacterSet(["\0"])) ?? ""
        }
    } else {
        return deviceHardwareModel
    }
    return ""
}

public var marketingModelIntel: String {
    guard let locale = Locale.current.languageCode else { return "en" }

    let modelIdentifier = deviceHardwareModel

    var path = "/System/Library/PrivateFrameworks/ServerInformation.framework/Versions/A/Resources/"
    path += locale + ".lproj"
    path += "/SIMachineAttributes.plist"

    if let fileData = FileManager.default.contents(atPath: path) {
        if let plistContents = try? PropertyListSerialization.propertyList(from: fileData, format: nil)
            as? [String: Any] {
            if let contents = plistContents[modelIdentifier] as? [String: Any],
               let localizable = contents["_LOCALIZABLE_"] as? [String: String] {
                let marketingModel = localizable["marketingModel"] ?? modelIdentifier
                return marketingModel
            }
        }
    }
    return modelIdentifier
}

public var deviceHardwareModel: String {
    // Returns the current devices hardware model from sysctl
    var size = 0
    sysctlbyname("hw.model", nil, &size, nil, 0)
    var model = [CChar](repeating: 0, count: size)
    sysctlbyname("hw.model", &model, &size, nil, 0)
    return String(cString: model)
}
