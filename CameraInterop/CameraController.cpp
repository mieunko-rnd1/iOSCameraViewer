#include "CameraController.hpp"

#include <CameraInterop-Swift.h>

#include <opencv2/opencv.hpp>

#include <iostream>
#include <cstdio>

CameraController::CameraController()
{
	
}

std::vector<unsigned char> CameraController::decodeMjpegData(const unsigned char* data, int size)
{
	if (data == nullptr)
	{
		return {};
	}
	
	std::vector<unsigned char> imageData = std::vector<unsigned char>(data, data + size);
	
	return imageData;
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

