import SwiftUI
import MSAL

struct UserProfileView: View {
    @State var userName: String
    @State var userEmail: String
    @Binding var isAuthenticated: Bool
    @State private var application: MSALPublicClientApplication?
    @State private var listedItems: [ListedItem] = []
    @State private var boughtItems: [ListedItem] = []
    @State private var showListedItems: Bool = true
    @State private var showBoughtItems: Bool = true

    var body: some View {
        NavigationView {
            
            Form {
                Section(header: Text("Profile Details")) {
                    Text("User Name: \(userName)")
                    Text("Email: \(userEmail)")
                }

                DisclosureGroup("Listed Items", isExpanded: $showListedItems) {
                    if listedItems.isEmpty {
                        Text("No items listed.")
                    } else {
                        ForEach(listedItems.filter { !$0.isSold }) { item in
                            NavigationLink(destination: EditItemView(item: item, userEmail: userEmail, onItemUpdated: { updatedItem in
                                updateItem(updatedItem)
                            }, onItemDeleted: { deletedItem in
                                deleteItem(deletedItem)
                            })) {
                                ListedItemRow(item: item, showSold: true)
                            }
                        }
                    }
                }

                DisclosureGroup("Bought Items", isExpanded: $showBoughtItems) {
                    if boughtItems.isEmpty {
                        Text("No items bought.")
                    } else {
                        ForEach(boughtItems) { item in
                            BoughtItemRow(item: item)
                        }
                    }
                }
                
                Button("Log Out") {
                    signOut()
                }
                .foregroundColor(.red)
            }
            .navigationBarTitle("User Profile", displayMode: .inline)
            .onAppear {
                loadUserItems()
                loadBoughtItems()
            }
        }
    }

    private func loadUserItems() {
        fetchListedItems(for: userEmail) { items in
            self.listedItems = items
        }
    }

    private func loadBoughtItems() {
        fetchBoughtItems(for: userEmail) { items in
            self.boughtItems = items
        }
    }

    private func fetchListedItems(for userEmail: String, completion: @escaping ([ListedItem]) -> Void) {
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/find"
        let filter = ["sellerID": ["$eq": userEmail]]

        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")

        let requestBody: [String: Any] = [
            "collection": "Item",
            "database": "SellingItems",
            "dataSource": "Cluster0",
            "filter": filter
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("HTTP Request Failed: \(error)")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status: \(httpResponse.statusCode)")
            }

            do {
                let response = try JSONDecoder().decode(MongoResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.documents)
                }
            } catch {
                print("Failed to decode response: \(error)")
            }
        }.resume()
    }

    private func fetchBoughtItems(for userEmail: String, completion: @escaping ([ListedItem]) -> Void) {
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/find"
        let filter = ["buyerID": ["$eq": userEmail]]

        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")

        let requestBody: [String: Any] = [
            "collection": "Item",
            "database": "SellingItems",
            "dataSource": "Cluster0",
            "filter": filter
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("HTTP Request Failed: \(error)")
                return
            }

            guard let data = data else {
                print("No data returned")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status: \(httpResponse.statusCode)")
            }

            do {
                let response = try JSONDecoder().decode(MongoResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(response.documents)
                }
            } catch {
                print("Failed to decode response: \(error)")
            }
        }.resume()
    }

    private func signOut() {
        // Clear authentication state and user info from UserDefaults
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")

        // Remove the current account from MSAL cache
        clearAuthenticationState()

        // Update isAuthenticated binding to navigate back to LoginView
        isAuthenticated = false
    }

    private func clearAuthenticationState() {
        // Check if the application instance is initialized
        guard let application = self.application else {
            print("MSAL application instance is not initialized.")
            return
        }

        do {
            // Retrieve the current account
            guard let currentAccount = try application.allAccounts().first else {
                print("No current account found.")
                return
            }

            // Remove the current account
            do {
                try application.remove(currentAccount)
            } catch let error {
                print("Failed to remove account: \(error.localizedDescription)")
            }
        } catch {
            print("Error retrieving accounts: \(error.localizedDescription)")
        }
    }

    private func updateItem(_ updatedItem: ListedItem) {
        if let index = listedItems.firstIndex(where: { $0.id == updatedItem.id }) {
            listedItems[index] = updatedItem
        }
    }

    private func deleteItem(_ deletedItem: ListedItem) {
        listedItems.removeAll { $0.id == deletedItem.id }
    }
}

private func formatPrice(_ price: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
}

private func formatDate(_ dateString: String) -> String {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
    if let date = inputFormatter.date(from: dateString) {
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .medium
        outputFormatter.timeStyle = .none
        return outputFormatter.string(from: date)
    }
    return dateString
}

struct ListedItemRow: View {
    let item: ListedItem
    var showSold: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
            Text(item.itemDescription)
                .font(.subheadline)
            Text("Category: \(item.category)")
                .font(.subheadline)
            Text("Price: \(formatPrice(item.price))")
                .font(.subheadline)
            Text("Date Posted: \(formatDate(item.datePosted))")
                .font(.subheadline)
            if showSold {
                Text("Sold: \(item.isSold ? "Yes" : "No")")
                    .font(.subheadline)
            }
        }
        .padding()
    }
}

struct BoughtItemRow: View {
    let item: ListedItem

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
            Text(item.itemDescription)
                .font(.subheadline)
            Text("Category: \(item.category)")
                .font(.subheadline)
            Text("Price: \(formatPrice(item.price))")
                .font(.subheadline)
            Text("Date Posted: \(formatDate(item.datePosted))")
                .font(.subheadline)
            Text("Seller: \(item.sellerID)")
                .font(.subheadline)
        }
        .padding()
    }
}

struct EditItemView: View {
    @State var item: ListedItem
    let userEmail: String
    let onItemUpdated: (ListedItem) -> Void
    let onItemDeleted: (ListedItem) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Edit Item")) {
                TextField("Title", text: $item.title)
                TextField("Description", text: $item.itemDescription)
                TextField("Category", text: $item.category)
                TextField("Price", value: $item.price, formatter: NumberFormatter())
            }
            Button("Save") {
                updateItem()
            }
            Button("Mark as Sold") {
                item.isSold = true
                updateItem()
            }
            Button("Delete") {
                deleteItem()
            }
            .foregroundColor(.red)
        }
        .navigationBarTitle("Edit Item", displayMode: .inline)
    }

    private func updateItem() {
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/updateOne"

        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")

        let requestBody: [String: Any] = [
            "collection": "Item",
            "database": "SellingItems",
            "dataSource": "Cluster0",
            "filter": ["_id": ["$oid": item.id]],
            "update": ["$set": ["title": item.title, "itemDescription": item.itemDescription, "category": item.category, "price": item.price, "isSold": item.isSold]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("HTTP Request Failed: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status: \(httpResponse.statusCode)")
            }

            if let responseString = String(data: data!, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }

            DispatchQueue.main.async {
                onItemUpdated(item)
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }

    private func deleteItem() {
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/deleteOne"

        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")

        let requestBody: [String: Any] = [
            "collection": "Item",
            "database": "SellingItems",
            "dataSource": "Cluster0",
            "filter": ["_id": ["$oid": item.id]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("HTTP Request Failed: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Response Status: \(httpResponse.statusCode)")
            }

            if let responseString = String(data: data!, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }

            DispatchQueue.main.async {
                onItemDeleted(item)
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}

struct UserProfileView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        UserProfileView(userName: "michelle", userEmail: "mwu1@uw.edu", isAuthenticated: $isAuthenticated)
    }
}
