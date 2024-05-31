import SwiftUI

struct AllItemsView: View {
    // Sample data array
    let items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        NavigationView {
            List(items, id: \.self) { item in
                Text(item)
            }
            .navigationBarTitle("All Items")
        }
    }
}

struct AllItemsView_Previews: PreviewProvider {
    static var previews: some View {
        AllItemsView()
    }
}
