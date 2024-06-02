import SwiftUI
import MSAL

struct LoginView: View {
    @State private var isAuthenticated = false
    @State private var userName: String = ""
    @State private var userEmail: String = ""

    var body: some View {
        NavigationStack {
            VStack {
                if isAuthenticated {
                    // Navigate to AllItemsView when authenticated
                    AllItemsView(userEmail: userEmail, userName: userName, isAuthenticated: $isAuthenticated)
                } else {
                    Text("Welcome to UW Marketplace")
                        .font(.largeTitle)
                        .padding()

                    Button(action: authenticateWithAzureAD) {
                        Text("Login with UWNetID")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.purple)
                            .cornerRadius(12)
                            .padding()
                    }
                }
            }
        }
    }

    func authenticateWithAzureAD() {
        let kClientID = "bcdfc7af-cdef-48f8-b4ec-ab4a664d06dd"
        let kRedirectUri = "msauth.com.449.auth://auth"
        let kAuthority = "https://login.microsoftonline.com/common"

        do {
            // Initialize the MSAL configuration
            let authorityURL = URL(string: kAuthority)!
            let authority = try MSALAuthority(url: authorityURL)
            let config = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: kRedirectUri, authority: authority)
            let application = try MSALPublicClientApplication(configuration: config)

            // Get the current window scene
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("Failed to get the window scene.")
                return
            }

            let webViewParameters = MSALWebviewParameters(authPresentationViewController: window.rootViewController!)
            let parameters = MSALInteractiveTokenParameters(scopes: ["User.Read"], webviewParameters: webViewParameters)

            // Acquire token
            application.acquireToken(with: parameters) { (result, error) in
                if let error = error {
                    print("Authentication failed: \(error.localizedDescription)")
                    return
                }

                guard let result = result else {
                    print("No result returned after token acquisition.")
                    return
                }

                print("Authentication successful. Token: \(result.accessToken)")

                fetchUserProfile(token: result.accessToken)
            }
        } catch let error as NSError {
            print("Error creating MSAL configuration: \(error.localizedDescription)")
        }
    }

    func fetchUserProfile(token: String) {
        let graphEndpoint = "https://graph.microsoft.com/v1.0/me"
        var request = URLRequest(url: URL(string: graphEndpoint)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch user profile: \(error?.localizedDescription ?? "No error description")")
                return
            }

            do {
                if let user = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    DispatchQueue.main.async {
                        self.userName = user["displayName"] as? String ?? "Unknown"
                        self.userEmail = user["mail"] as? String ?? "Unknown"
                        self.isAuthenticated = true // Navigate to AllItemsView
                        print("User profile fetched. Name: \(self.userName), Email: \(self.userEmail)")
                    }
                }
            } catch {
                print("Failed to parse user profile: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
