import SwiftUI

class NavigationCoordinator: ObservableObject {
    @Published var shouldPopToRoot = false

    func popToRoot() {
        shouldPopToRoot = true
        // Reset immediately to allow future pops
        DispatchQueue.main.async {
            self.shouldPopToRoot = false
        }
    }
}
