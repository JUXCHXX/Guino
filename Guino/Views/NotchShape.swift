import SwiftUI

struct NotchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: rect,
            cornerRadii: RectangleCornerRadii(topLeading: 0, bottomLeading: 14, bottomTrailing: 14, topTrailing: 0)
        )
        return path
    }
}
