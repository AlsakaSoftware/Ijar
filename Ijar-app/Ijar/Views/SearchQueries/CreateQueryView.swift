import SwiftUI

struct CreateQueryView: View {
    @StateObject private var viewModel: CreateQueryViewModel
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    init(editingQuery: SearchQuery?) {
        _viewModel = StateObject(wrappedValue: CreateQueryViewModel(editingQuery: editingQuery))
    }
    
    var body: some View {
        Form {
            Section("Search Details") {
                TextField("Search Name", text: $viewModel.name)
                    .textContentType(.name)
            }
            
            Section("Location") {
                Picker("Location", selection: $viewModel.selectedLocation) {
                    Text("Select a location").tag(nil as Location?)
                    
                    ForEach(Location.presetLocations) { location in
                        Text(location.name).tag(location as Location?)
                    }
                    
                    Text(Location.customLocation.name).tag(Location.customLocation as Location?)
                }
                
                if viewModel.selectedLocation?.id == Location.customLocation.id {
                    TextField("Location Name", text: $viewModel.customLocationName)
                    
                    TextField("Location ID", text: $viewModel.customLocationId)
                        .textContentType(.none)
                        .autocapitalization(.none)
                    
                    Button(action: { viewModel.showLocationIdHelp = true }) {
                        Label("How to find location ID", systemImage: "questionmark.circle")
                            .font(.caption)
                    }
                }
            }
            
            Section("Price Range") {
                VStack(alignment: .leading) {
                    Text("£\(Int(viewModel.minPrice)) - £\(Int(viewModel.maxPrice)) per month")
                        .font(.headline)
                    
                    Text("Minimum: £\(Int(viewModel.minPrice))")
                        .font(.caption)
                    Slider(value: $viewModel.minPrice, in: 500...viewModel.maxPrice, step: 50)
                    
                    Text("Maximum: £\(Int(viewModel.maxPrice))")
                        .font(.caption)
                    Slider(value: $viewModel.maxPrice, in: viewModel.minPrice...5000, step: 50)
                }
            }
            
            Section("Property Details") {
                Stepper("Min Bedrooms: \(viewModel.minBedrooms)", value: $viewModel.minBedrooms, in: 1...viewModel.maxBedrooms)
                
                Stepper("Max Bedrooms: \(viewModel.maxBedrooms)", value: $viewModel.maxBedrooms, in: viewModel.minBedrooms...5)
                
                Stepper("Min Bathrooms: \(viewModel.minBathrooms)", value: $viewModel.minBathrooms, in: 1...3)
                
                Picker("Furnished", selection: $viewModel.furnishedType) {
                    ForEach(FurnishedType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                
                Picker("Property Type", selection: $viewModel.propertyType) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Search" : "New Search")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    viewModel.save()
                }
                .disabled(!viewModel.isValid || viewModel.isLoading)
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $viewModel.showLocationIdHelp) {
            LocationIdHelpView()
        }
        .onAppear {
            viewModel.navigationCoordinator = navigationCoordinator
        }
    }
}

struct LocationIdHelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Find Location ID")
                        .font(.headline)
                    
                    Text("1. Go to rightmove.co.uk")
                    Text("2. Search for your desired area")
                    Text("3. Look at the URL in your browser")
                    Text("4. Copy the value after 'locationIdentifier='")
                    
                    Text("Example:")
                        .font(.headline)
                        .padding(.top)
                    
                    Text("If the URL contains:")
                        .font(.caption)
                    
                    Text("locationIdentifier=REGION%5E87490")
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Text("Then copy: REGION%5E87490")
                        .font(.caption)
                }
                .padding()
            }
            .navigationTitle("Location ID Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}