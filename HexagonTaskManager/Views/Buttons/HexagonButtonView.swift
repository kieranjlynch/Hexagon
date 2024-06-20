import SwiftUI

struct HexagonButtonView: View {
    let symbol: String
    let action: () -> Void
    private let sides = 6
    private let angle = 2 * .pi / CGFloat(6)
    
    private func pointFrom(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        let x = center.x + radius * cos(angle)
        let y = center.y + radius * sin(angle)
        return CGPoint(x: x, y: y)
    }
    
    private func hexagonPath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let adjustment = CGFloat.pi / 6
        let startPoint = self.pointFrom(center: center, radius: radius, angle: -CGFloat.pi / 2 + adjustment)
        path.move(to: startPoint)
        
        for i in 1..<sides {
            let currentAngle = angle * CGFloat(i) - CGFloat.pi / 2 + adjustment
            let point = self.pointFrom(center: center, radius: radius, angle: currentAngle)
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                ZStack {
                    self.hexagonPath(in: geometry.frame(in: .local))
                        .stroke(Color.orange, lineWidth: 2)
                    Image(systemName: symbol)
                }
            }
        }
    }
}
