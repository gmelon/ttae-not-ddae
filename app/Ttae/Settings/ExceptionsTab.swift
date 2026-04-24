import SwiftUI

struct ExceptionsTab: View {
    @EnvironmentObject var state: AppState
    @State private var newWord: String = ""
    @State private var selection = Set<String>()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이 단어들은 교정하지 않습니다. 슬랭, 고유명사, 브랜드명 등을 추가하세요.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack {
                TextField("추가할 단어", text: $newWord)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { add() }
                Button("추가") { add() }
                    .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            List(selection: $selection) {
                ForEach(state.exceptionWords, id: \.self) { word in
                    Text(word)
                }
            }
            .frame(minHeight: 200)

            HStack {
                Text("총 \(state.exceptionWords.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("선택 삭제") {
                    state.removeExceptionWords(selection)
                    selection.removeAll()
                }
                .disabled(selection.isEmpty)
            }
        }
        .padding()
    }

    private func add() {
        let trimmed = newWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.addExceptionWord(trimmed)
        newWord = ""
    }
}
