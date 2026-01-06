import SwiftUI

// MARK: - Projects Main Screen with Tabs

// MARK: - Projects Main Screen with Tabs
// MARK: - Projects Main Screen with Tabs
struct ProjectIdWrapper: Identifiable {
    let id: String
}

struct ProjectsMainScreen: View {
    @State private var selectedTab = 0
    @StateObject private var storyProjectViewModel = StoryProjectViewModel()
    @StateObject private var communityProjectViewModel = CommunityProjectViewModel()
    
    let tabs = ["📚 My Projects", "🌍 Community"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar
            customTabBar
            
            // Content based on selected tab
            TabView(selection: $selectedTab) {
                ProjectsListScreenWithNavigation()
                    .environmentObject(storyProjectViewModel)  // ← PASS TO CHILD
                    .tag(0)
                
                CommunityProjectsScreen()
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color.themeBeige)
    }
    
    
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, design: .monospaced))
                            .fontWeight(selectedTab == index ? .bold : .regular)
                            .foregroundColor(selectedTab == index ? .black : .gray)
                            .tracking(1)
                            .padding(.vertical, 8)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color.black : Color.clear)
                            .frame(height: 3)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .background(PixelBackground(fillColor: .white))
    }
}



// MARK: - Projects List Screen with Navigation

struct ProjectsListScreenWithNavigation: View {
    @EnvironmentObject var viewModel: StoryProjectViewModel  // ← USE ENVIRONMENT
    @State private var showCreateDialog = false
    @State private var projectToDelete: ProjectDto?
    @State private var projectToShare: ProjectDto?
    @State private var activeProject: ProjectIdWrapper?
    
    var body: some View {
        ZStack {
            Color.themeBeige.ignoresSafeArea()
                
            VStack(spacing: 0) {
                createButtonBar
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.projects.isEmpty {
                    emptyStateView
                } else {
                    projectsGrid
                }
            }
                if showCreateDialog {
                    CreateProjectDialog(
                        onCreate: { title, description in
                            showCreateDialog = false
                            viewModel.createNewProject(title: title, description: description) { projectId in
                                activeProject = ProjectIdWrapper(id: projectId)
                            }
                        },
                        onCancel: {
                            showCreateDialog = false
                        }
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
                
                if let project = projectToDelete {
                    DeleteConfirmationDialog(
                        projectTitle: project.title,
                        onConfirm: {
                            viewModel.deleteProject(projectId: project.id)
                            projectToDelete = nil
                        },
                        onCancel: {
                            projectToDelete = nil
                        }
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
                
                if let project = projectToShare {
                    ShareConfirmationDialog(
                        projectTitle: project.title,
                        isLoading: viewModel.publishState == .loading
                    ) {
                        viewModel.publishProject(projectId: project.id) {
                            projectToShare = nil
                        }
                    } onDismiss: {
                        projectToShare = nil
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
        .fullScreenCover(item: $activeProject) { projectWrapper in
            FlowBuilderScreenWrapper(
                projectId: projectWrapper.id,
                onDismiss: {
                    activeProject = nil
                }
            )
            .environmentObject(viewModel)
        }
    }
    
    private var createButtonBar: some View {
        HStack {
            Spacer()
            Button(action: { showCreateDialog = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.black, lineWidth: 2)
                    )
            }
        }
        .padding()
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .pixelGold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("📝")
                .font(.system(size: 64))
            Text("No projects yet")
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(.gray)
            Text("Click the + button to create your first story!")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
private var projectsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                ForEach(viewModel.projects) { project in
                    ProjectCard(
                        project: project,
                        onClick: {
                            activeProject = ProjectIdWrapper(id: project.id)
                        },
                        onDelete: { projectToDelete = project },
                        onShare: { projectToShare = project }
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Flow Builder Screen Wrapper

struct FlowBuilderScreenWrapper: View {
    let projectId: String
    @EnvironmentObject var storyViewModel: StoryProjectViewModel
    let onDismiss: () -> Void
    
    @StateObject private var state = FlowchartState()
    
    var body: some View {
        NavigationView {
            FlowchartEditorView(
                state: state,
                projectId: projectId,
                viewModel: storyViewModel
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading:
                Button(action: onDismiss) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Projects")
                    }
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(.black)
                }
            )
            .navigationTitle("✏️ PROJECT EDITOR")
        }
        .accentColor(.pixelGold)
    }
}
// MARK: - Preview

#if DEBUG
struct ProjectsMainScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProjectsMainScreen()
                .environmentObject(ThemeManager.shared)
                .preferredColorScheme(.dark)
            
            ProjectsListScreenWithNavigation()
                .environmentObject(ThemeManager.shared)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
