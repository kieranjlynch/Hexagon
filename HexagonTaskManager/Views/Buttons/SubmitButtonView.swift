import SwiftUI

struct SubmitButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(10)
            .foregroundColor(.offWhite)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.darkGray))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.offWhite, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SubmitButton: View {
    var submitAction: () -> Void
    
    var body: some View {
        Button("Submit", action: submitAction)
            .buttonStyle(SubmitButtonStyle())
    }
}
