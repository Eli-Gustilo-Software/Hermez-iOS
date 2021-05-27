# ![Hermez Logo](https://github.com/Eli-Gustilo-Software/Hermez/blob/main/hermez.png)
Version 0.5.0 (Beta), License MIT

Hermez is an application communications library that allows iOS, Android and Mac devices on the same local network to easily and automatically communicate with each other. Under the hood Hermez uses zero configuration to facilitate communications between different types of devices (see, Zero-configuration networking - Wikipedia).

- If you need the iOS version click here. <https://github.com/Eli-Gustilo-Software/Hermez-iOS>
- If you need the Android version click here. <https://github.com/Eli-Gustilo-Software/Hermez>

**Install on iOS/Mac**

Download code base and build the "hermez" or the "hermez_mac" framework target and then add the framework into your project.

<img src="/hermez_ios_targets.png" alt="hermez targets" width="400"/>

**How To Use on iOS/Mac**

Hermez implements 2 custom structs. One, HermezDevice representing a device found on the local network.

```swift
public struct HermezDevice: Codable, Equatable {
	public var name: String
}
```
Two, HermezMessage representing a message received from another device on the local network. Specifically, these classes are defined as follows.
```swift
public struct HermezMessage: Codable, Equatable {
	public var message: String?
	public var jsonData: String?
	public var messageID: String
	public var receivingDevice: HermezDevice
	public var sendingDevice: HermezDevice
}

```
There are 4 steps to using Hermez.

1. Set the service and device names. The service name is used to create a common communication service for all devices. All devices that use this service on the same network will be automatically discovered by Hermez. The device name is used to uniquely identify a specific device on the network.

```swift
Hermez.shared.setServiceAndDeviceName(serviceName: yourServiceName, 
deviceName: yourDeviceName)
```
	
2. Find available devices. There are three options for doing this. Option one, use the standard swift protocol/callback pattern by querying for all devices on the network.
```swift
Hermez.shared.findAvailableDevices()
```
  - Then listen for the callback of available devices  (by implementing the HermezCommProtocol protocol).
```swift
func availableDevices(devices: [HermesDevice]) {	
    print("devices found array list = \(devices)")
}
```
  - Option two, implement an RxSwift observable. For example,
```swift
HermezWithRx.shared.findDevicesObservable.subscribe { event in
    if let devices = event.element {
        // handle found devices
    }
}.disposed(by: disposeBag)
```
  - Option three, implement a Combine observable. For example,
```swift
self.devicesCancellable =  HermezWithCombine.shared.devicesObservable
      .removeDuplicates()
      .sink { devices in
          // handle found devices
      }
```
3. send messages. 
```swift
Hermez.shared.sendMessageToDevices(message: yourMessage, 
    json: yourJsonAsString, 
    messageID: yourMessageID, 
    devices: yourArrayOfDevices)
```
4. Listen for messages from other devices on the network.  There are three options for doing this. Option one, use the standard swift protocol/callback pattern (by implementing the HermezCommProtocol protocol).
```swift
override func messageReceived(message: messageReceived) {
    // handle message received of type HermezMessage
}
```
  - Option two, implement an RxSwift observable. For example,
```swift
HermezWithRx.shared.messagesObservable.subscribe { messageEvent in
    if let message = messageEvent.element {
        //handle message            	
    }
}.disposed(by: disposeBag)
```
  - Option three, implement a Combine observable. For example,
```swift
self.messageCancellable =  HermezWithCombine.shared.messageObservable
    .sink { message in
        if !self.data.contains(message) {
            // handle message
        }
    }
```

