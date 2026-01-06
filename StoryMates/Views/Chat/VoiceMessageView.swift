import SwiftUI

struct VoiceMessageView: View {
    let audioUrl: String
    let duration: String
    let transcription: String?
    
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Play/Pause button
                Button(action: togglePlayback) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
                
                // Waveform or progress
                VStack(alignment: .leading, spacing: 4) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            if audioPlayer.duration > 0 {
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * CGFloat(audioPlayer.currentTime / audioPlayer.duration), height: 4)
                                    .cornerRadius(2)
                            }
                        }
                    }
                    .frame(height: 4)
                    
                    // Duration
                    Text(formatDuration())
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            
            // Transcription
            if let transcription = transcription, !transcription.isEmpty, transcription != "Transcription disabled" {
                Text(transcription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
                    .padding(.horizontal, 12)
            }
        }
    }
    
    private func togglePlayback() {
        if audioPlayer.isPlaying {
            audioPlayer.pause()
        } else {
            if audioPlayer.currentTime == 0 {
                // Start new playback
                playAudio()
            } else {
                // Resume
                audioPlayer.resume()
            }
        }
    }
    
    private func playAudio() {
        guard let url = URL(string: audioUrl) else {
            print("❌ Invalid audio URL: \(audioUrl)")
            return
        }
        
        isLoading = true
        print("🎵 Starting audio playback for URL: \(audioUrl)")
        
        // Download audio file if it's a remote URL
        if url.scheme == "http" || url.scheme == "https" {
            print("📥 Downloading audio from remote URL...")
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("❌ Download error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }
                
                print("✅ Downloaded \(data.count) bytes")
                
                // Save to temporary file with unique name
                let filename = url.lastPathComponent
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                
                do {
                    try data.write(to: tempURL)
                    print("✅ Saved to temp file: \(tempURL.path)")
                    
                    DispatchQueue.main.async {
                        do {
                            try self.audioPlayer.play(url: tempURL)
                            self.isLoading = false
                            print("✅ Audio playback started")
                        } catch {
                            print("❌ Error playing audio: \(error)")
                            self.isLoading = false
                        }
                    }
                } catch {
                    print("❌ Error writing temp file: \(error)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            }.resume()
        } else {
            // Local file
            print("📂 Playing local file: \(url.path)")
            do {
                try audioPlayer.play(url: url)
                isLoading = false
                print("✅ Local audio playback started")
            } catch {
                print("❌ Error playing local audio: \(error)")
                isLoading = false
            }
        }
    }
    
    private func formatDuration() -> String {
        if audioPlayer.duration > 0 {
            let current = Int(audioPlayer.currentTime)
            let total = Int(audioPlayer.duration)
            return String(format: "%d:%02d / %d:%02d", current / 60, current % 60, total / 60, total % 60)
        } else if let durationValue = Double(duration) {
            let seconds = Int(durationValue)
            return String(format: "%d:%02d", seconds / 60, seconds % 60)
        }
        return "0:00"
    }
}
