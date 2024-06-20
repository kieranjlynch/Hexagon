import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Binding var mapRegion: MKCoordinateRegion
    @Binding var searchResults: [SearchResult]
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchQuery = ""
    @State private var matchingItems: [MKMapItem] = []
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search for a place", text: $searchQuery, onEditingChanged: { _ in
                    search()
                })
                .padding()
                .background(Color(UIColor.systemGray5))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.top, 10)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            
            List(matchingItems, id: \.self) { item in
                Button(action: {
                    selectLocation(item: item)
                }) {
                    VStack(alignment: .leading) {
                        Text(item.name ?? "")
                            .font(.headline)
                            .foregroundColor(.offWhite)
                        Text(item.placemark.title ?? "")
                            .font(.subheadline)
                            .foregroundColor(.offWhite)
                    }
                }
                .listRowBackground(Color.darkGray)
            }
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
            .listStyle(PlainListStyle())
            .background(Color.darkGray)
        }
        .background(Color.darkGray)
        .navigationBarTitle("Location Search", displayMode: .inline)
    }
    
    private func search() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = mapRegion
        
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            matchingItems = response.mapItems
            searchResults = matchingItems.map { SearchResult(location: $0.placemark.coordinate) }
        }
    }
    
    private func selectLocation(item: MKMapItem) {
        mapRegion.center = item.placemark.coordinate
        presentationMode.wrappedValue.dismiss()
    }
}
