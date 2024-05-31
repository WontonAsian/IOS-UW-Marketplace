import SwiftUI

struct UserProfileView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    Text("User Name: Kevin")
                    Text("Email: kevin@example.com")
                }

                Section(header: Text("Listed Items")) {
                    Text("Item 1")
                    Text("Item 2")
                }

                Button("Log Out") {
                    // Handle log out
                }
                .foregroundColor(.red)
            }
            .navigationBarTitle("User Profile", displayMode: .inline)
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
