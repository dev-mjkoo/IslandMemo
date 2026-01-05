import SwiftUI

struct LinkActionCard: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isShowingLinksSheet: Bool
    let savedLinksCount: Int
    let onPasteLink: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header - tappable to view links
            Button {
                HapticManager.light()
                isShowingLinksSheet = true
            } label: {
                HStack(spacing: 6) {
                    Text(LocalizationManager.shared.string("링크"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.primary.opacity(0.7))

                    Spacer()

                    HStack(spacing: 4) {
                        if savedLinksCount > 0 {
                            Text("\(savedLinksCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.blue)
                                )
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
            .buttonStyle(.plain)

            // Rest of the card - tappable to paste link
            VStack(spacing: 0) {
                // Button below header, left aligned
                HStack {
                    Text(LocalizationManager.shared.string("저장하기"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)

                Spacer()

                // Emoji at bottom right
                HStack {
                    Spacer()
                    Text("🔗")
                        .font(.system(size: 32))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.light()
                onPasteLink()
            }
        }
        .frame(height: 160)
        .background(AppColors.Card.background(for: colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(AppColors.Card.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppColors.Card.shadow(for: colorScheme), radius: 12, y: 8)
    }
}
