import SwiftUI

struct UserProfileView: View {
    var userName: String
    var userEmail: String
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    Text("User Name: \(userName)")
                    Text("Email: \(userEmail)")
                }

                Section(header: Text("Listed Items")) {
                    Text("Item 1")
                    Text("Item 2")
                }

                Button("Log Out") {
                    isAuthenticated = false
                }
                .foregroundColor(.red)
            }
            .navigationBarTitle("User Profile", displayMode: .inline)
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        UserProfileView(userName: "Kevin", userEmail: "kevin@example.com", isAuthenticated: $isAuthenticated)
    }
}
