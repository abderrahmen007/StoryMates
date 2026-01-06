import SwiftUI

// MARK: - Story Step Model

struct StoryStep {
    let nodeId: String
    let nodeType: NodeType
    let text: String
    let imageData: String
    let choice: String?
    let timestamp: Date
}

// MARK: - Community Projects Screen

struct CommunityProjectsScreen: View {
    @StateObject private var viewModel = CommunityProjectViewModel()
    @StateObject private var storyViewModel = StoryProjectViewModel()
    @State private var selectedFilter = "All"
    @State private var showPreview = false
    @State private var selectedProjectState: FlowchartState?
    @State private var isLoadingProject = false
    
    let filters = ["All", "Popular", "Recent", "Starred"]
    
    var body: some View {
        ZStack {
            Color.themeBeige.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Projects grid
                if viewModel.isLoading || isLoadingProject {
                    loadingView
                } else if viewModel.communityProjects.isEmpty {
                    emptyView
                } else {
                    projectsGrid
                }
            }
            
            if showPreview, let state = selectedProjectState {
                PreviewOverlayWithHistory(
                    state: state,
                    onClose: {
                        showPreview = false
                        selectedProjectState = nil
                    }
                )
            }
        }
        .onAppear {
            if let userId = AuthManager.shared.userId {
                viewModel.setCurrentUserId(userId: userId)
            }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        title: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        selectedFilter = filter
                        viewModel.filterProjects(filter: filter)
                    }
                }
            }
            .padding(12)
        }
        .background(Color.white)
        .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
    }
    
    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .pixelGold))
            if isLoadingProject {
                Text("Loading preview...")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Text("🌟")
                .font(.system(size: 64))
            Text("No community projects yet")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var projectsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                ForEach(viewModel.communityProjects) { project in
                    CommunityProjectCard(
                        project: project,
                        isAuthor: project.authorId == viewModel.currentUserId,
                        onClick: {
                            isLoadingProject = true
                            storyViewModel.loadFlowchart(projectId: project.id) { flowchartState in
                                isLoadingProject = false
                                if let state = flowchartState {
                                    selectedProjectState = state
                                    showPreview = true
                                }
                            }
                        },
                        onStar: {
                            viewModel.toggleStar(projectId: project.id)
                        },
                        onFork: {
                            viewModel.forkProject(projectId: project.id)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.black : Color.clear)
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.black : Color.gray, lineWidth: 1)
                )
        }
    }
}

// MARK: - Community Project Card

struct CommunityProjectCard: View {
    let project: CommunityProjectDto
    let isAuthor: Bool
    let onClick: () -> Void
    let onStar: () -> Void
    let onFork: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                Text(project.title)
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.pixelDarkBlue)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(16)
            
            // Description
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .padding(.horizontal, 16)
            }
            
            // Author
            HStack(spacing: 4) {
                Text("by \(project.authorName)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.black)
                if isAuthor {
                    Text("(You)")
                        .font(.system(size: 10, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            Spacer()
            
            // Stats and actions
            VStack(spacing: 8) {
                // Stats row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.pixelGold)
                            .font(.system(size: 12))
                        Text("\(project.starCount)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.branch")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        Text("\(project.forkCount)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    
                    Text(formatTimestamp(project.createdAt))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    // Star button
                    Button(action: onStar) {
                        HStack(spacing: 4) {
                            Image(systemName: project.isStarredByUser ? "star.fill" : "star")
                                .font(.system(size: 12))
                            Text(project.isStarredByUser ? "STARRED" : "STAR")
                                .font(.system(size: 10, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(project.isStarredByUser ? .white : .pixelOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(project.isStarredByUser ? Color.pixelGold : Color.themeCardBackground)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(project.isStarredByUser ? Color.black : Color.pixelOrange, lineWidth: 2)
                        )
                    }
                    
                    // Fork button
                    Button(action: onFork) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.branch")
                                .font(.system(size: 12))
                            Text(isAuthor ? "YOUR PROJECT" : "FORK")
                                .font(.system(size: 10, design: .monospaced))
                                .fontWeight(.bold)
                        }
                        .foregroundColor(isAuthor ? .gray : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(isAuthor ? Color.white : Color.green)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isAuthor ? Color.gray : Color.black, lineWidth: 2)
                        )
                    }
                    .disabled(isAuthor)
                }
            }
            .padding(16)
        }
        .frame(height: 200)
        .background(PixelBackground(fillColor: .themeCardBackground))
    }
    
    private func formatTimestamp(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview Overlay With History

struct PreviewOverlayWithHistory: View {
    let state: FlowchartState
    let onClose: () -> Void
    
    @State private var currentNodeId: String?
    @State private var storyHistory: [StoryStep] = []
    @State private var showHistory = false
    
    var body: some View {
        if showHistory {
            StoryHistoryView(
                history: storyHistory,
                onClose: { showHistory = false }
            )
        } else {
            previewView
        }
    }
    
    private var previewView: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                ScrollView {
                    if let nodeId = currentNodeId,
                       let node = state.findNode(id: nodeId) {
                        nodeContent(node)
                            .padding()
                    }
                }
                .background(Color(hex: "2A2A2A"))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
            }
            .padding()
        }
        .onAppear {
            if let start = state.nodes.first(where: { $0.type == .start }) {
                currentNodeId = start.id
                storyHistory = [StoryStep(
                    nodeId: start.id,
                    nodeType: start.type,
                    text: start.text,
                    imageData: start.imageData,
                    choice: nil,
                    timestamp: Date()
                )]
            }
        }
    }
    
    private var header: some View {
        HStack {
            Text("📖 STORY MODE")
                .font(.system(size: 16, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00FF00"))
                .tracking(1)
            
            Spacer()
            
            PixelButton(icon: "📜") {
                showHistory = true
            }
            
            PixelButton(icon: "✕", action: onClose)
        }
        .padding(12)
        .background(Color(hex: "1A1A1A"))
        .overlay(
            Rectangle()
                .stroke(Color.black, lineWidth: 3)
        )
    }
    
    @ViewBuilder
    private func nodeContent(_ node: FlowNode) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Node type badge
            Text("▶ \(node.type.emoji) \(node.type.rawValue.uppercased())")
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00FF00"))
                .tracking(0.5)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(hex: "1A1A1A"))
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                )
            
            // Image if exists
            if !node.imageData.isEmpty {
                Base64Image(base64String: node.imageData, placeholder: "photo")
                    .frame(height: 300)
                    .background(Color(hex: "1A1A1A"))
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
                    )
            }
            
            // Text content
            Text(node.text.isEmpty ? "No text provided." : node.text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(6)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "1A1A1A"))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            // Navigation options
            navigationOptions(for: node)
        }
    }
    
    @ViewBuilder
    private func navigationOptions(for node: FlowNode) -> some View {
        switch node.type {
        case .start, .story:
            let decisions = node.outs.compactMap { state.findNode(id: $0) }.filter { $0.type == .decision }
            
            if !decisions.isEmpty {
                choicesView(decisions)
            } else if let nextNode = node.outs.compactMap({ state.findNode(id: $0) }).first {
                PixelTextButton(text: "→ CONTINUE") {
                    navigateTo(nextNode)
                }
            }
            
        case .decision:
            let options = node.outs.compactMap { state.findNode(id: $0) }
            if !options.isEmpty {
                choicesView(options)
            }
            
        case .end:
            endView
        }
    }
    
    private func choicesView(_ choices: [FlowNode]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚔ CHOOSE YOUR PATH:")
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00FF00"))
                .tracking(0.5)
            
            ForEach(choices) { choice in
                PixelTextButton(text: "→ \(choice.text.isEmpty ? "Choice" : choice.text)") {
                    navigateTo(choice, choiceText: choice.text)
                }
            }
        }
    }
    
    private var endView: some View {
        VStack(spacing: 16) {
            Text("★ THE END ★")
                .font(.system(size: 20, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00FF00"))
                .tracking(2)
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color(hex: "1A3A1A"))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
            
            PixelTextButton(text: "📜 VIEW FULL STORY") {
                showHistory = true
            }
            
            PixelTextButton(text: "↻ RESTART STORY") {
                if let start = state.nodes.first(where: { $0.type == .start }) {
                    currentNodeId = start.id
                    storyHistory = [StoryStep(
                        nodeId: start.id,
                        nodeType: start.type,
                        text: start.text,
                        imageData: start.imageData,
                        choice: nil,
                        timestamp: Date()
                    )]
                }
            }
        }
    }
    
    private func navigateTo(_ node: FlowNode, choiceText: String? = nil) {
        currentNodeId = node.id
        storyHistory.append(StoryStep(
            nodeId: node.id,
            nodeType: node.type,
            text: node.text,
            imageData: node.imageData,
            choice: choiceText,
            timestamp: Date()
        ))
    }
}

// MARK: - Story History View

struct StoryHistoryView: View {
    let history: [StoryStep]
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color(hex: "0a0a0a").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("📜 YOUR STORY")
                        .font(.system(size: 16, design: .monospaced))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "00FF00"))
                        .tracking(1)
                    
                    Spacer()
                    
                    PixelButton(icon: "✕", action: onClose)
                }
                .padding(12)
                .background(Color(hex: "1A1A1A"))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
                
                // History content
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(history.enumerated()), id: \.offset) { index, step in
                            historyStepView(step: step, index: index)
                            
                            if index < history.count - 1 {
                                Rectangle()
                                    .fill(Color(hex: "4A4A4A"))
                                    .frame(height: 2)
                            }
                        }
                        
                        summaryView
                    }
                    .padding(16)
                }
                .background(Color(hex: "2A2A2A"))
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 3)
                )
            }
            .padding()
        }
    }
    
    private func historyStepView(step: StoryStep, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("STEP \(index + 1)")
                    .font(.system(size: 10, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "00FF00"))
                
                Spacer()
                
                Text("\(step.nodeType.emoji) \(step.nodeType.rawValue.uppercased())")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            if let choice = step.choice, !choice.isEmpty {
                Text("→ Choice: \(choice)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(hex: "AAAAFF"))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "3A2A5A"))
                    .overlay(
                        Rectangle()
                            .stroke(Color(hex: "5A5AFF"), lineWidth: 2)
                    )
            }
            
            Text(step.text.isEmpty ? "No text" : step.text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white)
                .lineSpacing(4)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "1A1A1A"))
                .overlay(
                    Rectangle()
                        .stroke(Color(hex: "4A4A4A"), lineWidth: 2)
                )
        }
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("📊 SUMMARY")
                .font(.system(size: 12, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "00FF00"))
            
            Text("Total Steps: \(history.count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
            
            Text("Choices Made: \(history.filter { $0.choice != nil }.count)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1A3A1A"))
        .overlay(
            Rectangle()
                .stroke(Color(hex: "00FF00"), lineWidth: 2)
        )
    }
}
