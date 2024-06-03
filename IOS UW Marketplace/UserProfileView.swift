import SwiftUI

struct UserProfileView: View {
    var userName: String
    var userEmail: String
    @Binding var isAuthenticated: Bool
    @State private var listedItems: [ListedItem] = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Details")) {
                    Text("User Name: \(userName)")
                    Text("Email: \(userEmail)")
                }

                Section(header: Text("Listed Items")) {
                    if listedItems.isEmpty {
                        Text("No items listed.")
                    } else {
                        ForEach(listedItems) { item in
                            ListedItemRow(item: item)
                        }
                    }
                }

                Button("Log Out") {
                    isAuthenticated = false
                }
                .foregroundColor(.red)
            }
            .navigationBarTitle("User Profile", displayMode: .inline)
            .onAppear {
                loadUserItems()
            }
        }
    }

    private func loadUserItems() {
        fetchListedItems(for: userEmail) { items in
            self.listedItems = items
            print(listedItems)
        }
    }

    private func fetchListedItems(for userEmail: String, completion: @escaping ([ListedItem]) -> Void) {
        let apiKey = "evWnPMfG5GwnCghHBR3zb5kTsDMwnmfU2JTvE8fywXL87nV5y0vaYgxn8D793NLe"
        let baseURL = "https://us-west-2.aws.data.mongodb-api.com/app/data-xogcpqd/endpoint/data/v1/action/find"
        let filter = ["sellerID": ["$eq": userEmail]]
        print(filter) //delete this later

        guard let url = URL(string: baseURL) else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(apiKey, forHTTPHeaderField: "api-key")
        print(request)
        
        let requestBody: [String: Any] = [
            "collection": "Item",
            "database": "SellingItems",
            "dataSource": "Cluster0",
            "filter": filter
        ]
        print(requestBody)
        
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
}

struct ListedItemRow: View {
    let item: ListedItem

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
        }
        .padding()
    }
}

struct UserProfileView_Previews: PreviewProvider {
    @State static var isAuthenticated = true
    static var previews: some View {
        UserProfileView(userName: "michelle", userEmail: "mwu1@uw.edu", isAuthenticated: $isAuthenticated)
    }
}

struct MongoResponse: Decodable {
    let documents: [ListedItem]
}

struct ListedItem: Identifiable, Decodable {
    let id: String
    let buyerID: String?
    let category: String
    let datePosted: Date
    let isSold: Bool
    let itemDescription: String
    let price: Int
    let sellerID: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case buyerID = "buyerID"
        case category = "category"
        case datePosted = "datePosted"
        case isSold = "isSold"
        case itemDescription = "itemDescription"
        case price = "price"
        case sellerID = "sellerID"
        case title = "title"
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter
    }()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        buyerID = try container.decodeIfPresent(String.self, forKey: .buyerID)
        category = try container.decode(String.self, forKey: .category)
        let dateString = try container.decode(String.self, forKey: .datePosted)
        datePosted = ListedItem.dateFormatter.date(from: dateString) ?? Date()
        isSold = try container.decode(Bool.self, forKey: .isSold)
        itemDescription = try container.decode(String.self, forKey: .itemDescription)
        price = try container.decode(Int.self, forKey: .price)
        sellerID = try container.decode(String.self, forKey: .sellerID)
        title = try container.decode(String.self, forKey: .title)
    }
}
