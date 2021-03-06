import AFNetworking
import SwiftyBeaver

class HttpRequestManager: NSObject {
    let maxRetryCount = 3
    
    fileprivate let queue = OperationQueue()
    
    fileprivate var currentlyFlushing = false
    fileprivate var lastRequestIds = [String]()
    
    fileprivate var appDelegate: AppDelegate {
        get {
            return UIApplication.shared.delegate as! AppDelegate
        }
    }
    public func dispatch(_ request: HttpRequest, completion: ((_ success: Bool) -> Void)? = nil) {
        dispatch(request, retry: 0, completion: completion)
    }
    
    public func dispatch(_ request: HttpRequest, retry: Int, completion: ((_ success: Bool) -> Void)? = nil) {
        
        SwiftyBeaver.self.debug("Dispatch request: \(request)")
        
        let configuration = URLSessionConfiguration.default
        let manager = AFHTTPSessionManager(sessionConfiguration: configuration)
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.securityPolicy = .locativePolicy
        
        if let h = request.httpAuth,
            let u = request.httpAuthUsername,
            let p = request.httpAuthPassword , h.boolValue {
            manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(
                u,
                password: p
            )
        }
        
        // bail out in case no url is present in request
        guard let url = request.url else { return SwiftyBeaver.self.debug("bailing out due to no url") }
        if let m = request.method , isPostMethod(m) {
            manager.post(url, parameters: request.parameters, success: { [weak self] op, r in
                guard let this = self else { return SwiftyBeaver.self.debug("bailing out due to no self") }
                this.dispatchFencelog(
                    true,
                    request: request,
                    responseObject: r as AnyObject?,
                    responseStatus: (op.response as? HTTPURLResponse)?.statusCode ?? 0,
                    error: nil,
                    completion: completion
                )
                }, failure: { [weak self] op, e in
                    guard let this = self else { return SwiftyBeaver.self.debug("bailing out due to no self") }
                    if retry < this.maxRetryCount {
                        return this.dispatch(request, retry: retry + 1, completion: completion)
                    }
                    this.dispatchFencelog(
                        false,
                        request: request,
                        responseObject: nil,
                        responseStatus: (op?.response as? HTTPURLResponse)?.statusCode ?? 0,
                        error: e as NSError?,
                        completion: completion
                    )
            })
        } else {
            manager.get(url, parameters: request.parameters, success: { [weak self] op, r in
                guard let this = self else { return SwiftyBeaver.self.debug("bailing out due to no self") }
                this.dispatchFencelog(
                    true,
                    request: request,
                    responseObject: r as AnyObject?,
                    responseStatus: (op.response as? HTTPURLResponse)?.statusCode ?? 0,
                    error: nil,
                    completion: completion
                )
                }, failure: { [weak self] op, e in
                    guard let this = self else { return SwiftyBeaver.self.debug("bailing out due to no self") }
                    if retry < this.maxRetryCount {
                        return this.dispatch(request, retry: retry + 1, completion: completion)
                    }
                    this.dispatchFencelog(
                        false,
                        request: request,
                        responseObject: nil,
                        responseStatus: (op?.response as? HTTPURLResponse)?.statusCode ?? 0,
                        error: e as NSError?,
                        completion: completion
                    )
            })
        }
    }
}

private extension HttpRequestManager {
    func main(_ closure:@escaping ()->Void) {
        DispatchQueue.main.async(execute: closure)
    }
}

//MARK: - Private
extension HttpRequestManager {
    func dispatchFencelog(_ fencelog: Fencelog) {
        if let a = appDelegate.settings.apiToken , a.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            appDelegate.cloudManager.dispatchCloudFencelog(fencelog, onFinish: nil)
        }
    }
    
    func dispatchFencelog(_ success: Bool,
                          request: HttpRequest,
                          responseObject: AnyObject?,
                          responseStatus: Int?,
                          error: NSError?,
                          completion: ((_ success: Bool) -> Void)?) {
        
        if let method = request.method, let n = appDelegate.settings.notifyOnSuccess , n.boolValue && success {

            var message = isPostMethod(method) ? NSLocalizedString("POST Success:", comment: "POST Success text") : NSLocalizedString("GET Success:", comment: "GET Success text")

            if let id = request.eventId {
                message = "[\(id)] ".appending(message)
            }
            
            // notify on success
            if let data = responseObject as? Data, let string = String(data: data, encoding: String.Encoding.utf8) {
                presentLocalNotification(
                    message.appendingFormat(" %@", string),
                    success: true
                )
            } else {
                presentLocalNotification(
                    message.appendingFormat(" %@", "No readable response received."),
                    success: true
                )
            }
        } else if let method = request.method, let n = appDelegate.settings.notifyOnFailure , n.boolValue && !success {
            
            var message = (isPostMethod(method) ? NSLocalizedString("POST Failure:", comment: "POST Failure text") : NSLocalizedString("GET Failure:", comment: "GET Failure text"))
            
            if let id = request.eventId {
                message = "[\(id)] ".appending(message)
            }
            
            // notify on failure
            if let data = responseObject as? Data, let string = String(data: data, encoding: String.Encoding.utf8) {
                presentLocalNotification(
                    message.appendingFormat(" %@", string),
                    success: true
                )
            } else {
                presentLocalNotification(
                    message.appendingFormat(" %@", "No readable response received."),
                    success: true
                )
            }
        }
        
        // dispatch fencelog
        let fencelog = Fencelog()
        
        if let parameters = request.parameters {
            
            if let l = parameters["latitude"] as? NSNumber {
                fencelog.latitude = l
            }
            if let l = parameters["longitude"] as? NSNumber {
                fencelog.longitude = l
            }
            if let i = parameters["id"] as? String {
                fencelog.locationId = i
            }
            fencelog.eventType = parameters["trigger"] as? String
        }
        
        if let eventType = request.eventType {
            fencelog.fenceType = eventType.int32Value == 0 ? "geofence" : "ibeacon"
        }

        fencelog.httpUrl = request.url
        fencelog.httpMethod = request.method
        
        if let s = responseStatus {
            fencelog.httpResponseCode = NSNumber(value: s as Int)
        }

        dispatchFencelog(fencelog)
        DispatchQueue.main.async { 
            completion?(success)
        }
        
    }
    
    func presentLocalNotification(_ text: String, success: Bool) {
        UILocalNotification.present(
            withSoundName: (appDelegate.settings.soundOnNotification?.boolValue == true) ? "notification.caf" : nil,
            alertBody: text,
            userInfo: ["success": success])
    }
    
    func isPostMethod(_ method: String) -> Bool {
        return method == "POST"
    }
}
