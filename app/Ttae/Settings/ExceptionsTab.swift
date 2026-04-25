import SwiftUI

struct ExceptionsTab: View {
    @Environment(AppState.self) private var state
    @State private var newWord: String = ""
    @State private var selection = Set<String>()
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            description
            inputBar
            contentArea
            listFooter
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("예외 단어")
                .font(.headline)
            Text("교정에서 제외할 단어를 등록합니다. 사람 이름, 브랜드명, 자주 쓰는 신조어처럼 사전에 없어도 그대로 두고 싶은 표현을 추가하세요.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("단어 입력 후 Enter", text: $newWord)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .onSubmit { add() }
            Button("추가") { add() }
                .buttonStyle(.borderedProminent)
                .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    @ViewBuilder
    private var contentArea: some View {
        Group {
            if state.exceptionWords.isEmpty {
                emptyState
            } else {
                wordList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var wordList: some View {
        List(selection: $selection) {
            ForEach(state.exceptionWords, id: \.self) { word in
                Text(word)
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            MageIcon("inbox", size: 36)
                .foregroundStyle(.tertiary)
            Text("아직 추가된 예외 단어가 없습니다")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("위 입력란에 단어를 입력해 추가해 보세요")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.secondary.opacity(0.18), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.alternatingContentBackgroundColors.first ?? .clear))
                )
        )
    }

    private var listFooter: some View {
        HStack {
            Text("\(state.exceptionWords.count)개")
                .font(.caption)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: state.exceptionWords.count)
            Spacer()
            if !selection.isEmpty {
                Button(role: .destructive) {
                    state.removeExceptionWords(selection)
                    selection.removeAll()
                } label: {
                    Text("선택 \(selection.count)개 삭제")
                }
                .controlSize(.small)
            }
        }
    }

    private func add() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.addExceptionWord(trimmed)
        newWord = ""
        inputFocused = true
    }
}
