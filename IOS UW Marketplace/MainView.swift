import SwiftUI

struct MainView: View {
    var userName: String
    var userEmail: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        TabView {
            AllItemsView(userName: userName, userEmail: userEmail, isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("All Items", systemImage: "list.bullet")
                }

            SellView(userEmail: userEmail)
                .tabItem {
                    Label("Sell", systemImage: "square.and.pencil")
                }

            UserProfileView(userName: userName, userEmail: userEmail, isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .onAppear {
            // Check if the user is authenticated when the view appears
            if UserDefaults.standard.bool(forKey: "isAuthenticated") {
                self.isAuthenticated = true
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        MainView(userName: "michelle", userEmail: "mwu1@uw.edu", isAuthenticated: $isAuthenticated)
    }
}
