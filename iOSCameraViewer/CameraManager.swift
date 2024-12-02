import AVFoundation
import UIKit
import CoreImage
import CameraInterop

class CameraManager: NSObject {
	private var permissionGranted: Bool = false
	private var isConnected: Bool = false
	private var captureSession: AVCaptureSession = AVCaptureSession() // 해당 객체 생성으로 입력(비디오, 오디오)을 캡쳐 할 수 있음
	private var addToPreviewStream: ((CGImage) -> Void)?
	
	private var isWebCam: Bool = false
	
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
					isWebCam = true
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
	
	func listSupportedInputFormats(for device: AVCaptureDevice) {
		for format in device.formats {
			let description = format.formatDescription
			let mediaType = description.mediaType
			let subType = description.mediaSubType

			let dimensions = CMVideoFormatDescriptionGetDimensions(description)
			let width = dimensions.width
			let height = dimensions.height

			let frameRates = format.videoSupportedFrameRateRanges
			let minFrameRate = frameRates.first?.minFrameRate ?? 0
			let maxFrameRate = frameRates.first?.maxFrameRate ?? 0

			let fourCC = subType.rawValue
			let fourCCString = String(format: "%c%c%c%c",
									  (fourCC >> 24) & 0xff,
									  (fourCC >> 16) & 0xff,
									  (fourCC >> 8) & 0xff,
									  fourCC & 0xff)

			print("Supported Input Format: \(fourCCString), Width: \(width), Height: \(height), Min FPS: \(minFrameRate), Max FPS: \(maxFrameRate)")
		}
	}
	
	func listSupportedOutputFormats(for output: AVCaptureVideoDataOutput) {
		let supportedPixelFormats = output.availableVideoPixelFormatTypes
		for currentPixelFormat in supportedPixelFormats {
			let fourCCString = String(format: "%c%c%c%c",
									  (currentPixelFormat >> 24) & 0xff,
									  (currentPixelFormat >> 16) & 0xff,
									  (currentPixelFormat >> 8) & 0xff,
									  currentPixelFormat & 0xff)
			
			print("Supported Output Format: \(fourCCString)")
		}
	}

	func setVideoInputFormat(device: AVCaptureDevice, width: Int32, height: Int32, frameRate: Double, fourCC: String) -> Bool {
		for format in device.formats {
			let description = format.formatDescription
			let dimensions = CMVideoFormatDescriptionGetDimensions(description)
			let frameRates = format.videoSupportedFrameRateRanges
			let minFrameRate = frameRates.first?.minFrameRate ?? 0
			let maxFrameRate = frameRates.first?.maxFrameRate ?? 0

			let subType = description.mediaSubType
			let fourCCString = String(format: "%c%c%c%c",
									  (subType.rawValue >> 24) & 0xff,
									  (subType.rawValue >> 16) & 0xff,
									  (subType.rawValue >> 8) & 0xff,
									  subType.rawValue & 0xff)

			if dimensions.width == width && dimensions.height == height && fourCCString == fourCC && minFrameRate <= frameRate && maxFrameRate >= frameRate {
				do {
					try device.lockForConfiguration()
					device.activeFormat = format
					device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
					device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
					device.unlockForConfiguration()
					return true
				} catch {
					print("Error setting video format: \(error.localizedDescription)")
					return false
				}
			}
		}
		return false
	}
	
	private func prepareVideoInput(device: AVCaptureDevice, session: AVCaptureSession ) -> Bool {
		print(#function)
		
		do {
			listSupportedInputFormats(for: device)
			
			// 원하는 포맷 설정
			let width: Int32 = 1104
			let height: Int32 = 6440
			let frameRate: Double = 30.0
			let fourCC: String = "420f" // 예: "420v" 또는 "420f"
			
			if !setVideoInputFormat(device: device, width: width, height: height, frameRate: frameRate, fourCC: fourCC) {
				print("Failed to set video format")
				return false
			}
			
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
		
		// 여기에서 pixel format과 width, height 값을 변경할 수 있음
		let output = AVCaptureVideoDataOutput()
		if (isWebCam) {
			output.videoSettings = [
				kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
			]
		}
		else {
			listSupportedOutputFormats(for: output)
			
			output.videoSettings = [
				kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
				// kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange
				// kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarFullRange
				// kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarVideoRange
				// kCVPixelFormatType_Lossy_420YpCbCr8BiPlanarFullRange
				// kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, 420v
				// kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, 420f
				//kCVPixelBufferWidthKey as String: 1104, // 1920 // 1104
				//kCVPixelBufferHeightKey as String: 6440 // 1080 // 6440
			]
			
			output.alwaysDiscardsLateVideoFrames = false
		}
		
		// 세션에 데이터 출력 추가
		if session.canAddOutput(output) {
			session.addOutput(output)
			
			// queue 추가
			let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
			output.setSampleBufferDelegate(self, queue: videoQueue)
			
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
		session.sessionPreset = .inputPriority
		
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

func convertCIImageToUIImage(cmage: CIImage) -> UIImage {
	let context = CIContext(options: nil)
	let cgImage = context.createCGImage(cmage, from: cmage.extent)!
	let image = UIImage(cgImage: cgImage)
	return image
}

func convertNSDataToByteArray(nsData: NSData) -> Array<UInt8> {
	let count = nsData.length / MemoryLayout<Int8>.size
	var bytes = [UInt8](repeating: 0, count: count)
	
	// copy bytes into array
	nsData.getBytes(&bytes, length:count * MemoryLayout<Int8>.size)
	
	var byteArray:Array = Array<UInt8>()
	
	for i in 0 ..< count {
		byteArray.append(bytes[i])
	}
	
	return byteArray
}

func rgbaArrayToUIImage(data:[UInt8], width:Int, height:Int) -> UIImage? {
	var data = data
	
	guard let provider = CGDataProvider(data: NSData(bytes: &data, length: data.count)) else {
		return nil
	}
	
	guard let cgimage = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent) else {
		return nil
	}
	
	return UIImage(cgImage: cgimage)
}

var imageSaveCount: Int = 0
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let currentFrame = sampleBuffer.cgImage else {
			print("Cannot translate to CGImage...!")
			return
		}
		addToPreviewStream?(currentFrame)
		
		// 포맷 설명 가져오기
		guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
			print("포맷 설명을 가져올 수 없습니다.")
			return
		}
		
		// 해상도 추출
		let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
		
		// fps 추출
		var fps = 0.0
		
		// 샘플 버퍼에서 presentationTimeStamp와 duration 가져오기
		let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
		let duration = CMSampleBufferGetDuration(sampleBuffer)
		
		// 프레임 간 시간 계산
		let durationSeconds = CMTimeGetSeconds(duration)
		let presentationTimeSeconds = CMTimeGetSeconds(presentationTime)
		
		if durationSeconds > 0 {
			// FPS 계산: 1초를 샘플 간 간격으로 나눈 값
			fps = 1 / durationSeconds
		}
		
		// 현재 output으로 들어오는 format 값 읽어옴
		print("현재 해상도: \(dimensions.width)x\(dimensions.height), 포맷: \(formatDescription.mediaSubType), FPS 범위: \(fps)")
		
		// Get Raw Pixel
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("Cannot get image buffer...!")
			return
		}
		
		guard CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess else {
			print("Failed to lock base address of image buffer.")
			return
		}
		
		/*
		// Convert Raw Pixel to CIImage
		let ciImage = CIImage(cvPixelBuffer: imageBuffer)
		
		// Convert CIImage to UIImage
		let uiImage = convertCIImageToUIImage(cmage: ciImage)
		*/
		
		
		guard let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer) else {
			print("Cannot get buffer base address...!")
			return
		}
		
		let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
		let bufferWidth = CVPixelBufferGetWidth(imageBuffer)
		let bufferHeight = CVPixelBufferGetHeight(imageBuffer)
		let bufferSize = CVPixelBufferGetDataSize(imageBuffer)
		
		print("bytesPerRow: \(bytesPerRow), bufferWidth: \(bufferWidth), bufferHeight: \(bufferHeight), bufferSize: \(bufferSize)")
		
		let rawImageBuffer = baseAddress.assumingMemoryBound(to: UInt8.self) // UnsafeMutablePointer<UInt8>
		 
		// Convert Raw Pixel to NSData
		let nsData = NSData(bytes: rawImageBuffer, length: bufferSize)
		
		// 버퍼의 첫번재 두번째 값을 읽어옴
		print("[0]: \(rawImageBuffer[0]), [1]: \(rawImageBuffer[1])")
		
		// Webcam일 경우에 들어온 영상을 저장함
		if (isWebCam == false) {
			return
		}
		
		// Convert NSData to Byte Array
		let byteArray = convertNSDataToByteArray(nsData: nsData)
		
		// Image Buffer C++ <-> Swift 주고 받는 부분
		let resultArray = Array<UInt8>(CameraModule().decodeMjpegData(byteArray, Int32(bufferSize)))
		
		guard let resultUIImage = rgbaArrayToUIImage(data: resultArray, width: bufferWidth, height: bufferHeight) else {
			print("Cannot create result UIImage...!")
			return
		}
		
		/*
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("Failed to get pixel buffer from sample buffer")
			return
		}
		
		// Step 1: Create a CIImage from the pixel buffer
		let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
		
		// Step 2: Create a CIContext for rendering
		let ciContext = CIContext(options: nil)
		
		// Step 3: Get the dimensions of the pixel buffer
		let width = CVPixelBufferGetWidth(pixelBuffer)
		let height = CVPixelBufferGetHeight(pixelBuffer)
		let rect = CGRect(x: 0, y: 0, width: width, height: height)
		
		// Step 4: Render the CIImage to a CGImage
		guard let cgImage = ciContext.createCGImage(ciImage, from: rect) else {
			print("Failed to create CGImage from CIImage")
			return
		}
		
		// Step 5: Convert the CGImage to JPEG data
		let resultUIImage = UIImage(cgImage: cgImage)
		
		guard CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0)) == kCVReturnSuccess else {
			print("Failed to unlock base address of image buffer.")
			return
		}
		*/
		
		do  {
			let fileUrl =  try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			let path = "rawData_" + String(imageSaveCount) + ".jpg";
			imageSaveCount += 1
			print("#\(imageSaveCount)")
			print("#\(path)")
			let destinationUrl: URL = fileUrl.appendingPathComponent(path)
			if FileManager().fileExists(atPath: destinationUrl.path) {
				try FileManager().removeItem(at: destinationUrl)
			}
			
			print(destinationUrl.absoluteString)
			
			if let data = resultUIImage.jpegData(compressionQuality: 1) {
			//if let data = uiImage!.jpegData(compressionQuality: 1) {
				try? data.write(to: destinationUrl)
			}
		} catch (let error) {
			print(error)
		}
	}
}

private func bufferToUInt(sampleBuffer: CMSampleBuffer) -> [UInt8] {
	let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
	
	CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
	let byterPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
	let height = CVPixelBufferGetHeight(imageBuffer)
	let srcBuff = CVPixelBufferGetBaseAddress(imageBuffer)
	
	let data = NSData(bytes: srcBuff, length: byterPerRow * height)
	CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
	
	return [UInt8].init(repeating: 0, count: data.length / MemoryLayout<UInt8>.size)
}

extension CMSampleBuffer {
	var cgImage: CGImage? {
		let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(self) // CMSampleBuffer -> CVPixelBuffer
		guard let imagePixelBuffer = pixelBuffer else { return nil }
		return CIImage(cvPixelBuffer: imagePixelBuffer).cgImage // CVPixelBuffer -> CIImage
	}
}

extension CIImage {
	var cgImage: CGImage? {
		let ciContext = CIContext()
		guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
		return cgImage
	}
}
