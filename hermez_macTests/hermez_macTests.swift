//
//  hermez_macTests.swift
//  hermez_macTests
//
//  Created by Nicholas Gustilo on 3/23/21.
//

import XCTest
@testable import Hermez_Mac

enum TestNames {
    case TEST_SET_SERVICE
    case TEST_FIND_DEVICES
    case TEST_MESSAGES
}

class hermez_macTests: XCTestCase {

    var exp: XCTestExpectation?
    var noDevices = 0
    var device: HermezDevice?
    var validMessage = false
    var testName = TestNames.TEST_SET_SERVICE
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        Hermez.shared.stopService()
    }

    func testSetServiceAndDeviceName() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        exp = expectation(description: "\(#function)\(#line)")
        
        self.testName = TestNames.TEST_SET_SERVICE
        Hermez.shared.addDataDelegate(delegate: self)
        let json = "{\"name\" : \"Dusty\", \"breed\": \"Poodle\", \"age\": 7}"
        assert(Hermez.shared.setServiceAndDeviceName(serviceName: "blah", deviceName: "test2", deviceJson: json))
        
        waitForExpectations(timeout: 2) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                 assertionFailure("serviceNotStarted")
            }
        }
        assert(true)
    }

    func testFindAvailableDevices() throws {
        exp = expectation(description: "\(#function)\(#line)")
        self.testName = TestNames.TEST_FIND_DEVICES
        Hermez.shared.addDataDelegate(delegate: self)
        let json = "{\"name\" : \"Dusty\", \"breed\": \"Poodle\", \"age\": 7}"
        assert(Hermez.shared.setServiceAndDeviceName(serviceName: "blah", deviceName: "test2", deviceJson: json))
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                 assertionFailure("no devices found")
            }
        }
        assert(self.noDevices > 0)
    }
    
    func testSendMessageToDevices() throws {
        self.testName = TestNames.TEST_MESSAGES
        Hermez.shared.addDataDelegate(delegate: self)
        let json = "{\"name\" : \"Dusty\", \"breed\": \"Poodle\", \"age\": 7}"
        assert(Hermez.shared.setServiceAndDeviceName(serviceName: "blah", deviceName: "test2", deviceJson: json))
        exp = expectation(description: "\(#function)\(#line)")
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                 assertionFailure("no message received")
            }
        }
        assert(self.validMessage)
    }
}

extension hermez_macTests: HermezDataProtocol {
    func availableDevices(devices: [HermezDevice]) {
        for device in devices {
            print("device = \(device.name)")
            self.device = device
        }
        self.noDevices = devices.count
        switch(self.testName) {
        case .TEST_SET_SERVICE:
            self.exp?.fulfill()
            self.exp = nil
        case .TEST_FIND_DEVICES:
            self.exp?.fulfill()
            self.exp = nil
        case .TEST_MESSAGES:
            if let theDevice = self.device {
                let json = "{\"name\" : \"Dusty\", \"breed\": \"Poodle\", \"age\": 7}"
                Hermez.shared.sendMessageToDevices(message: "A test message", json: json, devices: [theDevice], messageID: "0001")
            }
        }
    }
    
    func messageReceived(message: HermezMessage) {
        if let theMessage = message.message {
            print(theMessage)
        }
        validMessage = true
        if (testName == TestNames.TEST_MESSAGES) {
            self.exp?.fulfill()
            self.exp = nil
        }
    }
    
    func serviceStarted(serviceType: String, serviceName: String) {
        print("serviceStarted type = \(serviceType), name = \(serviceName)")
        if serviceType == "_blah._tcp.", serviceName == "test2" {
            switch(self.testName) {
            case .TEST_SET_SERVICE:
                self.exp?.fulfill()
                self.exp = nil
            case .TEST_FIND_DEVICES:
                Hermez.shared.findAvailableDevices()
            case .TEST_MESSAGES:
                Hermez.shared.findAvailableDevices()
            }
        }
    }
}
