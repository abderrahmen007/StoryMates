import SwiftUI

struct ReferencesScreen: View {
    let projectId: String
    @ObservedObject var viewModel: StoryProjectViewModel
    
    @State private var searchText = ""
    @State private var selectedCategory: ReferenceType? = nil
    @State private var showAddDialog = false
    @State private var showArtStyleSelector = false
    @State private var referenceToEdit: Reference?
    
    private let pixelAccent = Color.pixelGold
    
    var filteredReferences: [Reference] {
        viewModel.references.filter { ref in
            let matchesSearch = searchText.isEmpty || ref.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || ref.type == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.pixelDarkBlue, Color(red: 0.1, green: 0.1, blue: 0.2)]),
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            if viewModel.referencesLoading && viewModel.references.isEmpty {
                loadingView
            } else if viewModel.projectArtStyle == nil || showArtStyleSelector {
                ArtStyleSelectionWrapper(
                    projectId: projectId,
                    viewModel: viewModel,
                    initialStyle: viewModel.projectArtStyle?.artStyle ?? .STANDARD_2D,
                    initialDimension: viewModel.projectArtStyle?.dimension ?? .TWO_D,
                    onDismiss: { showArtStyleSelector = false }
                )
            } else {
                VStack(spacing: 0) {
                    headerView
                    
                    categoryPicker
                    
                    searchBar
                    
                    if filteredReferences.isEmpty {
                        emptyView
                    } else {
                        referenceList
                    }
                }
                
                floatingAddButton
            }
        }
        .onAppear {
            viewModel.loadReferences(projectId: projectId)
        }
        .onChange(of: projectId) { newId in
            viewModel.loadReferences(projectId: newId)
        }
        .sheet(isPresented: $showAddDialog) {
            AddReferenceDialog(projectId: projectId, viewModel: viewModel, onDismiss: { showAddDialog = false })
        }
        .sheet(item: $referenceToEdit) { reference in
            EditReferenceDialog(projectId: projectId, reference: reference, viewModel: viewModel, onDismiss: { referenceToEdit = nil })
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🎨 WORLD BUILDING")
                    .font(.custom("Courier", size: 10).weight(.black))
                    .foregroundColor(pixelAccent)
                Text(viewModel.projectArtStyle?.artStyle.displayName ?? "Select Style")
                    .font(.custom("Courier", size: 18).weight(.bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.4))
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(title: "ALL", isActive: selectedCategory == nil) {
                    selectedCategory = nil
                }
                
                ForEach(ReferenceType.allCases, id: \.self) { type in
                    CategoryChip(title: type.rawValue, isActive: selectedCategory == type) {
                        selectedCategory = type
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(pixelAccent)
            TextField("SEARCH REFERENCES...", text: $searchText)
                .font(.custom("Courier", size: 14))
                .foregroundColor(.white)
        }
        .padding(12)
        .background(Color.black.opacity(0.3))
        .border(Color.white.opacity(0.2), width: 1)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var referenceList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredReferences) { reference in
                    ReferenceCard(
                        reference: reference,
                        projectArtStyle: viewModel.projectArtStyle,
                        onEdit: { referenceToEdit = reference },
                        onDelete: { viewModel.deleteReference(projectId: projectId, referenceId: reference.id) }
                    )
                }
            }
            .padding(.vertical)
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: pixelAccent))
                    .scaleEffect(2)
                Text("RETRIEVING WORLD DATA...")
                    .font(.custom("Courier", size: 14))
                    .foregroundColor(pixelAccent)
            }
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Text(searchText.isEmpty ? "🌑" : "🔍")
                    .font(.system(size: 64))
                Text(searchText.isEmpty ? "THE WORLD IS EMPTY" : "NO MATCHES FOUND")
                    .font(.custom("Courier", size: 18).weight(.bold))
                    .foregroundColor(.white)
                Text(searchText.isEmpty ? "Start by adding characters or locations to your project." : "Try a different search term or category.")
                    .font(.custom("Courier", size: 12))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
        }
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showAddDialog = true }) {
                    ZStack {
                        Rectangle()
                            .fill(pixelAccent)
                            .frame(width: 56, height: 56)
                            .border(Color.black, width: 3)
                            .shadow(color: .black.opacity(0.5), radius: 0, x: 4, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.title.bold())
                            .foregroundColor(.black)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Courier", size: 12).weight(.bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Color.pixelGold : Color.white.opacity(0.1))
                .foregroundColor(isActive ? .black : .white)
                .border(isActive ? Color.black : Color.white.opacity(0.3), width: 2)
        }
    }
}

// Keep ArtStyleSelectionWrapper... (I'll keep it from previous file)
struct ArtStyleSelectionWrapper: View {
    let projectId: String
    @ObservedObject var viewModel: StoryProjectViewModel
    @State var selectedStyle: ArtStyle
    @State var selectedDimension: ArtDimension
    let onDismiss: () -> Void
    
    init(projectId: String, viewModel: StoryProjectViewModel, initialStyle: ArtStyle, initialDimension: ArtDimension, onDismiss: @escaping () -> Void) {
        self.projectId = projectId
        self.viewModel = viewModel
        _selectedStyle = State(initialValue: initialStyle)
        _selectedDimension = State(initialValue: initialDimension)
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        ArtStyleSelector(
            selectedStyle: $selectedStyle,
            selectedDimension: $selectedDimension,
            onSave: {
                viewModel.updateArtStyle(projectId: projectId, artStyle: selectedStyle, dimension: selectedDimension)
                onDismiss()
            }
        )
    }
}
