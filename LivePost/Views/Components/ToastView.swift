

import SwiftUI

struct ToastView: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(AppColors.Toast.background(for: colorScheme))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
    }
}
