import SwiftUI
import UIKit

struct BillScannerView: View {
    @ObservedObject var premiumStore: PremiumFeatureStore
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var ocrResult: OCRResult?
    @State private var error: String?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if let result = ocrResult {
                    OCRResultView(result: result, onSave: {
                        dismiss()
                    })
                } else {
                    VStack(spacing: 24) {
                        ScrollView {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 64))
                                    .foregroundColor(.blue)
                                
                                VStack(spacing: 8) {
                                    Text("Scan a Bill")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Text("Take a photo of your bill to automatically extract vendor, amount, and date")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(24)
                        }
                        
                        VStack(spacing: 12) {
                            Button(action: { showingImagePicker = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                    Text("Take Photo")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            
                            Button(action: { showingImagePicker = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "photo")
                                    Text("Choose from Library")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color(.systemGray5))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding(16)
                    }
                }
                
                if isProcessing {
                    VStack {
                        ProgressView("Processing bill...")
                            .padding(24)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                }
            }
            .navigationTitle("Scan Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePickerView(image: $selectedImage)
            }
            .onChange(of: selectedImage) { image in
                if let image = image {
                    processImage(image)
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error ?? "An error occurred")
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        error = nil
        
        Task {
            do {
                let result = try await BillOCRService.shared.extractBillData(from: image)
                await MainActor.run {
                    self.ocrResult = result
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isProcessing = false
                }
            }
        }
    }
}

struct OCRResultView: View {
    let result: OCRResult
    let onSave: () -> Void
    @State private var vendor: String
    @State private var amount: String
    @State private var date: Date
    @State private var description: String
    @Environment(\.dismiss) var dismiss
    
    init(result: OCRResult, onSave: @escaping () -> Void) {
        self.result = result
        self.onSave = onSave
        _vendor = State(initialValue: result.vendor)
        _amount = State(initialValue: result.amount.description)
        _date = State(initialValue: result.date)
        _description = State(initialValue: result.description ?? "")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vendor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Vendor name", text: $vendor)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DatePicker("Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Description", text: $description, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence: \(String(format: "%.0f%%", result.confidence * 100))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ProgressView(value: result.confidence)
                    }
                }
                .padding(16)
            }
            
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                
                Button(action: saveExpense) {
                    Text("Save Expense")
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Review Bill Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func saveExpense() {
        onSave()
        dismiss()
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
    }
}

struct BillScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BillScannerView(premiumStore: PremiumFeatureStore())
    }
}
