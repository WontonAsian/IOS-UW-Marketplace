import SwiftUI
import RealmSwift

class Item: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var title: String = ""
    @Persisted var price: Double = 0.0
    @Persisted var itemDescription: String = ""
    @Persisted var category: String = ""
    @Persisted var datePosted: Date = Date()
    @Persisted var isSold: Bool = false
    @Persisted var sellerID: String = ""
    @Persisted var buyerID: String?
}

struct SellView: View {
    @State private var itemName: String = ""
    @State private var itemPrice: String = ""
    @State private var itemDescription: String = ""
    @State private var selectedCategory: String = "Clothing"
    let categories = ["Clothing", "Electronics", "Kitchen", "Home Goods", "Misc"]
    var userEmail: String

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Create New Listing").font(.headline)) {
                        TextField("Item", text: $itemName)
                        TextField("Price", text: $itemPrice)
                            .keyboardType(.decimalPad)
                        TextField("Description", text: $itemDescription)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    .padding()
                    
                    Button(action: submitListing) {
                        Text("Submit")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .frame(width: UIScreen.main.bounds.width - 40)
                Spacer()
            }
            .navigationBarTitle("Sell Items", displayMode: .inline)
        }
    }

    func submitListing() {
        let app = App(id: "info449-yvztpct") // Realm App ID
        app.login(credentials: .anonymous) { result in
            switch result {
            case .success(let user):
                print("Logged in as user \(user)")

                var configuration = user.flexibleSyncConfiguration()
                configuration.objectTypes = [Item.self]

                // Open the Realm asynchronously
                Realm.asyncOpen(configuration: configuration) { result in
                    switch result {
                    case .success(let realm):
                        let subscriptions = realm.subscriptions
                        subscriptions.update {
                            if let existingSubscription = subscriptions.first(named: "all_items") {
                                existingSubscription.updateQuery(toType: Item.self, where: { item in item.price > 0 })
                            } else {
                                subscriptions.append(QuerySubscription<Item>(name: "all_items"))
                            }
                        }

                        // Create and add a new item
                        let newItem = Item()
                        newItem.title = self.itemName
                        newItem.price = Double(self.itemPrice) ?? 0.0
                        newItem.itemDescription = self.itemDescription
                        newItem.category = self.selectedCategory
                        newItem.datePosted = Date() // Set the current date and time
                        newItem.isSold = false // Default to not sold
                        newItem.sellerID = self.userEmail // Set sellerID to the user's email
                        newItem.buyerID = nil // Initially, buyerID is nil

                        try! realm.write {
                            realm.add(newItem)
                        }
                        
                        // Clear input fields
                        self.itemName = ""
                        self.itemPrice = ""
                        self.itemDescription = ""
                        self.selectedCategory = "Clothing"

                        print("Item added successfully.")
                    case .failure(let error):
                        print("Failed to open realm: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("Failed to log in: \(error.localizedDescription)")
            }
        }
    }
}

struct SellView_Previews: PreviewProvider {
    static var previews: some View {
        SellView(userEmail: "mwu1@uw.edu")
    }
}
