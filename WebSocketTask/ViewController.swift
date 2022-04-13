//
//  ViewController.swift
//  WebSocketTask
//
//  Created by Evgeniy Opryshko on 13.04.2022.
//

import UIKit

class ViewController: UIViewController {
    
    private var webSocketManager: WebSocketProvider?
    private let url = URL(string: "wss://ws.finnhub.io?token=c9b9ipaad3idfn1sr540")! // for testing
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webSocketManager = NativeWebSocket(url: url, timeout: 10)
        webSocketManager?.delegate = self
        webSocketManager?.connect()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        webSocketManager?.send(text: """
{"type":"subscribe","symbol":"AAPL"}
""")
        
        webSocketManager?.send(text: "test")
    }
    
}

// MARK: - SocketManagerDelegate

extension ViewController: WebSocketProviderDelegate {
    
    func webSocketDidReceiveData(_ socket: WebSocketProvider, didReceive data: Data) {
        print(data)
    }
    
    func webSocketDidReceiveMessage(_ socket: WebSocketProvider, didReceive message: String) {
        print("webSocketDidReceiveMessage")
        print(message)
    }
    
    func webSocketDidConnect(_ socket: WebSocketProvider) {
        print("WebSocketDidConnect")
    }
    
    func webSocketDidDisconnect(_ socket: WebSocketProvider, _ error: Error?) {
        print("webSocketDidDisconnect")
    }
    
    func webSocketReceiveError(_ error: Error?) {
        print("webSocketReceiveError")
    }
    
}
