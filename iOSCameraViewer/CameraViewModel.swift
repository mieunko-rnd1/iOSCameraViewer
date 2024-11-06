import Foundation
import CoreImage

@Observable
class CameraViewModel {
	var currentFrame: CGImage?
	
	private let cameraManager = CameraManager()
	
	init() {
		Task {
			await handleCameraPreviews()
		}
	}
	
	func handleCameraPreviews() async {
		for await image in cameraManager.previewStream {
			Task { @MainActor in
				currentFrame = image
			}
		}
	}
	
	func connectDevice() {
		cameraManager.connectDevice()
	}
	
	func disconnctDevice() {
		cameraManager.disconnectDevice()
	}
	
	func startCapture() {
		cameraManager.startCatpure()
	}
	
	func stopCapture() {
		cameraManager.stopCapture()
	}
}

