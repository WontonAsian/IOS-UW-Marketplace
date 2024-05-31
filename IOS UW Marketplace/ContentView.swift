import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AllItemsView()
                .tabItem {
                    Label("All Items", systemImage: "list.bullet")
                }
            
            SellView()
                .tabItem {
                    Label("Sell", systemImage: "square.and.pencil")
                }

            UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
