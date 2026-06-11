import SwiftUI

struct StructuredView: View {
    var model: PortalStructuredViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                if let subtitle = model.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(PortalTheme.secondaryText)
                }

                ForEach(model.blocks) { block in
                    blockView(block)
                }
            }
            .padding(16)
        }
        .background(PortalTheme.background)
    }

    @ViewBuilder
    private func blockView(_ block: PortalStructuredBlock) -> some View {
        switch block.type {
        case "header":
            VStack(alignment: .leading, spacing: 6) {
                Text(block.title ?? model.title ?? "Workspace")
                    .font(.title2.weight(.bold))
                if let subtitle = block.subtitle {
                    Text(subtitle)
                        .foregroundStyle(PortalTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case "items":
            PortalTheme.card {
                VStack(alignment: .leading, spacing: 10) {
                    if let title = block.title {
                        Text(title).font(.headline)
                    }
                    ForEach(block.items ?? []) { item in
                        HStack {
                            Text(item.label)
                                .foregroundStyle(PortalTheme.secondaryText)
                            Spacer()
                            Text(item.value.description)
                                .fontWeight(.medium)
                        }
                    }
                }
            }

        case "table":
            PortalTheme.card {
                VStack(alignment: .leading, spacing: 12) {
                    if let title = block.title {
                        Text(title).font(.headline)
                    }
                    ForEach(block.rows ?? []) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array((block.columns ?? []).enumerated()), id: \.element.id) { index, column in
                                let cell = row.cells.indices.contains(index) ? row.cells[index] : nil
                                HStack(alignment: .top) {
                                    Text(column.label)
                                        .font(.caption)
                                        .foregroundStyle(PortalTheme.secondaryText)
                                    Spacer()
                                    Text(cellText(cell))
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        Divider()
                    }
                }
            }

        case "markdown":
            PortalTheme.card {
                VStack(alignment: .leading, spacing: 8) {
                    if let title = block.title {
                        Text(title).font(.headline)
                    }
                    Text((try? AttributedString(markdown: block.content ?? "")) ?? AttributedString(block.content ?? ""))
                        .textSelection(.enabled)
                }
            }

        default:
            PortalTheme.card {
                VStack(alignment: .leading, spacing: 8) {
                    Text(block.title ?? block.type.capitalized)
                        .font(.headline)
                    if let description = block.description {
                        Text(description)
                            .foregroundStyle(PortalTheme.secondaryText)
                    }
                }
            }
        }
    }

    private func cellText(_ cell: PortalStructuredCell?) -> String {
        cell?.text
            ?? cell?.primary
            ?? cell?.value?.description
            ?? ""
    }
}

