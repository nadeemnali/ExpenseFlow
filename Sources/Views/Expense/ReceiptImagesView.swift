import SwiftUI
import PhotosUI

/// Displays and manages receipt images for an expense
struct ReceiptImagesView: View {
    @ObservedObject var imageStorageManager: ImageStorageManager
    let expenseId: UUID
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isShowingImagePicker = false
    @State private var selectedImageIndex = 0
    @State private var showDeleteConfirmation = false
    @State private var imageToDelete: String?
    
    var images: [UIImage] {
        imageStorageManager.retrieveImages(for: expenseId)
    }
    
    var body: some View {
        BackgroundView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Receipt Images")
                        .font(AppTheme.title(18))
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.ink.opacity(0.5))
                    }
                }
                .padding(20)
                .background(AppTheme.background)
                
                Divider()
                
                if images.isEmpty {
                    emptyState
                } else {
                    imageGallery
                }
                
                Spacer()
                
                // Add Image Button
                Button(action: { isShowingImagePicker = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Add Receipt Image")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppTheme.teal)
                    .foregroundStyle(AppTheme.ink)
                    .cornerRadius(8)
                    .fontWeight(.semibold)
                }
                .padding(20)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .photosPicker(
            isPresented: $isShowingImagePicker,
            selection: $selectedItem,
            matching: .images
        )
        .onChange(of: selectedItem) { item in
            Task {
                if let data = try await item?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    imageStorageManager.storeImage(uiImage, for: expenseId)
                }
                selectedItem = nil
            }
        }
        .alert("Delete Image?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let imageFile = imageToDelete {
                    imageStorageManager.deleteImage(imageFile, for: expenseId)
                    imageToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) {
                imageToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "photo.stack")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.ink.opacity(0.3))
            
            VStack(spacing: 4) {
                Text("No Receipt Images")
                    .font(AppTheme.title(16))
                    .fontWeight(.semibold)
                
                Text("Add photos of receipts to keep with your expense")
                    .font(AppTheme.body(13))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    private var imageGallery: some View {
        VStack(spacing: 16) {
            // Main image viewer
            if !images.isEmpty && selectedImageIndex < images.count {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: images[selectedImageIndex])
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .cornerRadius(8)
                        .padding(16)
                    
                    // Delete button
                    Button(action: {
                        imageToDelete = imageStorageManager.getImageFileName(for: expenseId, at: selectedImageIndex)
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.red)
                            .padding(16)
                    }
                }
            }
            
            // Image counter
            if !images.isEmpty {
                Text("Image \(selectedImageIndex + 1) of \(images.count)")
                    .font(AppTheme.body(12))
                    .foregroundStyle(AppTheme.ink.opacity(0.6))
            }
            
            // Thumbnail scroll view
            if images.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            selectedImageIndex == index ? AppTheme.teal : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .onTapGesture {
                                    withAnimation {
                                        selectedImageIndex = index
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var imageStorage = ImageStorageManager()
    
    ReceiptImagesView(
        imageStorageManager: imageStorage,
        expenseId: UUID()
    )
}
