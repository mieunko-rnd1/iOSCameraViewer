import Foundation

public struct CameraModule {
	var cameraController = CameraController()
	
	public init() {
		
	}
	
	public func decodeMjpegData(_ data: UnsafePointer<UInt8>, _ size: Int32) -> Array<UInt8> {
		var cameraController = CameraController()
		
		let rawData = Array<UInt8>(cameraController.decodeMjpegData(data, size))
		
		return rawData
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
