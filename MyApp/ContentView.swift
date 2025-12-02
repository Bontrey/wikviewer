import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            Circle()
                .fill(Color.blue)
                .frame(width: 200, height: 200)
        }
    }
}

#Preview {
    ContentView()
}
