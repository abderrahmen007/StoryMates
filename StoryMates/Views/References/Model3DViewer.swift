import SwiftUI
import WebKit

struct Model3DViewer: View {
    let modelData: String?
    
    @State private var isLoading = false
    @State private var loadError: String?
    
    private var modelURL: URL? {
        guard let data = modelData, !data.isEmpty else { return nil }
        
        // Handle localhost replacement logic
        var finalUrlString = data
        if data.contains("localhost") {
            let base = APIClient.baseURL.replacingOccurrences(of: "http://", with: "").replacingOccurrences(of: "https://", with: "")
            finalUrlString = data.replacingOccurrences(of: "localhost:3001", with: base)
                                .replacingOccurrences(of: "localhost", with: base)
        }
        
        // Ensure the URL is properly escaped
        if let encodedString = finalUrlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            return URL(string: encodedString)
        }
        
        return URL(string: finalUrlString)
    }
    
    var body: some View {
        ZStack {
            Color.black
            
            if modelData == "placeholder-3d-model-data" {
                VStack(spacing: 8) {
                    Text("🎮")
                        .font(.system(size: 48))
                    Text("3D Model Unavailable")
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.red)
                    Text("Model generation failed or in progress")
                        .font(.custom("Courier", size: 10))
                        .foregroundColor(.gray)
                }
            } else if let url = modelURL {
                ZStack(alignment: .bottomTrailing) {
                    // Web View with model-viewer
                    Model3DWebView(modelURL: url)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Download/Share button overlay
                    HStack(spacing: 12) {
                        Button(action: {
                            downloadModel(url: url)
                        }) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.pixelGold)
                                .padding(10)
                                .background(Color.pixelDarkBlue.opacity(0.8))
                                .border(Color.pixelGold, width: 1)
                        }
                    }
                    .padding(16)
                }
            } else {
                VStack(spacing: 8) {
                    Text("⚠️")
                        .font(.system(size: 32))
                    Text("No Model Data")
                        .font(.custom("Courier", size: 12))
                        .foregroundColor(.red)
                    Text("Model URL is empty or null")
                        .font(.custom("Courier", size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .border(Color.pixelCyan, width: 3)
    }
    
    private func downloadModel(url: URL) {
        print("📥 Starting download of GLB file from: \(url)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Download failed: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ No data received")
                return
            }
            
            // Save to temporary directory
            let tempDir = FileManager.default.temporaryDirectory
            let filename = url.lastPathComponent.isEmpty || !url.lastPathComponent.contains(".glb") ? "model.glb" : url.lastPathComponent
            let tempURL = tempDir.appendingPathComponent(filename)
            
            do {
                try data.write(to: tempURL)
                print("✅ Saved GLB to: \(tempURL.path)")
                
                // Share the file
                DispatchQueue.main.async {
                    self.shareFile(url: tempURL)
                }
            } catch {
                print("❌ Failed to save file: \(error)")
            }
        }.resume()
    }
    
    private func shareFile(url: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                       y: rootViewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityVC, animated: true)
    }
}

// WebView wrapper for model-viewer (Premium Implementation)
struct Model3DWebView: UIViewRepresentable {
    let modelURL: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlContent = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1.0, user-scalable=no">
            <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js"></script>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { background-color: #1a1a2e; overflow: hidden; width: 100vw; height: 100vh; }
                model-viewer { 
                    width: 100%; 
                    height: 100%; 
                    --poster-color: transparent; 
                    --progress-bar-color: #ffd369;
                    background-color: #1a1a2e;
                }
            </style>
        </head>
        <body>
            <model-viewer
                src="\(modelURL.absoluteString)"
                alt="3D Model"
                auto-rotate
                camera-controls
                shadow-intensity="1"
                environment-image="neutral"
                exposure="1"
                interaction-prompt="auto"
                loading="eager"
            >
                <div slot="progress-bar" style="color: #ffd369; font-family: monospace; text-align: center; width: 100%; position: absolute; top: 50%;">
                    LOADING MESH...
                </div>
            </model-viewer>
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

// Helper for image from base64 (Maintained for backward compatibility in other views)
struct ImageFromBase64: View {
    let base64: String
    
    var body: some View {
        let cleanBase64 = base64.components(separatedBy: ",").last ?? base64
        
        if let data = Data(base64Encoded: cleanBase64, options: .ignoreUnknownCharacters),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
        } else {
            Color.gray
                .overlay(Text("Invalid Image").font(.caption).foregroundColor(.white))
        }
    }
}
