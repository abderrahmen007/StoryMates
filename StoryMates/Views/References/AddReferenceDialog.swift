import SwiftUI

struct AddReferenceDialog: View {
    let projectId: String
    @ObservedObject var viewModel: StoryProjectViewModel
    var onDismiss: () -> Void
    
    @State private var name = ""
    @State private var lore = ""
    @State private var design = ""
    @State private var selectedType: ReferenceType?
    
    // AI Generation state
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var imageData: String?
    @State private var modelData: String?
    
    private let pixelAccent = Color.pixelGold
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.pixelDarkBlue.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Type Selection
                        HStack(spacing: 20) {
                            ForEach(ReferenceType.allCases, id: \.self) { type in
                                TypeButton(
                                    type: type,
                                    isActive: selectedType == type,
                                    action: { selectedType = type }
                                )
                            }
                        }
                        .padding(.top)
                        
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
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .border(Color.white.opacity(0.3), width: 2)
                                .foregroundColor(.white)
                            
                            PixelLabel(text: "DESIGN / APPEARANCE")
                            TextEditor(text: $design)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .padding(4)
                                .background(Color.white.opacity(0.1))
                                .border(Color.white.opacity(0.3), width: 2)
                                .foregroundColor(.white)
                        }
                        
                        // Generation Section
                        if isGenerating {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: pixelAccent))
                                Text("🪄 AI is crafting your assets...")
                                    .font(.custom("Courier", size: 14))
                                    .foregroundColor(pixelAccent)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.3))
                        } else if imageData != nil || modelData != nil {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("✨ GENERATED ASSETS")
                                    .font(.custom("Courier", size: 12).weight(.bold))
                                    .foregroundColor(pixelAccent)
                                
                                let is3D = viewModel.projectArtStyle?.dimension == .THREE_D
                                let hasModel = modelData != nil && modelData != "" && modelData != "placeholder-3d-model-data"
                                
                                if is3D && hasModel {
                                    Model3DViewer(modelData: modelData)
                                        .frame(height: 200)
                                        .background(Color.black.opacity(0.3))
                                        .border(Color.cyan, width: 2)
                                } else if let img = imageData {
                                    ImageFromBase64(base64: img)
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black.opacity(0.3))
                                        .border(pixelAccent, width: 2)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                        }
                        
                        if let error = generationError {
                            Text(error)
                                .font(.custom("Courier", size: 12))
                                .foregroundColor(.red)
                                .padding()
                        }
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: generateAssets) {
                                Text("🪄 GENERATE WITH AI")
                                    .font(.custom("Courier", size: 16).weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isGenerating || name.isEmpty ? Color.gray : Color.purple)
                                    .foregroundColor(.white)
                                    .border(Color.white.opacity(0.5), width: 2)
                            }
                            .disabled(isGenerating || name.isEmpty)
                            
                            Button(action: saveReference) {
                                Text("✓ SAVE REFERENCE")
                                    .font(.custom("Courier", size: 16).weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(name.isEmpty || selectedType == nil ? Color.gray : pixelAccent)
                                    .foregroundColor(.black)
                                    .border(Color.black, width: 2)
                            }
                            .disabled(name.isEmpty || selectedType == nil)
                        }
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Reference")
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
        guard let type = selectedType else { return }
        isGenerating = true
        generationError = nil
        
        // 1. Create a temp reference to save to backend to get an ID
        let tempRef = Reference(
            type: type,
            name: name,
            lore: lore,
            design: design
        )
        
        // 2. Add it temporarily
        viewModel.addReference(projectId: projectId, reference: tempRef) {
             if let addedRef = viewModel.references.last(where: { $0.name == name }) {
                 viewModel.generateReferenceAssets(projectId: projectId, referenceId: addedRef.id) { img, model in
                     self.imageData = img
                     self.modelData = model
                     self.isGenerating = false
                 } onError: { err in
                     self.generationError = err
                     self.isGenerating = false
                 }
             }
        }
    }
    
    private func saveReference() {
        onDismiss()
    }
}

struct TypeButton: View {
    let type: ReferenceType
    let isActive: Bool
    let action: () -> Void
    
    private let color = Color.pixelGold
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(type.icon)
                    .font(.system(size: 32))
                Text(type.rawValue)
                    .font(.custom("Courier", size: 10).weight(.bold))
                    .foregroundColor(isActive ? .black : .white)
            }
            .frame(width: 100)
            .padding(.vertical, 12)
            .background(color.opacity(isActive ? 1.0 : 0.3))
            .border(Color.white.opacity(0.3), width: 2)
        }
    }
}
