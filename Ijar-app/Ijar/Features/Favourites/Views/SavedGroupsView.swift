import SwiftUI

struct SavedGroupsView: View {
    @EnvironmentObject var coordinator: SavedPropertiesCoordinator
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var viewModel = SavedGroupsViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if authService.isInGuestMode {
                guestEmptyStateView
                    .padding(.top, 20)
            } else if viewModel.isLoading {
                loadingView
            } else {
                groupsListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmCream)
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Favourites")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.coffeeBean)

                Text("Your curated shortlist")
                    .font(.system(size: 18))
                    .foregroundColor(.warmBrown.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(Color.warmCream)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(.rusticOrange)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !authService.isInGuestMode {
                    Button {
                        viewModel.showCreateGroupSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.rusticOrange)
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showCreateGroupSheet) {
            createGroupSheet
        }
        .task {
            if !authService.isInGuestMode {
                await viewModel.loadData()
            }
            withAnimation(.easeOut(duration: 0.4)) {
                viewModel.animateContent = true
            }
        }
        .onAppear {
            guard !viewModel.isLoading && !authService.isInGuestMode else { return }
            Task {
                await viewModel.refreshData()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.rusticOrange.opacity(0.3))
                        .frame(width: 12, height: 12)
                        .offset(x: CGFloat(index - 1) * 30)
                        .scaleEffect(viewModel.animateContent ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.8)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: viewModel.animateContent
                        )
                }
            }

            Text("Loading your saved homes...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.warmBrown)

            Spacer()
        }
    }

    private var guestEmptyStateView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Text("Create a free account to save properties you love and organize them into groups.")
                        .font(.system(size: 17))
                        .foregroundColor(.warmBrown.opacity(0.7))
                        .opacity(viewModel.animateContent ? 1 : 0)
                        .offset(y: viewModel.animateContent ? 0 : 15)
                        .padding(.horizontal, 24)

                    VStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.warmBrown.opacity(0.08))
                                .frame(height: 80)
                                .overlay(
                                    HStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.warmBrown.opacity(0.12))
                                            .frame(width: 50, height: 50)
                                        VStack(alignment: .leading, spacing: 6) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.warmBrown.opacity(0.1))
                                                .frame(width: 100, height: 14)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.warmBrown.opacity(0.06))
                                                .frame(width: 60, height: 12)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                )
                                .opacity(viewModel.animateContent ? 1 : 0)
                                .offset(y: viewModel.animateContent ? 0 : 20)
                                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 0.2), value: viewModel.animateContent)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 100)
                }
            }

            VStack(spacing: 0) {
                SignInWithAppleButtonView()
                    .padding(.horizontal, 24)
                    .opacity(viewModel.animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.4), value: viewModel.animateContent)
            }
            .padding(.vertical, 16)
            .background(Color.warmCream)
        }
        .animation(.easeOut(duration: 0.35), value: viewModel.animateContent)
    }

    private var groupsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                GroupCard(
                    title: "All Saved",
                    count: viewModel.savedPropertiesCount,
                    icon: "heart.fill",
                    iconColor: .warmRed
                ) {
                    coordinator.navigate(to: .allSaved)
                }
                .padding(.horizontal, 20)
                .opacity(viewModel.animateContent ? 1 : 0)
                .offset(y: viewModel.animateContent ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.animateContent)

                if !viewModel.groups.isEmpty {
                    HStack {
                        Text("Your Groups")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.warmBrown.opacity(0.6))
                            .textCase(.uppercase)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 4)

                    ForEach(Array(viewModel.groups.enumerated()), id: \.element.id) { index, group in
                        GroupCard(
                            title: group.name,
                            count: group.propertyCount ?? 0,
                            icon: "folder.fill",
                            iconColor: .rusticOrange
                        ) {
                            coordinator.navigate(to: .groupProperties(group: group))
                        }
                        .padding(.horizontal, 20)
                        .opacity(viewModel.animateContent ? 1 : 0)
                        .offset(y: viewModel.animateContent ? 0 : 30)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index + 1) * 0.08),
                            value: viewModel.animateContent
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteGroup(group)
                                }
                            } label: {
                                Label("Delete Group", systemImage: "trash")
                            }
                        }
                    }
                }

                if viewModel.groups.isEmpty && viewModel.savedPropertiesCount == 0 {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.warmBrown.opacity(0.3))

                        Text("No saved properties yet")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.warmBrown.opacity(0.6))

                        Text("Heart properties you like and they'll appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.warmBrown.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                    .padding(.horizontal, 40)
                }
            }
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var createGroupSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Group Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.warmBrown.opacity(0.7))

                    TextField("e.g. Near Work, Shortlist", text: $viewModel.newGroupName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.warmBrown.opacity(0.08))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()
            }
            .background(Color.warmCream)
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.newGroupName = ""
                        viewModel.showCreateGroupSheet = false
                    }
                    .foregroundColor(.warmBrown)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await viewModel.createGroup()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.rusticOrange)
                    .disabled(viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }
}

struct GroupCard: View {
    let title: String
    let count: Int
    let icon: String
    let iconColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.coffeeBean)

                    Text("\(count) \(count == 1 ? "property" : "properties")")
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.6))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.warmBrown.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
