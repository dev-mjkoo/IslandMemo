//
//  ToastView.swift
//  IslandMemo
//

import SwiftUI

struct ToastView: View {
    let message: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let toastBackground: Color = {
            if colorScheme == .dark {
                return Color.white.opacity(0.12)
            } else {
                return Color.black.opacity(0.75)
            }
        }()

        let toastForeground: Color = {
            if colorScheme == .dark {
                return Color.white
            } else {
                return Color.white
            }
        }()

        return Text(message)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(toastForeground)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(toastBackground)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
    }
}
