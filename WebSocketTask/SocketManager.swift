//
//  SocketManager.swift
//  WebSocketTask
//
//  Created by Evgeniy Opryshko on 13.04.2022.
//

import Foundation

protocol WebSocketProvider {
    
    var delegate: WebSocketProviderDelegate? { get set }
    
    func connect()
    func send(text: String)
    func send(data: Data)
    func closeConnection()
    
}

protocol WebSocketProviderDelegate: AnyObject {
    
    func webSocketDidReceiveData(_ socket: WebSocketProvider, didReceive: Data)
    func webSocketDidReceiveMessage(_ socket: WebSocketProvider, didReceive: String)
    func webSocketDidConnect(_ socket: WebSocketProvider)
    func webSocketDidDisconnect(_ socket: WebSocketProvider, _ error: Error?)
    func webSocketReceiveError(_ error: Error?)
    
}

class NativeWebSocket: NSObject, WebSocketProvider, URLSessionDelegate, URLSessionWebSocketDelegate {
    
    // MARK: - Private properties
    
    private var socket: URLSessionWebSocketTask?
    private let timeout: TimeInterval
    private let url: URL
    private(set) var isConnected: Bool = false
    
    // MARK: - Public properties
    
    weak var delegate: WebSocketProviderDelegate?
    
    init(url: URL, timeout: TimeInterval) {
        self.timeout = timeout
        self.url = url
        super.init()
    }
    
    // MARK: - Public methods
    
    func connect() {
        let configuration = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue())
        let urlRequest = URLRequest(url: url,timeoutInterval: timeout)
        socket = urlSession.webSocketTask(with: urlRequest)
        socket?.resume()
        readMessage()
    }
    
    func send(data: Data) {
        socket?.send(.data(data)) { error in
            self.handleError(error)
        }
    }
    
    func send(text: String) {
        socket?.send(.string(text)) { error in
            self.handleError(error)
        }
    }
    
    func closeConnection() {
        socket?.cancel(with: .goingAway, reason: nil)
        delegate?.webSocketDidDisconnect(self, nil)
    }
    
    // MARK: - Private methods
    
    private func readMessage() {
        socket?.receive { result in
            switch result {
            case .failure(_):
                break
            case .success(let message):
                switch message {
                case .data(let data):
                    self.delegate?.webSocketDidReceiveData(self, didReceive: data)
                case .string(let string):
                    self.delegate?.webSocketDidReceiveMessage(self, didReceive: string)
                @unknown default:
                    print("un implemented case found in NativeWebSocketProvider")
                }
                self.readMessage()
            }
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
        delegate?.webSocketDidConnect(self)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
    
    ///never call delegate?.webSocketDidDisconnect in this method it leads to close next connection
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            handleError(error)
        }
    }
    
    /// we need to check if error code is one of the 57 , 60 , 54 timeout no network and internet offline to notify delegate we disconnected from internet
    private func handleError(_ error: Error?) {
        if let error = error as NSError? {
            if error.code == 57  || error.code == 60 || error.code == 54 {
                isConnected = false
                closeConnection()
                delegate?.webSocketDidDisconnect(self, error)
            } else {
                delegate?.webSocketReceiveError(error)
            }
        }
    }
}
