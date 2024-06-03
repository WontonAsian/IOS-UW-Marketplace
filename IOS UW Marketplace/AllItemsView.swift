import SwiftUI

struct AllItemsView: View {
    var userName: String
    var userEmail: String
    @Binding var isAuthenticated: Bool
    @State private var allItems: [ListedItem] = []

    var body: some View {
        NavigationView {
            List(allItems) { item in
                AllItemRow(item: item, userEmail: userEmail, onItemBought: { boughtItem in
                    removeItem(boughtItem)
                })
            }
            .navigationBarTitle("All Items", displayMode: .inline)
            .onAppear {
                loadAllItems()
            }
        }
    }

    private func loadAllItems() {
        fetchAllItems { items in
            self.allItems = items
        }
    }

    private func fetchAllItems(completion: @escaping ([ListedItem]) -> Void) {
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/find"

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
            "filter": ["isSold": ["$eq": false]]
        ]

        print("Request Body: \(requestBody)")
        
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

            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Data: \(responseString)")
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

    private func removeItem(_ item: ListedItem) {
        allItems.removeAll { $0.id == item.id }
    }
}

struct AllItemRow: View {
    let item: ListedItem
    let userEmail: String
    let onItemBought: (ListedItem) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
            Text(item.itemDescription)
                .font(.subheadline)
            Text("Category: \(item.category)")
                .font(.subheadline)
            Text("Price: $\(item.price)")
                .font(.subheadline)
            Text("Date Posted: \(item.datePosted)")
                .font(.subheadline)
            Text("Sold: \(item.isSold ? "Yes" : "No")")
                .font(.subheadline)
            Button(action: {
                buyItem(item)
            }) {
                Text("Buy")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(5)
            }
        }
        .padding()
    }

    private func buyItem(_ item: ListedItem) {
        print("Buying item with ID: \(item.id) by user: \(userEmail)")
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/find"

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
            "filter": ["_id": item.id],
            "update": ["$set": ["isSold": true, "buyerID": userEmail]]
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
                onItemBought(item)
            }
        }.resume()
    }
}

struct AllItemsView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        AllItemsView(userName: "michelle", userEmail: "mwu1@uw.edu", isAuthenticated: $isAuthenticated)
    }
}
