import SpacerCore
import SwiftUI

struct SettingsView: View {
    let model: SettingsModel

    /// More rows than this scroll, so the window never grows past the screen.
    private let rowsBeforeScrolling = 8

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("settings.gaps")).font(.headline)

            if model.rows.isEmpty {
                Text(L("settings.gaps.empty")).foregroundStyle(.secondary)
            } else if model.rows.count > rowsBeforeScrolling {
                ScrollView { rows.padding(.trailing, 12) }.frame(height: 300)
            } else {
                rows
            }

            Button(L("settings.add"), systemImage: "plus") { model.add() }

            Text(L("settings.hint"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Toggle(L("settings.openAtLogin"), isOn: Binding(
                get: { model.openAtLogin },
                set: { model.setOpenAtLogin($0) }))
            if model.loginItemFailed {
                Text(L("settings.openAtLogin.failed"))
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            HStack {
                Text(L("settings.version", version)).foregroundStyle(.secondary)
                Spacer()
                Button(L("menu.quit")) { NSApplication.shared.terminate(nil) }
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                GapRow(number: index + 1, row: row, model: model)
            }
        }
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}

/// One gap: its number from the left, the width slider, the width and a remove button.
private struct GapRow: View {
    let number: Int
    let row: SettingsModel.Row
    let model: SettingsModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Text(String(number))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 22, alignment: .trailing)
                Slider(
                    value: Binding(
                        get: { WidthScale.fraction(for: row.width) },
                        set: { model.setWidth(WidthScale.width(at: $0), for: row.id) }),
                    onEditingChanged: { model.setHighlighted(row.id, $0) })
                    .accessibilityLabel(L("settings.gap.width", number))
                Text(String(row.width))
                    .monospacedDigit()
                    .frame(width: 34, alignment: .trailing)
                Button {
                    model.remove(row.id)
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .help(L("settings.gap.remove"))
                .accessibilityLabel(L("settings.gap.remove.label", number))
            }
            if row.isHidden {
                Text(L("settings.gap.hidden"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)
            }
        }
        .onHover { model.setHighlighted(row.id, $0) }
    }
}
