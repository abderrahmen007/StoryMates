import SwiftUI

struct ReferenceCard: View {
    let reference: Reference
    let projectArtStyle: ProjectArtStyle?
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var isExpanded = false
    private let pixelAccent = Color.pixelGold
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Thumbnail Row
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reference.name)
                        .font(.custom("Courier", size: 16).weight(.bold))
                        .foregroundColor(.white)
                    
                    Text(reference.type.rawValue)
                        .font(.custom("Courier", size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Quick Preview Thumbnail
                let is3D = projectArtStyle?.dimension == .THREE_D
                
                if !is3D, let imageData = reference.imageData {
                    ImageFromBase64(base64: imageData)
                        .frame(width: 40, height: 40)
                        .border(Color.white.opacity(0.3), width: 1)
                } else if is3D {
                    Text("🎮")
                        .font(.title3)
                }
                
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(pixelAccent)
                }
            }
            .padding()
            .background(Color.black.opacity(0.2))
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider().background(pixelAccent)
                    
                    if let artStyle = projectArtStyle, artStyle.dimension == .THREE_D {
                        Text("🎮 3D Model View:")
                            .font(.caption).bold().foregroundColor(.cyan)
                        Model3DViewer(modelData: reference.modelData)
                            .frame(height: 250)
                    } else if let imageData = reference.imageData {
                        Text("🖼️ Reference Image:")
                            .font(.caption).bold().foregroundColor(.cyan)
                        ImageFromBase64(base64: imageData)
                            .frame(height: 200)
                            .background(Color.black)
                            .border(pixelAccent, width: 1)
                    }
                    
                    Group {
                        Text("📖 Lore:")
                            .font(.caption).bold().foregroundColor(pixelAccent)
                        Text(reference.lore)
                            .font(.custom("Courier", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("🎨 Design:")
                            .font(.caption).bold().foregroundColor(pixelAccent)
                        Text(reference.design)
                            .font(.custom("Courier", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil.circle")
                                .font(.custom("Courier", size: 12))
                                .padding(8)
                                .background(Color.blue.opacity(0.3))
                                .foregroundColor(.white)
                                .border(Color.blue, width: 1)
                        }
                        
                        Button(action: onDelete) {
                            Label("Delete", systemImage: "trash.circle")
                                .font(.custom("Courier", size: 12))
                                .padding(8)
                                .background(Color.red.opacity(0.3))
                                .foregroundColor(.white)
                                .border(Color.red, width: 1)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.black.opacity(0.1))
            }
        }
        .background(Color(red: 0.2, green: 0.2, blue: 0.3))
        .border(isExpanded ? pixelAccent : Color.white.opacity(0.2), width: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
