import Foundation

public struct CameraModule {
	public init() {
		
	}
	
	public func sendToCPlusPlus(_ value: Int) -> Bool {
		var cameraController = CameraController()
		return cameraController.sendToCPlusPlus(Int32(value))
	}
	
	public func sendToSwift(_ value: Int) -> Bool {
		let logStr = "[CameraModule] number : \(value)"
		print(logStr)
		return true
	}
}
