//
//  SwiftLocation - Efficient Location Tracking for iOS
//
//  Created by Daniele Margutti
//   - Web: https://www.danielemargutti.com
//   - Twitter: https://twitter.com/danielemargutti
//   - Mail: hello@danielemargutti.com
//
//  Copyright © 2019 Daniele Margutti. Licensed under MIT License.

import Foundation

public extension LocationByIPRequest {
    
    enum Service: CustomStringConvertible {
        case ipAPI
        case ipApiCo
        case ipINFO
        
        public static let all: [Service] = [.ipAPI, .ipApiCo, .ipINFO]
        
        public var description: String {
            switch self {
            case .ipAPI:
                return "ipAPI"
            case .ipApiCo:
                return "ipApiCo"
            case .ipINFO:
                return "ipINFO"
            }
        }
    }
    
}
