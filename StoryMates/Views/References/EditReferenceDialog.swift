import SwiftUI

struct EditReferenceDialog: View {
    let projectId: String
    let reference: Reference
    @ObservedObject var viewModel: StoryProjectViewModel
    var onDismiss: () -> Void
    
    @State private var name: String
    @State private var lore: String
    @State private var design: String
    @State private var selectedType: ReferenceType
    
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var previewImage: String?
    @State private var previewModel: String?
    
    init(projectId: String, reference: Reference, viewModel: StoryProjectViewModel, onDismiss: @escaping () -> Void) {
        self.projectId = projectId
        self.reference = reference
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        _name = State(initialValue: reference.name)
        _lore = State(initialValue: reference.lore)
        _design = State(initialValue: reference.design)
        _selectedType = State(initialValue: reference.type)
        _previewImage = State(initialValue: reference.imageData)
        _previewModel = State(initialValue: reference.modelData)
    }
    
    private let pixelAccent = Color.pixelGold
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.pixelDarkBlue.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Asset Previews
                        if previewImage != nil || previewModel != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                PixelLabel(text: "GENERATED ASSETS")
                                
                                let is3D = viewModel.projectArtStyle?.dimension == .THREE_D
                                let hasModel = previewModel != nil && previewModel != "" && previewModel != "placeholder-3d-model-data"
                                
                                if is3D && hasModel {
                                    Model3DViewer(modelData: previewModel)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.3))
                                        .border(Color.cyan, width: 2)
                                } else if let img = previewImage {
                                    ImageFromBase64(base64: img)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.3))
                                        .border(pixelAccent, width: 2)
                                }
                            }
                            .padding(.bottom, 10)
                        }
                        
                        // Input Fields
                        VStack(alignment: .leading, spacing: 8) {
                            PixelLabel(text: "NAME")
                            TextField("Enter name...", text: $name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .border(Color.white.opacity(0.3), width: 2)
                                .foregroundColor(.white)
                            
                            PixelLabel(text: "LORE / BACKSTORY")
                            TextEditor(text: $lore)
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .border(Color.white.opacity(0.3), width: 2)
                                .foregroundColor(.white)
                            
                            PixelLabel(text: "DESIGN / APPEARANCE")
                            TextEditor(text: $design)
                                .frame(height: 80)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .border(Color.white.opacity(0.3), width: 2)
                                .foregroundColor(.white)
                        }
                        
                        // Generation Controls
                        VStack(spacing: 12) {
                            if isGenerating {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: pixelAccent))
                                    Text("GENERATING ASSETS...")
                                        .font(.custom("Courier", size: 14).weight(.bold))
                                        .foregroundColor(pixelAccent)
                                    Text("This may take a minute. Please don't close the app.")
                                        .font(.custom("Courier", size: 10))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black.opacity(0.3))
                                .border(pixelAccent, width: 2)
                            } else {
                                Button(action: generateAssets) {
                                    HStack {
                                        Text(previewImage == nil ? "✨ GENERATE ASSETS" : "🔄 RE-GENERATE ASSETS")
                                        if isGenerating { ProgressView().padding(.leading) }
                                    }
                                    .font(.custom("Courier", size: 14).weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue.opacity(0.3))
                                    .foregroundColor(.white)
                                    .border(Color.blue, width: 2)
                                }
                                
                                if let error = generationError {
                                    Text("⚠️ \(error)")
                                        .font(.custom("Courier", size: 12))
                                        .foregroundColor(.red)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        
                        Button(action: saveChanges) {
                            Text("✓ SAVE CHANGES")
                                .font(.custom("Courier", size: 16).weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(name.isEmpty || isGenerating ? Color.gray : pixelAccent)
                                .foregroundColor(.black)
                                .border(Color.black, width: 2)
                        }
                        .disabled(name.isEmpty || isGenerating)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Reference")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(pixelAccent)
                }
            }
        }
    }
    
    private func PixelLabel(text: String) -> some View {
        Text(text)
            .font(.custom("Courier", size: 12).weight(.bold))
            .foregroundColor(pixelAccent)
            .padding(.top, 4)
    }
    
    private func generateAssets() {
        isGenerating = true
        generationError = nil
        
        viewModel.generateReferenceAssets(
            projectId: projectId,
            referenceId: reference.id,
            completion: { image, model in
                self.previewImage = image
                self.previewModel = model
                self.isGenerating = false
            },
            onError: { errorMsg in
                self.generationError = errorMsg
                self.isGenerating = false
            }
        )
    }
    
    private func saveChanges() {
        let updated = Reference(
            id: reference.id,
            type: selectedType,
            name: name,
            lore: lore,
            design: design,
            imageData: previewImage,
            modelData: previewModel,
            createdAt: reference.createdAt,
            updatedAt: Int64(Date().timeIntervalSince1970 * 1000)
        )
        viewModel.updateReference(projectId: projectId, reference: updated)
        onDismiss()
    }
}
