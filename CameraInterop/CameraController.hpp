#ifndef CameraController_hpp
#define CameraController_hpp

#if defined __cplusplus // Build error 발생, https://stackoverflow.com/questions/17129698/expected-after-top-level-declarator-error-in-xcode

#include <swift/bridging>

class CameraController {
	
public:
	CameraController();
	
	// Swift -> C++
	bool sendToCPlusPlus(int number);
	
	// C++ -> Swift
	bool sendToSwift(int number);
};

#endif // __cplusplus

#endif // CameraController_hpp
