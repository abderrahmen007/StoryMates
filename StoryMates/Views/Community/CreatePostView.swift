import SwiftUI
import PhotosUI

struct CreatePostView: View {
    var onCancel: () -> Void
    var onSave: (String, String, String?) -> Void
    
    @State private var title = ""
    @State private var content = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?
    
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
                                Text("Share your story...")
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
                                    Text("Add Photo")
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                    }
                }
                .scrollContentBackground(.hidden)
                .padding(.top, 60)
                .navigationTitle("New Post")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { onCancel() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Post") {
                            let base64Image = selectedImageData?.base64EncodedString()
                            let photoString = base64Image != nil ? "data:image/jpeg;base64,\(base64Image!)" : nil
                            onSave(title, content, photoString)
                        }
                        .fontWeight(.bold)
                        .disabled(title.isEmpty || content.isEmpty)
                    }
                }
                .onChange(of: selectedItem) { oldValue, newValue in
                    Task {
                        if let data = try? await newValue?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            if let compressedData = uiImage.jpegData(compressionQuality: 0.5) {
                                selectedImageData = compressedData
                                selectedImage = UIImage(data: compressedData)
                            }
                        }
                    }
                }
            }
        }
    }

