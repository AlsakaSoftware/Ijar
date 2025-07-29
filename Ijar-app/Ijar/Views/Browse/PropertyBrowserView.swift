import SwiftUI

struct PropertyBrowserView: View {
    @StateObject private var viewModel = PropertyBrowserViewModel()
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @State private var dragAmount = CGSize.zero
    @State private var dragDirection: SwipeDirection = .none
    
    enum SwipeDirection {
        case left, right, none
    }
    
    var body: some View {
        ZStack {
            if viewModel.hasNoMoreProperties {
                NoPropertiesView()
            } else if viewModel.hasProperties {
                PropertyStackView(
                    properties: viewModel.properties,
                    currentIndex: viewModel.currentIndex,
                    dragAmount: dragAmount,
                    dragDirection: dragDirection,
                    onSwipeRight: viewModel.likeCurrentProperty,
                    onSwipeLeft: viewModel.dismissCurrentProperty,
                    onTap: viewModel.openPropertyInBrowser
                )
                .gesture(dragGesture)
            } else if viewModel.isLoading {
                ProgressView("Loading properties...")
            }
            
            // Action buttons
            VStack {
                Spacer()
                
                HStack(spacing: 60) {
                    // Dismiss button
                    Button(action: viewModel.dismissCurrentProperty) {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.red))
                    }
                    .disabled(!viewModel.hasProperties)
                    
                    // Like button
                    Button(action: viewModel.likeCurrentProperty) {
                        Image(systemName: "heart.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.green))
                    }
                    .disabled(!viewModel.hasProperties)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Browse")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: viewModel.fetchNewProperties) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.navigationCoordinator = navigationCoordinator
        }
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragAmount = value.translation
                
                if value.translation.width > 50 {
                    dragDirection = .right
                } else if value.translation.width < -50 {
                    dragDirection = .left
                } else {
                    dragDirection = .none
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                
                if value.translation.width > threshold {
                    viewModel.likeCurrentProperty()
                } else if value.translation.width < -threshold {
                    viewModel.dismissCurrentProperty()
                }
                
                dragAmount = .zero
                dragDirection = .none
            }
    }
}

struct NoPropertiesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("No new properties")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Check back tomorrow after 9 AM\nfor fresh property matches")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}