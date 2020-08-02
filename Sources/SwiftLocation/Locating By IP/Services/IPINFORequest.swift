//
//  IPINFORequest.swift
//  SwiftLocation-iOS
//
//  Created by armin on 8/2/20.
//  Copyright © 2020 SwiftLocation. All rights reserved.
//

import Foundation

public class IPINFORequest: LocationByIPRequest {
    
    private var jsonOperation: JSONOperation?
    
    public override var service: LocationByIPRequest.Service {
        return .ipINFO
    }

    public override func start() {
        let url = URL(string: "https://ipinfo.io/json")!
        self.jsonOperation = JSONOperation(url, timeout: self.timeout?.interval)
        self.jsonOperation?.start { response in
            switch response {
            case .failure(let error):
                self.stop(reason: error, remove: true)
                
            case .success(let json):
                let ip: String? = valueAtKeyPath(root: json, ["ip"])
                guard let _ = ip else {
                    self.stop(reason: .generic("General failure"), remove: true)
                    return
                }
                
                let place = IPPlace(ipINFOJSON: json)
                self.value = place
                self.dispatch(data: .success(place), andComplete: true)
            }
        }
    }
    
    public override func stop(reason: LocationManager.ErrorReason = .cancelled, remove: Bool) {
        jsonOperation?.stop()
        super.stop(reason: reason, remove: remove)
    }
    
}
