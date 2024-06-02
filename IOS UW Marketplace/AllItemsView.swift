import SwiftUI

struct AllItemsView: View {
    var userEmail: String
    var userName: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        TabView {
            VStack {
                Text("All Items")
                    .font(.largeTitle)
                    .padding()

                List {
                    Text("Item 1")
                    Text("Item 2")
                    Text("Item 3")
                }
            }
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
    }
}

struct AllItemsView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        AllItemsView(userEmail: "kevin@example.com", userName: "Kevin", isAuthenticated: $isAuthenticated)
    }
}
