//
//  Shared.swift
//  SwiftLocation
//
//  Created by Daniele Margutti on 08/01/2017.
//  Copyright © 2017 Daniele Margutti. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

/// Grand Central Dispatch Queues
/// This is essentially a wrapper around GCD Queues and allows you to specify a queue in which operation will be executed in.
///
/// More on GCD QoS info are available [here](https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html).
///
/// - background: Should we used when work takes significant time, such as minutes or hours. Work is not visible to the user, such as indexing, synchronizing, and backups. Focuses on energy efficiency.
/// - main: The serial queue associated with the application’s main thread.
/// - userInteractive: Should we used when work is virtually instantaneous (work that is interacting with the user, such as operating on the main thread, refreshing the user interface, or performing animations. If the work doesn’t happen quickly, the user interface may appear frozen. Focuses on responsiveness and performance).
/// - userInitiated: Should we used when work is nearly instantaneous, such as a few seconds or less (work that the user has initiated and requires immediate results, such as opening a saved document or performing an action when the user clicks something in the user interface. The work is required in order to continue user interaction. Focuses on responsiveness and performance).
/// - utility: Should we used when work takes a few seconds to a few minutes (work that may take some time to complete and doesn’t require an immediate result, such as downloading or importing data. Utility tasks typically have a progress bar that is visible to the user. Focuses on providing a balance between responsiveness, performance, and energy efficiency).
/// - custom: provide a custom queue
public enum Context {
	case background
	case main
	case userInteractive
	case userInitiated
	case utility
	case custom(queue: DispatchQueue)
	
	public var queue: DispatchQueue {
		switch self {
		case .background:
			return DispatchQueue.global(qos: .background)
		case .main:
			return DispatchQueue.main
		case .userInteractive:
			return DispatchQueue.global(qos: .userInteractive)
		case .userInitiated:
			return DispatchQueue.global(qos: .userInitiated)
		case .utility:
			return DispatchQueue.global(qos: .utility)
		case .custom(let queue):
			return queue
		}
	}
	
}


/// This represent the state of a request
///
/// - idle: an idle request is not part of the main location queue. It's the initial state of a request before.
/// - waitingUserAuth: this is a paused state. Request is running but actually it's paused waiting for user authorization.
/// - running: a running request can receive events about location manager
/// - paused: a paused request its part of the location queue but does not receive events
/// - failed: a failed request its a request
public enum RequestState: CustomStringConvertible, Equatable, Hashable {
	case idle
	case waitingUserAuth
	case running
	case paused
	case failed(_: Error)
	
	public static func ==(lhs: RequestState, rhs: RequestState) -> Bool {
		switch (lhs, rhs) {
		case (.idle, .idle):						return true
		case (.waitingUserAuth, .waitingUserAuth):	return true
		case (.running, .running):					return true
		case (.paused, .paused):					return true
		case (.failed(let f1), .failed(let f2)):	return (f1.localizedDescription == f2.localizedDescription)
		default:									return false
		}
	}
	
	public var hashValue: Int {
		return self.description.hashValue
	}
	
	public var description: String {
		switch self {
		case .idle:				return "idle"
		case .running:			return "running"
		case .paused:			return "paused"
		case .failed(let e):	return "failed: \(e)"
		case .waitingUserAuth:	return "waiting auth"
		}
	}
	
	public var isRunning: Bool {
		switch self {
		case .running, .failed(_), .idle:
			return true
		default:
			return false
		}
	}
	
	public var isPaused: Bool {
		switch self {
		case .waitingUserAuth, .paused, .failed(_):
			return true
		default:
			return false
		}
	}
}

/// Public Request Protocol
public protocol Request: class, Hashable, Equatable, CustomStringConvertible {
	
	func resume()
	func pause()
	func cancel()
	
	func onResume()
	func onPause()
	func onCancel()
	
	var state: RequestState { get }
	
	var requiredAuth: Authorization { get }
	
	var isBackgroundRequest: Bool { get }
	
	func dispatch(error: Error)
	
	var isInQueue: Bool { get }
	
	var name: String? { get set }
}

/// Location errors
///
/// - missingAuthInInfoPlist: missing authorization strings (`NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` in Info.plist)
/// - authDidChange: authorization is changed to `.denied` or `.restricted` mode. Location services are not available anymore.
/// - timeout: timeout for request is reached
/// - serviceNotAvailable: hardware does not support required service
/// - backgroundModeNotSet: one or more requests needs background capabilities enabled (see `UIBackgroundModes` in Info.plist)
public enum LocationError: Error {
	case missingAuthInInfoPlist
	case authDidChange(_: CLAuthorizationStatus)
	case timeout
	case serviceNotAvailable
	case requireAlwaysAuth
	case authorizationDenided
	case backgroundModeNotSet
	case noData
	case invalidData
	case other(_: String)
}

public enum Authorization : CustomStringConvertible, Comparable, Equatable {
	case always
	case inuse
	case both
	case none
	
	public var rawValue: String {
		switch self {
		case .always:	return "NSLocationAlwaysUsageDescription"
		case .inuse:	return "NSLocationWhenInUseUsageDescription"
		default:		return ""
		}
	}
	
	private var order: Int {
		switch self {
		case .both:		return 0
		case .always:	return 1
		case .inuse:	return 2
		case .none:		return 3
		}
	}
	
	public var description: String {
		switch self {
		case .both:		return "Both"
		case .always:	return "Always"
		case .inuse:	return "When In Use"
		case .none:		return "None"
		}
	}
	
	public static func <(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order < rhs.order
	}
	
	public static func <=(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order <= rhs.order
	}
	
	public static func >(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order > rhs.order
	}
	
	public static func >=(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order >= rhs.order
	}
	
	public static func ==(lhs: Authorization, rhs: Authorization) -> Bool {
		return lhs.order == rhs.order
	}
}

public enum LocAuth {
	case disabled
	case undetermined
	case denied
	case restricted
	case alwaysAuthorized
	case inUseAuthorized
	
	public static var status: LocAuth {
		guard CLLocationManager.locationServicesEnabled() else {
			return .disabled
		}
		switch CLLocationManager.authorizationStatus() {
		case .notDetermined:		return .undetermined
		case .denied:				return .denied
		case .restricted:			return .restricted
		case .authorizedAlways:		return .alwaysAuthorized
		case .authorizedWhenInUse:	return .inUseAuthorized
		}
	}
	
	public static var isAuthorized: Bool {
		switch LocAuth.status {
		case .alwaysAuthorized, .inUseAuthorized:
			return true
		default:
			return false
		}
	}
}

public extension CLLocationManager {
	
	public static var appAuthorization: Authorization {
		guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"), let dict = NSDictionary(contentsOfFile: path) else {
			return .none
		}
		var isAlways = false
		var isWhenInUse = false
		if let _ = dict[Authorization.always.rawValue] {
			isAlways = true
		}
		if let _ = dict[Authorization.inuse.rawValue] {
			isWhenInUse = true
		}
		
		if isWhenInUse && isAlways {
			return .both
		} else {
			if isWhenInUse {
				return .inuse
			} else if isAlways {
				return .always
			}
			return .none
		}
	}
	
	public static var isBackgroundUpdateEnabled: Bool {
		if let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? NSArray {
			if backgroundModes.contains("location") && backgroundModes.contains("fetch") {
				return true
			}
		}
		return false
	}

}
