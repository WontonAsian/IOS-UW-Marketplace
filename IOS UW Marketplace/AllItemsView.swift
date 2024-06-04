import SwiftUI

struct AllItemsView: View {
    var userName: String
    var userEmail: String
    @Binding var isAuthenticated: Bool
    @State private var allItems: [ListedItem] = []
    @State private var searchQuery = ""
    @State private var selectedCategory = "All"
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 1000
    @State private var showMoreFilters = false
    private var categories = ["All", "Home Goods", "Electronics", "Clothing", "Misc"]

    init(userName: String, userEmail: String, isAuthenticated: Binding<Bool>) {
        self.userName = userName
        self.userEmail = userEmail
        self._isAuthenticated = isAuthenticated
    }

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search", text: $searchQuery)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal, 10)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                
                DisclosureGroup("More filters", isExpanded: $showMoreFilters) {
                    VStack {
                        HStack {
                            Text("Min Price: \(Int(minPrice))")
                            Slider(value: $minPrice, in: 0...maxPrice, step: 5)
                                .padding(.horizontal)
                        }

                        HStack {
                            Text("Max Price: \(Int(maxPrice))")
                            Slider(value: $maxPrice, in: minPrice...1000, step: 5)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding()
                
                List(filteredItems) { item in
                    AllItemRow(item: item, userEmail: userEmail, onItemBought: { boughtItem in
                        removeItem(boughtItem)
                    }, showSellerLink: true)
                    .listRowInsets(EdgeInsets())
                }
                .refreshable {
                    loadAllItems()
                }
                .navigationBarTitle("All Items", displayMode: .inline)
                .onAppear {
                    loadAllItems()
                }
            }
        }
    }

    private var filteredItems: [ListedItem] {
        var items = allItems

        if selectedCategory != "All" {
            items = items.filter { $0.category == selectedCategory }
        }

        if !searchQuery.isEmpty {
            items = items.filter { $0.title.lowercased().contains(searchQuery.lowercased()) }
        }
        
        items = items.filter { $0.price >= minPrice && $0.price <= maxPrice }

        return items
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

    private func removeItem(_ item: ListedItem) {
        allItems.removeAll { $0.id == item.id }
    }
}

struct AllItemRow: View {
    let item: ListedItem
    let userEmail: String
    let onItemBought: (ListedItem) -> Void
    let showSellerLink: Bool
    @State private var showAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            if showSellerLink {
                NavigationLink(destination: SellerProfileView(sellerID: item.sellerID, userEmail: userEmail)) {
                    Text("Seller: \(item.sellerID)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                Text("Seller: \(item.sellerID)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray, lineWidth: 1)
        )
        .shadow(radius: 5)

        BuyButton(item: item, userEmail: userEmail, showAlert: $showAlert, onItemBought: onItemBought).disabled(false)
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
}

struct BuyButton: View {
    let item: ListedItem
    let userEmail: String
    @Binding var showAlert: Bool
    let onItemBought: (ListedItem) -> Void

    var body: some View {
        Button(action: {
            if item.sellerID == userEmail {
                showAlert = true
            } else {
                buyItem(item)
            }
        }) {
            HStack {
                Spacer()
                Text("Buy")
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.blue)
            .cornerRadius(5)
            .contentShape(Rectangle())
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Cannot Buy Item"), message: Text("You cannot buy your own item."), dismissButton: .default(Text("OK")))
        }
    }

    private func buyItem(_ item: ListedItem) {
        print("Buying item with ID: \(item.id) by user: \(userEmail)")
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

struct ListedItem: Identifiable, Codable {
    var id: String { _id }
    var _id: String
    var title: String
    var price: Double
    var itemDescription: String
    var category: String
    var datePosted: String
    var isSold: Bool
    var sellerID: String
    var buyerID: String?

    private enum CodingKeys: String, CodingKey {
        case _id, title, price, itemDescription, category, datePosted, isSold, sellerID, buyerID
    }
}

struct MongoResponse: Codable {
    let documents: [ListedItem]
}
