import SwiftUI
import MSAL

struct ViewControllerHolder: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .init("viewControllerAvailable"), object: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct LoginView: View {
    @State private var isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var userEmail: String = UserDefaults.standard.string(forKey: "userEmail") ?? ""
    @State private var application: MSALPublicClientApplication?
    @State private var webViewParameters: MSALWebviewParameters?

    @State private var viewController: UIViewController?

    var body: some View {
        NavigationStack {
            VStack {
                if isAuthenticated {
                    MainView(userName: userName, userEmail: userEmail, isAuthenticated: $isAuthenticated)
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
            .background(ViewControllerHolder().frame(width: 0, height: 0))
            .onAppear {
                initializeMSAL()
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("viewControllerAvailable")), perform: { notification in
                if let vc = notification.object as? UIViewController {
                    self.viewController = vc
                    self.webViewParameters = MSALWebviewParameters(authPresentationViewController: vc)
                }
            })
        }
    }

    private func initializeMSAL() {
        let kClientID = "bcdfc7af-cdef-48f8-b4ec-ab4a664d06dd"
        let kRedirectUri = "msauth.com.449.auth://auth"
        let kAuthority = "https://login.microsoftonline.com/common"
        
        do {
            let authorityURL = URL(string: kAuthority)!
            let authority = try MSALAuthority(url: authorityURL)
            let config = MSALPublicClientApplicationConfig(clientId: kClientID, redirectUri: kRedirectUri, authority: authority)
            self.application = try MSALPublicClientApplication(configuration: config)
            print("MSAL configuration successful.")
        } catch let error as NSError {
            print("Error creating MSAL configuration: \(error.localizedDescription)")
        }
    }

    private func authenticateWithAzureAD() {
        guard let application = self.application, let webViewParameters = self.webViewParameters else {
            print("MSAL application or webViewParameters is not initialized.")
            return
        }
        
        let parameters = MSALInteractiveTokenParameters(scopes: ["User.Read"], webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        
        application.acquireToken(with: parameters) { (result, error) in
            if let error = error as NSError? {
                print("Authentication failed: \(error.localizedDescription)")
                if let errorDescription = error.userInfo[MSALErrorDescriptionKey] as? String {
                    print("Error description: \(errorDescription)")
                }
                return
            }
            
            guard let result = result else {
                print("No result returned after token acquisition.")
                return
            }
            
            print("Authentication successful. Token: \(result.accessToken)")
            self.fetchUserProfile(token: result.accessToken)
        }
    }

    private func fetchUserProfile(token: String) {
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
                        self.isAuthenticated = true
                        
                        UserDefaults.standard.set(true, forKey: "isAuthenticated")
                        UserDefaults.standard.set(self.userName, forKey: "userName")
                        UserDefaults.standard.set(self.userEmail, forKey: "userEmail")
                        
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
