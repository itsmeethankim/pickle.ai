import SwiftUI

struct ShotTypePickerView: View {
    @Binding var selectedShotType: ShotType
    var onSelect: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(ShotType.allCases, id: \.self) { shotType in
                Button {
                    selectedShotType = shotType
                    onSelect()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: shotType.iconName)
                            .font(.system(size: 28))
                        Text(shotType.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        selectedShotType == shotType
                            ? Color.accentColor.opacity(0.2)
                            : Color(.systemGray6)
                    )
                    .foregroundColor(
                        selectedShotType == shotType ? .accentColor : .primary
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedShotType == shotType ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
                }
            }
        }
    }
}
