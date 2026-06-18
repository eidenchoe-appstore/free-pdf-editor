import PDFKit
import SwiftUI

struct ThumbnailSidebarView: View {
    @EnvironmentObject private var editor: PDFEditorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Pages")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(0..<editor.pageCount, id: \.self) { index in
                        ThumbnailRow(index: index)
                            .contentShape(Rectangle())
                            .onTapGesture { editor.goToPage(index) }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            }
        }
        .background(.regularMaterial)
    }
}

private struct ThumbnailRow: View {
    @EnvironmentObject private var editor: PDFEditorModel
    let index: Int

    var body: some View {
        VStack(spacing: 6) {
            if let image = thumbnail {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 124, maxHeight: 164)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(editor.currentPageIndex == index ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: editor.currentPageIndex == index ? 2 : 1)
                    }
            }
            Text("\(index + 1)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(editor.currentPageIndex == index ? .primary : .secondary)
        }
        .padding(6)
        .background(editor.currentPageIndex == index ? Color.accentColor.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var thumbnail: NSImage? {
        editor.page(at: index)?.thumbnail(of: CGSize(width: 220, height: 300), for: .cropBox)
    }
}
