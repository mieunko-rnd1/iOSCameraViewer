import SwiftUI
import AVFoundation

struct ContentView: View {
	@State private var viewModel = CameraViewModel()
	
	@State private var connectDevice: Bool = false
	@State private var startCapture: Bool = false
	@State private var stopCapture: Bool = false
	
	var body: some View {
		ZStack {
			VStack {
				CameraView(image: $viewModel.currentFrame)
					.ignoresSafeArea()
				Spacer()
				
				HStack {
					Button(action: {
						viewModel.connectDevice()
					}, label: {
						Text("Connect Device")
					})
					Spacer()
					
					Button(action: {
						viewModel.disconnctDevice()
					}, label: {
						Text("Disconnect Device")
					})
					Spacer()
					
					Button(action: {
						viewModel.startCapture()
					}, label: {
						Text("Start Capture")
					})
					Spacer()
					
					Button(action: {
						viewModel.stopCapture()
					}, label: {
						Text("Stop Capture")
					})
				}
			}
		}
		
	}
}

// Interoperability 예제
/*
import SwiftUI
import CameraInterop

struct ContentView: View {
	var body: some View {
	VStack {
	// Swift <-> C++ Mixing Languages Test Code
		var retb = CameraModule().sendToCPlusPlus(10)
		Text("Hello, world!")
	}
	.padding()
	}
}
*/

#Preview {
	ContentView()
}
