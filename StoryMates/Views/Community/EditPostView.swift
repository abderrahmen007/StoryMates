import SwiftUI
import PhotosUI

struct EditPostView: View {
    let post: Post
    var onCancel: () -> Void
    var onSave: (String, String, String?) -> Void
    
    @State private var title: String
    @State private var content: String
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?
    @State private var hasPhotoChanged = false
    
    init(post: Post, onCancel: @escaping () -> Void, onSave: @escaping (String, String, String?) -> Void) {
        self.post = post
        self.onCancel = onCancel
        self.onSave = onSave
        _title = State(initialValue: post.title)
        _content = State(initialValue: post.content)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("background_general")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("Post Details")) {
                        TextField("Title", text: $title)
                        
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Edit your story...")
                                    .foregroundColor(Color(uiColor: .placeholderText))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            TextEditor(text: $content)
                                .frame(minHeight: 120)
                        }
                    }
                    
                    Section(header: Text("Media")) {
                        if let selectedImage = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button {
                                    self.selectedImage = nil
                                    self.selectedImageData = nil
                                    self.selectedItem = nil
                                    self.hasPhotoChanged = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                }
                                .padding(8)
                            }
                            .listRowInsets(EdgeInsets())
                        } else {
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Change Photo")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    }
                }
                .scrollContentBackground(.hidden)
                .padding(.top, 60)
                .navigationTitle("Edit Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onCancel() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let photoString: String?
                            if hasPhotoChanged {
                                if let data = selectedImageData {
                                    photoString = "data:image/jpeg;base64,\(data.base64EncodedString())"
                                } else {
                                    photoString = "" // Deleted
                                }
                            } else {
                                photoString = nil // Unchanged
                            }
                            onSave(title, content, photoString)
                        }
                        .fontWeight(.bold)
                        .disabled(title.isEmpty || content.isEmpty)
                    }
                }
                .onAppear {
                    if let photo = post.photo, !photo.isEmpty,
                       let data = Data(base64Encoded: photo.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")) {
                        self.selectedImage = UIImage(data: data)
                    }
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            if let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                                selectedImageData = compressedData
                                selectedImage = UIImage(data: compressedData)
                                hasPhotoChanged = true
                            }
                        }
                    }
                }
            }
        }
    }

