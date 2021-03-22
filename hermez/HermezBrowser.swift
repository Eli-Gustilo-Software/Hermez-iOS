//
//  ZeroConfigBrowser.swift
//  zeroconfig_test
//
//  Created by Nicholas Gustilo on 3/3/21.
//

import Foundation
import CocoaAsyncSocket

struct HermezBrowserService {
    let netService: NetService
    var joinSocket: GCDAsyncSocket
    let device: HermezDevice
}

protocol HermezBrowserDataAvailable {
    func availableDevices(devices: [HermezDevice])
    func messageCannotBeSentToDevices(messages: [HermezMessage], error: HermezError) // TODO: never called??
}

class HermezBrowser: NSObject {
    static let shared = HermezBrowser()
    
    var serviceBrowser = NetServiceBrowser()
    var device: HermezDevice?
    var isSearching: Bool = false
    var devices: [HermezDevice] = []
    
    private var dataDelegate: HermezBrowserDataAvailable?
    
    //private var isConnected = false
    private var messageQueue: [HermezMessage] = []
    private var serviceName: String?
    private let HERMES_DOMAIN = "local."
    private var services:[HermezBrowserService] = []
    
    func startBrowsing(serviceType: String) {
        self.services.removeAll()
        self.serviceBrowser.delegate = self
        DispatchQueue.global(qos: .background).async {
            self.serviceBrowser.searchForServices(ofType: "_blah._tcp.", inDomain: self.HERMES_DOMAIN)
            self.isSearching = true
        }
    }
    
    func findAvailableDevices(serviceType: String) {
        // TODO: query for devices
        if !isSearching {
            self.startBrowsing(serviceType: serviceType)
        }
    }
    
    func sendMessageToDevices(messages: [HermezMessage]) {
        // TODO: Queue connect via each device and send????
         for currentMessage in messages {
            if let currentService = findZCBrowserServiceByDevice(device: currentMessage.receivingDevice ) {
                if let messageAsJsonData = try? JSONEncoder().encode(currentMessage) {
                    let messageAsJsonString = String(data: messageAsJsonData, encoding: .utf8)!
                    sendValue(str: messageAsJsonString, zcBrowserService: currentService)
                } else {
                    print("Unable to connect to address.")
                }                
            } else {
                // have to create connection and go
            }
        }
    }
    
    func stopBrowsing() {
        print("Net service browser stopped browsing.")
        serviceBrowser.stop()
        serviceBrowser.delegate = nil
        self.serviceBrowser = NetServiceBrowser()
        isSearching = false
    }
    
    func setDataDelegate(newDelegate: HermezBrowserDataAvailable) {
        self.dataDelegate = newDelegate
    }
    
    private func serviceSelected(service: NetService) {
        service.delegate = self
        service.resolve(withTimeout: 30.0)
    }
    
    private func findZCBrowserService(service: NetService) -> HermezBrowserService? {
        for currentService in services {
            if service == currentService.netService {
                return currentService
            }
        }
        return nil
    }
    
    private func findZCBrowserServiceByDevice(device: HermezDevice) -> HermezBrowserService? {
        for currentService in services {
            if device == currentService.device {
                return currentService
            }
        }
        return nil
    }
    
    private func findZCBrowserServiceBySocket(socket: GCDAsyncSocket) -> HermezBrowserService? {
        for currentService in services {
            if socket == currentService.joinSocket {
                return currentService
            }
        }
        return nil
    }
    
    private func updateService(updatedService: HermezBrowserService) {
        var index = 0
        for currentService in services {
            if currentService.netService == updatedService.netService {
                services.remove(at: index)
            }
            index += 1
        }
        services.append(updatedService)
    }
    
    private func addService(service: HermezBrowserService) {
        self.services.append(service)
        

    }
}

//MARK: - Netservice Browser Delegate
extension HermezBrowser: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("more incoming ", moreComing , " service ", service)
        let zcDevice = HermezDevice(name: service.name, jsonData: nil)
        let newService = HermezBrowserService(netService: service, joinSocket: GCDAsyncSocket(), device: zcDevice)
        self.services.append(newService)
        service.delegate = self
        service.resolve(withTimeout: 30.0)
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("Net service browser Did remove service: \(service)")
        self.services = services.filter {
            return service != $0.netService
        }
        if !moreComing {
            // update var??
        }
    }
    
    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("Net service browser did stop search.")
        self.isSearching = false
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("Net service browser failed to search with error: \(errorDict)")
        self.isSearching = false
    }
}

//MARK: - NetService Delegate
extension HermezBrowser: NetServiceDelegate {
    
    func netServiceDidResolveAddress(_ sender: NetService) {
        if connect(with: sender) {
         } else {
            print("Unable to Connect with Service: domain \(sender.domain) type \(sender.type) name \(sender.name) port\(sender.port)")
        }
        var devices: [HermezDevice] = []
        for currentServices in self.services {
            devices.append(currentServices.device)
        }
        if devices.count > 0 {
            DispatchQueue.main.async {
                self.devices = devices
                self.dataDelegate?.availableDevices(devices: devices)
            }
        }
    }
    
    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("NetService : \(sender) failed to resolve with info: \(errorDict).")
    }
    
    func connect(with service: NetService?) -> Bool {
        var isConnected = false
        
        if let theService = service, var zcBrowserService = findZCBrowserService(service: theService) {
            let addresses = service?.addresses
            
            if !zcBrowserService.joinSocket.isConnected {
                // Initialize Socket
                zcBrowserService.joinSocket = GCDAsyncSocket(delegate: self, delegateQueue: .main)
                self.updateService(updatedService: zcBrowserService)
                // Connect
                while !isConnected && addresses?.count != nil {
                    let address = addresses?[0]
                    if address != nil {
                        if let _ = try? zcBrowserService.joinSocket.connect(toAddress: address!) {
                            isConnected = true
                            print("Socket connected.")
                        } else {
                            print("Unable to connect to address.")
                        }
                    }
                }
                
            } else {
                isConnected = zcBrowserService.joinSocket.isConnected
            }
        }
        print("NetService : \(String(describing: service)) connected.")
        return isConnected
    }
    

}

//MARK: - GCDAsyncSocket Delegate
extension HermezBrowser: GCDAsyncSocketDelegate {
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("Socket Did Connect to Host: \(host), Port: \(port)", sock)
        if let zcBrowserService = findZCBrowserServiceBySocket(socket: sock), let myDevice = self.device {
            let message = HermezMessage(message: "ZeroConfigBrowser did connect to service \(myDevice.name)!!!\r\n", jsonData: nil, messageID: "\(myDevice.name)", receivingDevice: zcBrowserService.device, sendingDevice: myDevice)
            if let messageAsJsonData = try? JSONEncoder().encode(message) {
                let messageAsJsonString = String(data: messageAsJsonData, encoding: .utf8)!
                sendValue(str: messageAsJsonString, zcBrowserService: zcBrowserService)
            }
        }
    }
    
    func sendValue(str: String, zcBrowserService: HermezBrowserService) {
        print("sendValue str = \(str)")
        let data = Data(str.utf8) + GCDAsyncSocket.crlfData()
        let service = zcBrowserService.netService
        print("sendValue service data: \(String(describing: service.hostName)), Port: \(service.port)")

        zcBrowserService.joinSocket.write(data, withTimeout: -1.0, tag: 3)
    }
    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if err != nil {
            print("Socket Did Disconnect with Error \(String(describing: err)) with User Info \(err!.localizedDescription).", sock)
        } else {
            print("socketDidDisconnect with sock: \(sock)", sock)
        }
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        let str = String(decoding: data, as: UTF8.self)
        let astr = "Join did read \(str) with host port: \(sock.connectedPort)"
        print(astr)
    }
    
    func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        let astr = "Join did write data to host port: \(sock.connectedPort)"
        print(astr)
    }
    
}



