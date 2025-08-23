//
//  FireCameraView.swift
//  UI
//
//  Created by bear on 8/23/25.
//

import SwiftUI

struct FireCameraView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var showCheckmark = false
    @State private var capturedImage: UIImage?
    
    var body: some View {
        ZStack {
            // 실제 카메라 프리뷰 (백그라운드)
            if cameraViewModel.isAuthorized && cameraViewModel.isRunning {
                CameraPreview(session: cameraViewModel.captureSession)
                    .ignoresSafeArea()
                    .opacity(cameraViewModel.cameraFrozen ? 0.8 : 1.0) // 촬영 후 살짝 어둡게
            } else {
                // 카메라 권한이 없거나 실행 중이 아닐 때 검은 배경
                Color.black
                    .ignoresSafeArea()
            }
            
            // 어두운 오버레이 (카메라 뷰를 살짝 어둡게)
            Color.black.opacity(cameraViewModel.cameraFrozen ? 0.5 : 0.3)
                .ignoresSafeArea()
            
            // 커스텀 UI 오버레이
            CameraOverlayView(
                showCheckmark: showCheckmark,
                isDirectionCorrect: cameraViewModel.isDirectionCorrect,
                onCapturePhoto: {
                    capturePhoto()
                }
            )
            
            // 에러 메시지 표시
            if let errorMessage = cameraViewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                    Spacer()
                }
            }
            
            // 제보 완료 메시지 (선택적)
            if capturedImage != nil {
                ReportCompletionView()
            }
        }
        .onAppear {
            cameraViewModel.requestAccessAndConfigure()
        }
        .onDisappear {
            Task {
                await cameraViewModel.stop()
            }
        }
        .onChange(of: cameraViewModel.lastPhotoData) { _, newData in
            if let data = newData,
               let image = UIImage(data: data) {
                capturedImage = image
                showCheckmark = true
                
                // 2초 후 홈으로 돌아가기 (홈뷰 기능은 나중에 구현)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // TODO: 홈뷰로 돌아가는 로직
                    // NavigationController.popToRoot() 또는 dismiss() 등
                }
            }
        }
    }
    
    private func capturePhoto() {
        cameraViewModel.capturePhoto()
        
        // 촬영 애니메이션
        withAnimation(.easeInOut(duration: 0.3)) {
            showCheckmark = true
        }
    }
}

// MARK: - Camera Overlay View
struct CameraOverlayView: View {
    let showCheckmark: Bool
    let isDirectionCorrect: Bool
    let onCapturePhoto: () -> Void
    
    var body: some View {
        ZStack {
            // Camera frame corners
            CameraFrameCorners()
            
            // Center content
            VStack(spacing: 0) {
                Spacer()
                
                // Center icon (arrow pointing to target direction)
                CenterIconView(
                    showCheckmark: showCheckmark,
                    isDirectionCorrect: isDirectionCorrect
                )
                
                Spacer().frame(height: 40)
                
                // Instructional text
                InstructionalTextView(showCheckmark: showCheckmark, isDirectionCorrect: isDirectionCorrect)
                
                Spacer()
                
                // Bottom content
                VStack(spacing: 24) {
                    // Safety notice (촬영 완료 시 숨김)
                    if !showCheckmark {
                        Text("안전이 확보된 곳에서만 촬영하세요")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Fire report button (올바른 방향일 때만 활성화, 촬영 완료 시 숨김)
                    if !showCheckmark {
                        FireReportButton(
                            isEnabled: isDirectionCorrect,
                            onReport: onCapturePhoto
                        )
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Report Completion View
struct ReportCompletionView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 완료 체크마크
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("화재 상황이 제보되었습니다")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("관련 기관에 신속히 전달됩니다")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: true)
        }
    }
}

// MARK: - Camera Frame Corners
struct CameraFrameCorners: View {
    var body: some View {
        VStack {
            // Top corners
            HStack {
                TopLeftCorner()
                Spacer()
                TopRightCorner()
            }
            .padding(.top, 100)
            
            Spacer()
            
            // Bottom corners
            HStack {
                BottomLeftCorner()
                Spacer()
                BottomRightCorner()
            }
            .padding(.bottom, 200)
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Corner Shapes
struct TopLeftCorner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 4)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 40)
        }
    }
}

struct TopRightCorner: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 4)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 40)
        }
    }
}

struct BottomLeftCorner: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 40)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 4)
        }
    }
}

struct BottomRightCorner: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 40)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 40, height: 4)
        }
    }
}

// MARK: - Center Icon View
struct CenterIconView: View {
    let showCheckmark: Bool
    let isDirectionCorrect: Bool
    
    var body: some View {
        if showCheckmark {
            // Green checkmark circle
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(Color.green, lineWidth: 4)
                    .frame(width: 90, height: 90)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(showCheckmark ? 1.0 : 0.8)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showCheckmark)
        } else {
            // Direction arrow or checkmark circle
            if isDirectionCorrect {
                // Green checkmark circle when direction is correct
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .stroke(Color.green, lineWidth: 4)
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDirectionCorrect)
            } else {
                // White arrow when direction needs adjustment
                Image(systemName: "arrow.right")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Instructional Text View
struct InstructionalTextView: View {
    let showCheckmark: Bool
    let isDirectionCorrect: Bool
    
    var body: some View {
        if !showCheckmark {
            VStack(spacing: 4) {
                Text("화면에 표시된 화살표를 따라")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("화재 방향을 맞춰주세요.")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Fire Report Button
struct FireReportButton: View {
    let isEnabled: Bool
    let onReport: () -> Void
    
    var body: some View {
        Button(action: onReport) {
            Text("화재상황 제보")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(isEnabled ? Color.red : Color.gray.opacity(0.6))
                )
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 40)
        .scaleEffect(isEnabled ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

#Preview {
    FireCameraView()
}
