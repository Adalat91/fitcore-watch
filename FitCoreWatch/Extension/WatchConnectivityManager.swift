import Foundation
import WatchConnectivity

protocol WatchConnectivityDelegate: AnyObject {
    func didReceiveMessage(_ message: WatchMessage)
}

class WatchConnectivityManager: NSObject, ObservableObject {
    weak var delegate: WatchConnectivityDelegate?
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    func sendMessage(_ type: WatchMessageType, data: Data?) {
        guard let session = session, session.isReachable else {
            print("iPhone not reachable")
            return
        }
        
        let message = WatchMessage(type: type, data: data)
        
        do {
            let messageData = try JSONEncoder().encode(message)
            let messageDict = ["message": messageData]
            
            session.sendMessage(messageDict, replyHandler: { response in
                print("Message sent successfully: \(response)")
            }, errorHandler: { error in
                print("Error sending message: \(error)")
            })
        } catch {
            print("Error encoding message: \(error)")
        }
    }
    
    func sendUserInfo(_ userInfo: [String: Any]) {
        guard let session = session else { return }
        
        session.transferUserInfo(userInfo)
    }
    
    func updateApplicationContext(_ context: [String: Any]) {
        guard let session = session else { return }
        
        do {
            try session.updateApplicationContext(context)
        } catch {
            print("Error updating application context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error)")
        } else {
            print("WCSession activated successfully")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let messageData = message["message"] as? Data else { return }
        
        do {
            let watchMessage = try JSONDecoder().decode(WatchMessage.self, from: messageData)
            DispatchQueue.main.async {
                self.delegate?.didReceiveMessage(watchMessage)
            }
        } catch {
            print("Error decoding message: \(error)")
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        print("Received user info: \(userInfo)")
        // Handle user info updates
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received application context: \(applicationContext)")
        // Handle application context updates
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Session reachability changed: \(session.isReachable)")
    }
}

