import SwiftUI

struct SelectListView: View {
    
    @FetchRequest(sortDescriptors: [])
    private var myListsFetchResults: FetchedResults<TaskList>
    @Binding var selectedList: TaskList?
    
    var body: some View {
        List(myListsFetchResults) { myList in
            HStack {
                HStack {
                    Image(systemName: "line.3.horizontal.circle.fill")
                        .foregroundColor(Color(myList.color!))
                    Text(myList.name!)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    self.selectedList = myList
                }
                
                Spacer()
                
                if selectedList == myList {
                    Image(systemName: "checkmark")
                }
            }
        }
        .background(Color.darkGray.ignoresSafeArea())
    }
}
