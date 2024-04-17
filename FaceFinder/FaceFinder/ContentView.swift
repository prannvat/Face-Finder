//
//  ContentView.swift
//  FaceFinder
//
//  Created by Prannvat Singh on 17/04/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Vision

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}


import SwiftUI
import Vision

struct ContentView: View {
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? = UIImage(named: "people") // Replace "defaultImage" with your default image name
    @State private var image: Image? = Image("people") // Same here
    @State private var faceBoundingBoxes: [CGRect] = []

    var body: some View {
        VStack {
            ZStack {
                image?
                    .resizable()
                    .scaledToFit()
                    .overlay(detectionOverlay)
                
                if faceBoundingBoxes.isEmpty {
                    Text("No faces detected")
                        .foregroundColor(.red)
                        .background(Color.white)
                        .padding()
                }
            }

            Button("Select Image") {
                showingImagePicker = true
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $inputImage)
        }
        .onChange(of: inputImage) { _ in
            loadImage()
        }
    }

    var detectionOverlay: some View {
        GeometryReader { geometry in
            ForEach(Array(faceBoundingBoxes.enumerated()), id: \.offset) { _, box in
                Rectangle()
                    .fill(Color.clear)
                    .border(Color.red, width: 3)
                    .frame(width: box.width * geometry.size.width,
                           height: box.height * geometry.size.height)
                    .offset(x: box.minX * geometry.size.width,
                            y: (1 - box.maxY) * geometry.size.height) // Flip the y-axis
            }
        }
    }

    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        detectFaces(in: inputImage)
    }

    func detectFaces(in uiImage: UIImage) {
        guard let cgImage = uiImage.cgImage else { return }
        guard let cgImage = uiImage.fixedOrientation().cgImage else { return }
        let request = VNDetectFaceRectanglesRequest { request, error in
            guard error == nil else {
                print("Face detection error: \(error!.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                self.faceBoundingBoxes = request.results?.compactMap { result in
                    guard let faceObservation = result as? VNFaceObservation else { return nil }
                    return VNImageRectForNormalizedRect(faceObservation.boundingBox, cgImage.width, cgImage.height)
                } ?? []
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }
    
}
extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}
#Preview(windowStyle: .automatic) {
    ContentView()
}
