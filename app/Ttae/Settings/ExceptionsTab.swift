import SwiftUI

struct ExceptionsTab: View {
    @EnvironmentObject var state: AppState
    @State private var newWord: String = ""
    @State private var selection = Set<String>()
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            description

            inputBar

            if state.exceptionWords.isEmpty {
                emptyState
            } else {
                wordList
                listFooter
            }
        }
        .padding(20)
    }

    private var description: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("예외 단어")
                .font(.headline)
            Text("이 단어들은 교정하지 않습니다. 슬랭, 고유명사, 브랜드명 등을 추가하세요.")
                .font(.callout)
                .foregroundStyle(.secondary)
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

    private var wordList: some View {
        List(selection: $selection) {
            ForEach(state.exceptionWords, id: \.self) { word in
                Text(word)
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
        .frame(minHeight: 200)
    }

    private var listFooter: some View {
        HStack {
            Text("\(state.exceptionWords.count)개")
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.tertiary)
            Text("아직 추가된 예외 단어가 없습니다")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("위 입력란에 단어를 입력해 추가해 보세요")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.05))
        )
    }

    private func add() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.addExceptionWord(trimmed)
        newWord = ""
        inputFocused = true
    }
}
