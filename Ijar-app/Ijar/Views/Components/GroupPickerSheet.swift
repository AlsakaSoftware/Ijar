import SwiftUI
import Kingfisher

struct GroupPickerSheet: View {
    let property: Property
    let propertyService: PropertyService
    let savedPropertyRepository: SavedPropertyRepository
    @Environment(\.dismiss) private var dismiss

    @State private var groups: [PropertyGroup] = []
    @State private var showCreateGroup = false
    @State private var newGroupName = ""
    @State private var isLoadingGroups = true
    @State private var isSaving = false
    @State private var originalGroupIds: [String] = []
    @State private var localSelectedIds: [String] = []

    private var isSaved: Bool {
        savedPropertyRepository.isSaved(property.id)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if isLoadingGroups {
                        loadingView
                    } else {
                        // Saved property header
                        savedPropertyHeader
                            .padding(.top, 16)

                        Divider()
                            .padding(.vertical, 16)

                        // Add to a list section
                        addToListSection
                    }
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.warmCream)
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveChangesAndDismiss()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .tint(.rusticOrange)
                        } else {
                            Text("Done")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.rusticOrange)
                    .disabled(isSaving)
                }
            }
            .task {
                // If property is not saved yet, save it first
                if !isSaved {
                    let success = await savedPropertyRepository.save(property)
                    if !success {
                        dismiss()
                        return
                    }
                }

                groups = await propertyService.loadGroups()
                // Load which groups this property is already in
                let currentGroups = await propertyService.getGroupsForProperty(propertyId: property.id)
                originalGroupIds = currentGroups
                localSelectedIds = currentGroups
                isLoadingGroups = false
            }
            .alert("New Group", isPresented: $showCreateGroup) {
                TextField("Group name", text: $newGroupName)
                Button("Cancel", role: .cancel) {
                    newGroupName = ""
                }
                Button("Create") {
                    createGroup()
                }
                .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Create a new group for your saved properties")
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 100)
            ProgressView()
                .scaleEffect(1.2)
                .tint(.rusticOrange)
            Text("Loading...")
                .font(.system(size: 15))
                .foregroundColor(.warmBrown.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var savedPropertyHeader: some View {
        HStack(spacing: 12) {
            // Property thumbnail
            if let firstImage = property.images.first {
                KFImage(URL(string: firstImage))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.warmBrown.opacity(0.1))
                    .frame(width: 60, height: 60)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Saved property")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.coffeeBean)

                Text(property.address)
                    .font(.system(size: 14))
                    .foregroundColor(.warmBrown.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer()

            // Unsave button
            Button {
                unsaveProperty()
            } label: {
                Text("Unsave")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.rusticOrange)
            }
        }
    }

    private var addToListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add to a group")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.coffeeBean)

            // Groups list
            VStack(spacing: 12) {
                ForEach(groups) { group in
                    GroupRowItem(
                        group: group,
                        isSelected: localSelectedIds.contains(group.id),
                        onToggle: {
                            toggleGroup(group)
                        }
                    )
                }

                // Create a group button
                Button {
                    showCreateGroup = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.rusticOrange)

                        Text("Create a group")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.rusticOrange)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func toggleGroup(_ group: PropertyGroup) {
        // Just update local state - no API call yet
        if localSelectedIds.contains(group.id) {
            localSelectedIds.removeAll { $0 == group.id }
        } else {
            localSelectedIds.append(group.id)
        }
    }

    private func createGroup() {
        Task {
            if let group = await propertyService.createGroup(name: newGroupName) {
                // Add to local groups and auto-select
                groups.insert(group, at: 0)
                localSelectedIds.append(group.id)
            }
            newGroupName = ""
        }
    }

    private func saveChangesAndDismiss() {
        isSaving = true

        Task {
            // Find groups to add (in local but not in original)
            let toAdd = localSelectedIds.filter { !originalGroupIds.contains($0) }

            // Find groups to remove (in original but not in local)
            let toRemove = originalGroupIds.filter { !localSelectedIds.contains($0) }

            // Add to new groups
            for groupId in toAdd {
               _ = await propertyService.addPropertyToGroup(propertyId: property.id, groupId: groupId)
            }

            // Remove from unselected groups
            for groupId in toRemove {
                _ = await propertyService.removePropertyFromGroup(propertyId: property.id, groupId: groupId)
            }

            isSaving = false
            dismiss()
        }
    }

    private func unsaveProperty() {
        isSaving = true

        Task {
            // Remove from all groups first
            for groupId in localSelectedIds {
                _ = await propertyService.removePropertyFromGroup(propertyId: property.id, groupId: groupId)
            }

            // Unsave from All Saved
            await savedPropertyRepository.unsave(property)

            isSaving = false
            dismiss()
        }
    }
}

struct GroupRowItem: View {
    let group: PropertyGroup
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.coffeeBean)

                    Text("\(group.propertyCount ?? 0) properties")
                        .font(.system(size: 14))
                        .foregroundColor(.warmBrown.opacity(0.6))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .rusticOrange : .warmBrown.opacity(0.3))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
