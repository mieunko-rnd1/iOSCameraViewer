// C++ <-> Swift 프로젝트 설정 방법
* Project -> Build Settings -> C++ and Objective-C Interoperability -> C++/Objective-C++ 로 변경
* File -> New -> Target -> Framework를 생성하여 C++과 Interoperation 가능한 Header 파일 생성
* New File frome Template -> C++ 파일 생성 (생성시에 docc 파일 옵션도 선택)
* Project -> 생성한 Framework 선택 -> Build Phase -> Headers -> Project에 있던걸 Public으로 변경 (Move to Public Group)

// Camera 접근 권한 설정
* https://adjh54.tistory.com/126
* Target -> Build Settings -> Privacy - Camera Usage Description -> 카메라 접근을 허용해주세요

// 실행 에러 수정
* https://forums.developer.apple.com/forums/thread/710843
* Product -> Scheme -> Edit Scheme -> Diagnostics -> API Validation 체크 해제

// Camera 예제 코드
* https://gist.github.com/SatoTakeshiX/440a0b8b3c859d44fcf91dae3e0f8a32
* https://github.com/create-with-swift/Camera-capture-setup-in-SwiftUI

// OpenCV
* https://object-world.tistory.com/28
* https://medium.com/@hdpoorna/integrating-opencv-to-your-swift-ios-project-in-xcode-and-working-with-uiimages-4c614e62ac88
* OpenCV는 파일 크기가 커서 git에 push가 안되서 opencv-4.10.0-ios-framework.zip 파일 받아서 project에 직접 추가해줘야함
* 파일 압축 해제 후 opencv2.framework 파일을 project 폴더 아래에 복사해두면 됨
