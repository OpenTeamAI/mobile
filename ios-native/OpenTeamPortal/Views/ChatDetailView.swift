import SwiftUI

struct ChatDetailView: View {
    @ObservedObject var model: ChatViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var showsStructuredView = false

    var body: some View {
        VStack(spacing: 0) {
            chatHeader

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(model.detail?.messages ?? []) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }

                        if let status = model.streamStatus {
                            HStack(spacing: 8) {
                                if model.isStreaming {
                                    ProgressView()
                                }
                                Text(status)
                                    .font(.caption)
                                    .foregroundStyle(PortalTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .background(PortalTheme.background)
                .onChange(of: model.detail?.messages.last?.content ?? "") { _ in
                    if let last = model.detail?.messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if let error = model.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 6)
            }

            ComposerView(model: model)
        }
        .navigationBarHidden(true)
        .accessibilityIdentifier("chat-detail")
        .overlay {
            if model.isLoading && model.detail == nil {
                ProgressView("Loading chat")
            }
        }
        .sheet(isPresented: $showsStructuredView) {
            NavigationView {
                if let viewModel = model.structuredView {
                    StructuredView(model: viewModel)
                        .navigationTitle(viewModel.title ?? "Workspace")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private var chatHeader: some View {
        HStack(spacing: 10) {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.headline)
                    .frame(width: 38, height: 38)
                    .background(PortalTheme.surface.opacity(0.78))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PortalTheme.border.opacity(0.7), lineWidth: 1))
            }
            .accessibilityLabel("Open chat list")

            Text(model.detail?.title ?? model.summary.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PortalTheme.primaryText)
                .lineLimit(1)

            Spacer()

            SmallHeaderButton(systemName: "sun.max") {}
            SmallHeaderButton(systemName: "gearshape") {}

            if model.structuredView != nil {
                SmallHeaderButton(systemName: "rectangle.split.3x1") {
                    showsStructuredView = true
                }
            }

            if model.isStreaming {
                SmallHeaderButton(systemName: "stop.circle") {
                    Task { await model.stop() }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(PortalTheme.background)
    }
}

private struct SmallHeaderButton: View {
    var systemName: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PortalTheme.primaryText)
                .frame(width: 38, height: 38)
                .background(PortalTheme.surface.opacity(0.78))
                .clipShape(Circle())
                .overlay(Circle().stroke(PortalTheme.border.opacity(0.7), lineWidth: 1))
        }
    }
}

private struct MessageBubble: View {
    var message: PortalMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer(minLength: 36)
            }

            VStack(alignment: .leading, spacing: 10) {
                if let activities = message.activities, !activities.isEmpty {
                    ForEach(activities) { activity in
                        ActivityEventView(activity: activity)
                    }
                }

                if !message.content.isEmpty {
                    PortalMarkdownView(message.content, isUserMessage: message.isUser)
                } else if message.state == "in_progress" {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Working")
                            .font(.subheadline)
                            .foregroundStyle(PortalTheme.secondaryText)
                    }
                }

                MessageActions(message: message)
            }
            .padding(14)
            .background(message.isUser ? PortalTheme.accent : PortalTheme.surface)
            .foregroundStyle(message.isUser ? Color.white : PortalTheme.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(message.isUser ? Color.clear : PortalTheme.border, lineWidth: 1)
            )
            .frame(maxWidth: 560, alignment: message.isUser ? .trailing : .leading)

            if !message.isUser {
                Spacer(minLength: 36)
            }
        }
    }
}

private struct MessageActions: View {
    var message: PortalMessage

    var body: some View {
        if !message.isUser && message.state != "in_progress" {
            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = message.content
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .accessibilityLabel("Copy")

                Button {} label: {
                    Image(systemName: "hand.thumbsup")
                }
                .accessibilityLabel("Good response")

                Button {} label: {
                    Image(systemName: "hand.thumbsdown")
                }
                .accessibilityLabel("Bad response")
            }
            .font(.caption)
            .foregroundStyle(PortalTheme.secondaryText)
        }
    }
}

private struct ActivityEventView: View {
    var activity: PortalActivityEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(activity.phase.capitalized)
                    .font(.caption2)
                    .foregroundStyle(PortalTheme.secondaryText)
            }

            if let detail = activity.detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(PortalTheme.secondaryText)
            }

            if let command = activity.command, !command.isEmpty {
                Text(command)
                    .font(.caption.monospaced())
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PortalTheme.groupedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }

            if let output = activity.aggregatedOutput, !output.isEmpty {
                Text(output)
                    .font(.caption.monospaced())
                    .lineLimit(5)
                    .foregroundStyle(PortalTheme.secondaryText)
            }
        }
        .padding(10)
        .background(PortalTheme.groupedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var title: String {
        activity.title ?? activity.kind.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var icon: String {
        switch activity.kind {
        case "command_execution":
            return "terminal"
        case "response_text":
            return "text.bubble"
        default:
            return "sparkles"
        }
    }
}

enum PortalMarkdownBlock: Equatable {
    case paragraph(String)
    case heading(level: Int, text: String)
    case unorderedList([String])
    case orderedList([String])
    case quote(String)
    case code(language: String?, text: String)
    case table(headers: [String], rows: [[String]])
}

struct PortalMarkdownParser {
    static func parse(_ markdown: String) -> [PortalMarkdownBlock] {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        var blocks: [PortalMarkdownBlock] = []
        var index = 0

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                index += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                let parsed = parseCodeBlock(lines: lines, start: index)
                blocks.append(parsed.block)
                index = parsed.nextIndex
                continue
            }

            if isTableStart(lines: lines, index: index) {
                let parsed = parseTable(lines: lines, start: index)
                blocks.append(parsed.block)
                index = parsed.nextIndex
                continue
            }

            if let heading = parseHeading(line) {
                blocks.append(.heading(level: heading.level, text: heading.text))
                index += 1
                continue
            }

            if let listItem = parseListItem(line) {
                let parsed = parseList(lines: lines, start: index, ordered: listItem.ordered)
                blocks.append(parsed.ordered ? .orderedList(parsed.items) : .unorderedList(parsed.items))
                index = parsed.nextIndex
                continue
            }

            if trimmed.hasPrefix(">") {
                let parsed = parseQuote(lines: lines, start: index)
                blocks.append(parsed.block)
                index = parsed.nextIndex
                continue
            }

            let parsed = parseParagraph(lines: lines, start: index)
            blocks.append(.paragraph(parsed.text))
            index = parsed.nextIndex
        }

        return blocks
    }

    private static func parseCodeBlock(
        lines: [String],
        start: Int
    ) -> (block: PortalMarkdownBlock, nextIndex: Int) {
        let fence = lines[start].trimmingCharacters(in: .whitespaces)
        let language = String(fence.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        var codeLines: [String] = []
        var index = start + 1

        while index < lines.count {
            if lines[index].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                return (
                    .code(language: language.isEmpty ? nil : language, text: codeLines.joined(separator: "\n")),
                    index + 1
                )
            }
            codeLines.append(lines[index])
            index += 1
        }

        return (
            .code(language: language.isEmpty ? nil : language, text: codeLines.joined(separator: "\n")),
            index
        )
    }

    private static func isTableStart(lines: [String], index: Int) -> Bool {
        guard index + 1 < lines.count else {
            return false
        }
        return splitTableRow(lines[index]).count > 1 && isTableSeparator(lines[index + 1])
    }

    private static func parseTable(
        lines: [String],
        start: Int
    ) -> (block: PortalMarkdownBlock, nextIndex: Int) {
        let headers = splitTableRow(lines[start])
        var rows: [[String]] = []
        var index = start + 2

        while index < lines.count, splitTableRow(lines[index]).count > 1 {
            rows.append(splitTableRow(lines[index]))
            index += 1
        }

        return (.table(headers: headers, rows: rows), index)
    }

    private static func splitTableRow(_ line: String) -> [String] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else {
            return []
        }

        var row = trimmed
        if row.hasPrefix("|") {
            row.removeFirst()
        }
        if row.hasSuffix("|") {
            row.removeLast()
        }

        return row.split(separator: "|", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let cells = splitTableRow(line)
        guard !cells.isEmpty else {
            return false
        }

        return cells.allSatisfy { cell in
            let normalized = cell
                .replacingOccurrences(of: ":", with: "")
                .replacingOccurrences(of: "-", with: "")
                .trimmingCharacters(in: .whitespaces)
            return normalized.isEmpty && cell.contains("-")
        }
    }

    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let hashes = trimmed.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes), trimmed.dropFirst(hashes).first == " " else {
            return nil
        }

        let text = String(trimmed.dropFirst(hashes + 1)).trimmingCharacters(in: .whitespaces)
        return (hashes, text)
    }

    private static func parseList(
        lines: [String],
        start: Int,
        ordered: Bool
    ) -> (ordered: Bool, items: [String], nextIndex: Int) {
        var items: [String] = []
        var index = start

        while index < lines.count, let item = parseListItem(lines[index]), item.ordered == ordered {
            items.append(item.text)
            index += 1
        }

        return (ordered, items, index)
    }

    private static func parseListItem(_ line: String) -> (ordered: Bool, text: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        for marker in ["- ", "* ", "+ "] where trimmed.hasPrefix(marker) {
            return (false, String(trimmed.dropFirst(marker.count)))
        }

        var number = ""
        var index = trimmed.startIndex
        while index < trimmed.endIndex, trimmed[index].isNumber {
            number.append(trimmed[index])
            index = trimmed.index(after: index)
        }

        guard !number.isEmpty,
              index < trimmed.endIndex,
              trimmed[index] == ".",
              trimmed.index(after: index) < trimmed.endIndex,
              trimmed[trimmed.index(after: index)] == " " else {
            return nil
        }

        let textStart = trimmed.index(index, offsetBy: 2)
        return (true, String(trimmed[textStart...]))
    }

    private static func parseQuote(
        lines: [String],
        start: Int
    ) -> (block: PortalMarkdownBlock, nextIndex: Int) {
        var quoteLines: [String] = []
        var index = start

        while index < lines.count {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(">") else {
                break
            }

            var text = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
            if text.hasPrefix(">") {
                text.removeFirst()
            }
            quoteLines.append(text)
            index += 1
        }

        return (.quote(quoteLines.joined(separator: "\n")), index)
    }

    private static func parseParagraph(
        lines: [String],
        start: Int
    ) -> (text: String, nextIndex: Int) {
        var paragraphLines: [String] = []
        var index = start

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || isBlockStart(lines: lines, index: index) {
                break
            }

            paragraphLines.append(line)
            index += 1
        }

        return (paragraphLines.joined(separator: "\n"), index)
    }

    private static func isBlockStart(lines: [String], index: Int) -> Bool {
        let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
        return trimmed.hasPrefix("```")
            || trimmed.hasPrefix(">")
            || parseHeading(lines[index]) != nil
            || parseListItem(lines[index]) != nil
            || isTableStart(lines: lines, index: index)
    }
}

private struct PortalMarkdownView: View {
    var markdown: String
    var isUserMessage: Bool

    init(_ markdown: String, isUserMessage: Bool) {
        self.markdown = markdown
        self.isUserMessage = isUserMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(Array(PortalMarkdownParser.parse(markdown).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(_ block: PortalMarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            MarkdownInlineText(text, isUserMessage: isUserMessage)
        case .heading(let level, let text):
            MarkdownInlineText(
                text,
                font: level <= 2 ? .headline : .subheadline.weight(.semibold),
                isUserMessage: isUserMessage
            )
        case .unorderedList(let items):
            ListBlock(items: items, ordered: false, isUserMessage: isUserMessage)
        case .orderedList(let items):
            ListBlock(items: items, ordered: true, isUserMessage: isUserMessage)
        case .quote(let text):
            QuoteBlock(text: text, isUserMessage: isUserMessage)
        case .code(let language, let text):
            CodeBlock(language: language, text: text, isUserMessage: isUserMessage)
        case .table(let headers, let rows):
            TableBlock(headers: headers, rows: rows, isUserMessage: isUserMessage)
        }
    }
}

private struct MarkdownInlineText: View {
    var markdown: String
    var font: Font
    var isUserMessage: Bool

    init(_ markdown: String, font: Font = .body, isUserMessage: Bool) {
        self.markdown = markdown
        self.font = font
        self.isUserMessage = isUserMessage
    }

    var body: some View {
        Text(attributedString)
            .font(font)
            .foregroundStyle(isUserMessage ? Color.white : PortalTheme.primaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var attributedString: AttributedString {
        (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
    }
}

private struct ListBlock: View {
    var items: [String]
    var ordered: Bool
    var isUserMessage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(ordered ? "\(index + 1)." : "•")
                        .font(.body)
                        .foregroundStyle(isUserMessage ? Color.white : PortalTheme.primaryText)
                        .frame(width: ordered ? 24 : 14, alignment: .trailing)
                    MarkdownInlineText(item, isUserMessage: isUserMessage)
                }
            }
        }
    }
}

private struct QuoteBlock: View {
    var text: String
    var isUserMessage: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(isUserMessage ? Color.white.opacity(0.6) : PortalTheme.border)
                .frame(width: 3)
            MarkdownInlineText(text, isUserMessage: isUserMessage)
        }
    }
}

private struct CodeBlock: View {
    var language: String?
    var text: String
    var isUserMessage: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isUserMessage ? Color.white.opacity(0.78) : PortalTheme.secondaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isUserMessage ? Color.white : PortalTheme.primaryText)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(isUserMessage ? Color.white.opacity(0.12) : PortalTheme.groupedSurface)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}

private struct TableBlock: View {
    var headers: [String]
    var rows: [[String]]
    var isUserMessage: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                tableRow(headers, isHeader: true)
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    tableRow(row, isHeader: false)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isUserMessage ? Color.white.opacity(0.25) : PortalTheme.border, lineWidth: 1)
            )
        }
    }

    private func tableRow(_ cells: [String], isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, cell in
                MarkdownInlineText(
                    cell,
                    font: isHeader ? .caption.weight(.semibold) : .caption,
                    isUserMessage: isUserMessage
                )
                .padding(8)
                .frame(minWidth: 108, alignment: .leading)
                .background(tableBackground(isHeader: isHeader))
            }
        }
    }

    private func tableBackground(isHeader: Bool) -> Color {
        if isUserMessage {
            return Color.white.opacity(isHeader ? 0.16 : 0.08)
        }
        return isHeader ? PortalTheme.groupedSurface : PortalTheme.surface
    }
}
