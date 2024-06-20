import SwiftUI

struct FilterStatsView: View {
    
    let icon: String
    let title: String
    var count: Int?
    var iconColor: Color = .orange
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title)
                    Text(title)
                        .opacity(0.8)
                        .foregroundColor(.offWhite)
                }
                Spacer()
                if let count {
                    Text("\(count)")
                        .font(.largeTitle)
                        .foregroundColor(.offWhite)
                }
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16.0, style: .continuous))
        }
    }
}
