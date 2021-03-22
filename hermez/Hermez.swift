//
//  ZeroConfig.swift
//  zeroconfig_test
//
//  Created by Nicholas Gustilo on 3/6/21.
//

import Foundation
import RxSwift

public enum HermezError: Error {
    case SERVICE_FAILED
    case DEVICE_NOT_FOUND
    case JSON_PARSE_ERROR
}

public struct HermezDevice: Codable, Equatable {
    public var name: String
    public var jsonData: String?
}

public struct HermezMessage: Codable, Equatable {
    public var message: String?
    public var jsonData: String?
    public var messageID: String
    public var receivingDevice: HermezDevice
    public var sendingDevice: HermezDevice
}

public protocol HermezDataAvailable : class {
    func availableDevices(devices: [HermezDevice])
    func messageReceived(message: HermezMessage)
    
    // Optional default implementation exists (see below)
    func serviceStarted(serviceType: String, serviceName: String)
    func serviceStopped(serviceType: String, serviceName: String)
    func serviceFailed(serviceType: String, serviceName: String, error: HermezError)
    func messageCannotBeSentToDevices(messages: [HermezMessage], error: HermezError)
}

public extension HermezDataAvailable { //defaults
    func serviceStarted(serviceType: String, serviceName: String) {
        print("serviceStarted type: \(serviceType), name: \(serviceName)")
    }
    
    func serviceStopped(serviceType: String, serviceName: String) {
        print("serviceStopped type: \(serviceType), name: \(serviceName)")
    }
    
    func serviceFailed(serviceType: String, serviceName: String, error: HermezError) {
        print("serviceFailed type: \(serviceType), name: \(serviceName), error: \(error)")
    }
    
    func messageCannotBeSentToDevices(messages: [HermezMessage], error: HermezError) {
        print("messageCannotBeSentToDevices messages: \(messages), error: \(error)")
    }
}

func print(_ items: Any...) {
    #if DEBUG
    Swift.print(items[0])
    #endif
}

public class Hermez: NSObject {
    public static let shared = Hermez()
    public var device: HermezDevice?
    
    private var serviceName: String = "unknown"
    private var deviceName: String?
    private var delegates: [HermezDataAvailable] = []
    
    private override init() {
        super.init()
        HermezService.shared.setDataDelegate(newDelegate: self)
        HermezBrowser.shared.setDataDelegate(newDelegate: self)
    }
    
    public func setServiceAndDeviceName(serviceName: String, deviceName: String, deviceJson: String?) -> Bool {
        if !HermezService.shared.serviceIsActive {
            self.serviceName = serviceName
            self.deviceName = deviceName
            let theDevice = HermezDevice(name: deviceName, jsonData: deviceJson)
            self.device = theDevice
            HermezBrowser.shared.device = theDevice
            return self.startService(serviceName: serviceName, device: theDevice)
        } else {
            self.serviceName = serviceName
            self.deviceName = deviceName
            let theDevice = HermezDevice(name: deviceName, jsonData: deviceJson)
            self.device = theDevice
        }
        return true
    }

    public func addDataDelegate(delegate: HermezDataAvailable) {
        self.delegates.append(delegate)
    }
    
    public func removeDataDelegate(delegate: HermezDataAvailable) {
        self.delegates = self.delegates.filter { $0 !== delegate }
    }
    
    public func findAvailableDevices() {
        if !HermezBrowser.shared.isSearching {
            HermezBrowser.shared.setDataDelegate(newDelegate: self)
            let adjServiceName = "_" + serviceName + "._tcp"
            HermezBrowser.shared.findAvailableDevices(serviceType: adjServiceName)
        } else {
            for delegate in delegates {
                delegate.availableDevices(devices: HermezBrowser.shared.devices)
            }
        }
    }
    
    public func sendMessageToDevices(message: String?, json: String?, devices: [HermezDevice], messageID: String) {
        var messages = [HermezMessage]()
        for device in devices {
            if let fromDevice = self.device {
                let sendMessage = HermezMessage(message: message, jsonData: json, messageID: messageID, receivingDevice: device, sendingDevice: fromDevice)
                messages.append(sendMessage)
            }
        }
        if messages.count > 0 {
            HermezBrowser.shared.sendMessageToDevices(messages: messages)
        } else {
            //TODO: add error handling
        }
    }
    
    public func stopService() {
        if HermezService.shared.serviceIsActive {
            HermezService.shared.stopService()
        }
    }
    
    private func startService(serviceName: String, device: HermezDevice) -> Bool {
        let adjServiceName = "_" + serviceName + "._tcp"
        return HermezService.shared.publishService(serviceType: adjServiceName, name: device.name)
    }
}

extension Hermez: HermezServiceDataAvailable {
    func serviceStarted(serviceType: String, serviceName: String) {
        print("serviceStarted(): type'\(serviceType)' name'\(serviceName)'")
        for delegate in delegates {
            delegate.serviceStarted(serviceType: serviceType, serviceName: serviceName)
        }
    }
    
    func serviceStopped(serviceType: String, serviceName: String) {
        for delegate in delegates {
            delegate.serviceStopped(serviceType: serviceType, serviceName: serviceName)
        }
    }
    
    func messageReceived(message: HermezMessage) {
        for delegate in delegates {
            delegate.messageReceived(message: message)
        }
    }
    
    func serviceFailed(serviceType: String, serviceName: String, error: HermezError) {
        for delegate in delegates {
            delegate.serviceFailed(serviceType: serviceType, serviceName: serviceName, error: error)
        }
    }
}

extension Hermez: HermezBrowserDataAvailable {
    func availableDevices(devices: [HermezDevice]) {
        for delegate in delegates {
            delegate.availableDevices(devices: devices)
        }
    }
    
    func messageCannotBeSentToDevices(messages: [HermezMessage], error: HermezError) {
        for delegate in delegates {
            delegate.messageCannotBeSentToDevices(messages: messages, error: error)
        }
    }
}
