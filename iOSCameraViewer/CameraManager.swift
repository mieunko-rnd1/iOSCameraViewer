import AVFoundation
import CoreImage

class CameraManager: NSObject {
	private var permissionGranted: Bool = false
	private var isConnected: Bool = false
	private var captureSession: AVCaptureSession = AVCaptureSession() // 해당 객체 생성으로 입력(비디오, 오디오)을 캡쳐 할 수 있음
	private var addToPreviewStream: ((CGImage) -> Void)?
	
	lazy var previewStream: AsyncStream<CGImage> = {
		AsyncStream { continuation in
			addToPreviewStream = { cgImage in
				continuation.yield(cgImage)
			}
		}
	}()
	
	private var isAuthorized: Bool {
		get async {
			let status = AVCaptureDevice.authorizationStatus(for: .video)
			
			// Determine if the user previously authorized camera access.
			var isAuthorized = status == .authorized
			
			// If the system hasn't determined the user's authorization status,
			// explicitly prompt them for approval.
			if status == .notDetermined {
				isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
			}
			
			return isAuthorized
		}
	}
	
	private var isCameraExist: Bool {
		get async {
			let sessions = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
			let devices = sessions.devices
			var isFound: Bool = false
			
			for device in devices {
				switch device.localizedName {
				case "C270 HD WEBCAM":
					isFound = true
					break;
				case "Medit MO3":
					isFound = true
					break;
				default:
					break;
				}
			}
			
			return isFound
		}
	}
	
	override init() {
		super.init()
	}
	
	func connectDevice() {
		Task {
			await configureSession()
		}
	}
	
	func disconnectDevice() {
		isConnected = false
		
		captureSession.beginConfiguration()
		
		for input in captureSession.inputs {
			captureSession.removeInput(input);
		}
		
		for output in captureSession.outputs {
			captureSession.removeOutput(output);
		}
		
		captureSession.commitConfiguration()
	}
	
	func startCatpure() {
		if !isConnected {
			print("Device is not connected...!")
			return
		}
		
		startSession()
	}
	
	func stopCapture() {
		stopSession()
	}
	
	private func getDetectCameraDevicesCount() -> Int {
		var count = 0;
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		
		for device in devices {
			let deviceID = device.uniqueID
			let deviceName = device.localizedName
			print("\(deviceID): \(deviceName)")
			count += 1
		}
		
		return count
	}
	
	private func getDetectCameraDeviceName() -> String {
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		
		for device in devices {
			switch device.localizedName {
			case "C270 HD WEBCAM":
				return device.localizedName
			case "Medit MO3":
				return device.localizedName
			default:
				break;
			}
		}
		
		return ""
	}
	
	private func prepareVideoInput(device: AVCaptureDevice, session: AVCaptureSession ) -> Bool {
		print(#function)
		
		do {
			let input = try AVCaptureDeviceInput(device: device)
			
			// 세션에 데이터 입력 추가
			if session.canAddInput(input) {
				session.addInput(input)
				return true
			}
		} catch let error {
			print(error.localizedDescription)
		}
		
		return false
	}
	
	private func prepareVideoOutput(session: AVCaptureSession) -> Bool {
		print(#function)
		
		let videoOutput = AVCaptureVideoDataOutput()
		videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
		
		// 세션에 데이터 출력 추가
		if session.canAddOutput(videoOutput) {
			session.addOutput(videoOutput)
			
			// queue 추가
			let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
			videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
			
			return true
		}
		
		return false
	}
	
	private func configureSession() async {
		print(#function)
		
		guard await isAuthorized else {
			print("Permission is not granted...!")
			return
		}
		
		guard await isCameraExist else {
			print("Cannot found camera device...!")
			return
		}
		
		let capureDeviceName = getDetectCameraDeviceName()
		if capureDeviceName.isEmpty {
			print("Cannot detect camera device name...!")
			return
		}
		
		let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: .video, position: .unspecified)
		let devices = discoverySession.devices
		guard !devices.isEmpty else {
			print("Cannot found capture devices...!")
			return
		}
		
		// Capture Session에 대한 입력을 제공
		var captureDevice = AVCaptureDevice.default(.external, for: .video, position: .unspecified)!
		for device in devices {
			if device.localizedName == capureDeviceName {
				captureDevice = device
				print("Found capture device: \(device.localizedName)")
				break;
			}
			else {
				print("Cannot found capture device...!")
				return
			}
		}
		
		let session = AVCaptureSession()
		session.sessionPreset = .inputPriority // 캡처 세션에 대한 오디오 및 비디오 출력 설정을 지정하지 않음
		
		session.beginConfiguration()
		
		if !prepareVideoInput(device: captureDevice, session: session) {
			print("Cannot found video input...!")
			session.commitConfiguration()
			return
		}
		
		if !prepareVideoOutput(session: session) {
			print("Cannot found video output...!")
			session.commitConfiguration()
			return
		}
		
		// session 구성 시작
		session.commitConfiguration()
		
		// local에서 구성한 session을 global 변수에 저장
		captureSession = session
		isConnected = true
	}
	
	private func startSession() {
		if captureSession.isRunning { return }
		
		DispatchQueue.global(qos: .userInitiated).async { [self] in
			print("session start")
			captureSession.startRunning() // data flow 시작
		}
	}
	
	private func stopSession() {
		if !captureSession.isRunning { return }
		/*
		DispatchQueue.global(qos: .userInitiated).async { [self] in
			print("session stop")
			captureSession.stopRunning() // data flow 멈춤
		}
		*/
		print("session stop")
		captureSession.stopRunning() // data flow 멈춤
	}
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let currentFrame = sampleBuffer.cgImage else {
			print("Can't translate to CGImage...!")
			return
		}
		addToPreviewStream?(currentFrame)
	}
}

extension CMSampleBuffer {
	var cgImage: CGImage? {
		let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(self)
		guard let imagePixelBuffer = pixelBuffer else { return nil }
		return CIImage(cvPixelBuffer: imagePixelBuffer).cgImage
	}
}

extension CIImage {
	var cgImage: CGImage? {
		let ciContext = CIContext()
		guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
		return cgImage
	}
}
