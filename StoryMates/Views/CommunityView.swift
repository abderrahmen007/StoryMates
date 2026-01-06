//
//  ContentView.swift
//  community
//
//  Created by Mac Mini 9 on 18/11/2025.
//

import SwiftUI

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = PostViewModel()
    @State private var showCreateSheet = false
    @State private var editingPost: Post?
    @State private var postPendingDeletion: Post?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                PixelArtTheme.gray
                    .ignoresSafeArea()
                
                Image("background_general")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.5)

                ZStack {
                    Image("background_general")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                PostCardView(
                                    post: post,
                                    onLike: { viewModel.like(post: post) },
                                    onAddComment: { text in viewModel.addComment(to: post, content: text) },
                                    onEdit: { editingPost = post },
                                    onDelete: { postPendingDeletion = post }
                                )
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100) // Space for FAB
                    }
                    .refreshable { await viewModel.loadPosts() }
                }
                .navigationTitle("Community")
                .navigationBarTitleDisplayMode(.large)

                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                }

                // ➕ Modern FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
                        }
                        .padding(24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadPosts()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreatePostView(
                onCancel: { showCreateSheet = false },
                onSave: { title, content, photo in
                    viewModel.createPost(title: title, content: content, photo: photo) {
                        showCreateSheet = false
                    }
                }
            )
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                ),
                actions: {
                    Button("OK", role: .cancel) { }
                },
                message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
            )
        }
        .sheet(item: $editingPost) { post in
            EditPostView(
                post: post,
                onCancel: { editingPost = nil },
                onSave: { title, content, photo in
                    viewModel.updatePost(id: post.id, title: title, content: content, photo: photo) {
                        editingPost = nil
                    }
                }
            )
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { _ in viewModel.errorMessage = nil }
                ),
                actions: {
                    Button("OK", role: .cancel) { }
                },
                message: {
                    Text(viewModel.errorMessage ?? "Unknown error")
                }
            )
        }
        .confirmationDialog(
            "Delete this post?",
            isPresented: Binding(
                get: { postPendingDeletion != nil },
                set: { newValue in
                    if !newValue { postPendingDeletion = nil }
                }
            ),
            presenting: postPendingDeletion
        ) { post in
            Button("Delete", role: .destructive) {
                viewModel.delete(post: post) {
                    postPendingDeletion = nil
                }
            }
        } message: {_ in 
            Text("This action cannot be undone.")
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil && !showCreateSheet && editingPost == nil },
                set: { _ in viewModel.errorMessage = nil }
            ),
            actions: {
                Button("OK", role: .cancel) { }
            },
            message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        )
    }
}
