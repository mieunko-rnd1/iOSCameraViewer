#include "CameraController.hpp"

#include <CameraInterop-Swift.h>

#include <iostream>

CameraController::CameraController()
{
	
}

bool CameraController::sendToCPlusPlus(int number)
{
	// Swift -> C++
	printf("[CameraController] number : %d\n", number);
	
	// C++ -> Swift
	sendToSwift(number);
	
	return true;
}


bool CameraController::sendToSwift(int number)
{
	auto swiftCameraModule = CameraInterop::CameraModule::init();
	swiftCameraModule.sendToSwift(number + 1);
	return true;
}
