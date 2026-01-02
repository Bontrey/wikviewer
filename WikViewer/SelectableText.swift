import SwiftUI
import UIKit

// Selectable Text (as Label)
class SelectableTextLabel: UITextView {

    var onFind: ((String) -> Void)?

    // hide the cursor
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }

    // only allow copy, select, selectAll, share, and customFind
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
            case
            #selector(copy(_:)),
            #selector(select(_:)),
            #selector(selectAll(_:)),
            #selector(customFind(_:)):
            return true
        default:
            if (action == Selector(("_share:"))) {
                return true
            }
            return false
        }
    }

    // Add custom Find menu item
    override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions = suggestedActions

        // Create custom Find action
        let findAction = UIAction(title: "Find", image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
            self?.customFind(nil)
        }

        actions.append(findAction)

        return UIMenu(children: actions)
    }

    // to remove autofill from the action menu
    override func buildMenu(with builder: any UIMenuBuilder) {
        builder.remove(menu: .autoFill)
        super.buildMenu(with: builder)
    }

    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    @objc func customFind(_ sender: Any?) {
        guard let selectedRange = selectedTextRange,
              let selectedText = text(in: selectedRange),
              !selectedText.isEmpty else {
            return
        }
        onFind?(selectedText)
    }
}

struct SelectableText: UIViewRepresentable {

    var text: String
    @Binding var selection: TextSelection?
    var uiFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var textColor: UIColor = .label
    var onFind: ((String) -> Void)?

    func makeUIView(context: Context) -> SelectableTextLabel {
        let textView = SelectableTextLabel()
        textView.delegate = context.coordinator
        textView.text = self.text
        textView.onFind = self.onFind

        // Configure for read-only selectable text
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.autocorrectionType = .no
        textView.textContentType = .none
        textView.font = uiFont
        textView.textColor = textColor

        return textView
    }

    func updateUIView(_ uiView: SelectableTextLabel, context: Context) {
        // Update text if it changed
        if uiView.text != self.text {
            uiView.text = self.text
        }

        // Update font and color
        uiView.font = uiFont
        uiView.textColor = textColor

        // Update onFind callback
        uiView.onFind = self.onFind

        // Don't apply selection from other text fields
        context.coordinator.currentText = self.text

        uiView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        uiView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Force layout update
        uiView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: SelectableTextLabel, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let size = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: size.height)
    }
}

// SwiftUI modifiers for SelectableText
extension SelectableText {
    func font(_ font: Font) -> SelectableText {
        var view = self
        view.uiFont = font.toUIFont()
        return view
    }

    func foregroundColor(_ color: Color) -> SelectableText {
        var view = self
        view.textColor = UIColor(color)
        return view
    }

    func italic() -> SelectableText {
        var view = self
        if let currentFont = uiFont.fontDescriptor.withSymbolicTraits(.traitItalic) {
            view.uiFont = UIFont(descriptor: currentFont, size: uiFont.pointSize)
        }
        return view
    }

    func onFindAction(_ action: @escaping (String) -> Void) -> SelectableText {
        var view = self
        view.onFind = action
        return view
    }
}

// Extension to convert SwiftUI Font to UIFont
extension Font {
    func toUIFont() -> UIFont {
        // Map common SwiftUI fonts to UIFont
        // This is a simplified mapping
        return UIFont.preferredFont(forTextStyle: .body)
    }
}

extension SelectableText {

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SelectableText
        var currentText: String = ""
        var isUpdating = false

        init(_ control: SelectableText) {
            self.parent = control
            super.init()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Prevent feedback loop
            guard !isUpdating else { return }

            // we are only interested in selection
            // insertion should not trigger updates
            if let selectedRange = textView.selectedTextRange, !selectedRange.isEmpty {
                isUpdating = true
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.parent.selection = textView.selectedTextRange?.textSelection(textView)
                    self.isUpdating = false
                }
            }
        }

        // Prevent editing
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            false
        }
    }
}

// MARK: - Extensions for TextSelection

extension TextSelection {
    func textRange(_ textView: UITextView) ->  UITextRange? {
        guard let text = textView.text else { return nil }
        switch self.indices {
        case .selection(let range):
            if self.isInsertion {
                guard let position = textView.position(from: textView.beginningOfDocument, offset: range.lowerBound.utf16Offset(in: text)) else {return nil}
                return textView.textRange(from: position, to: position)

            } else {
                guard let start = textView.position(from: textView.beginningOfDocument, offset: range.lowerBound.utf16Offset(in: text)), let end = textView.position(from: textView.beginningOfDocument, offset: range.upperBound.utf16Offset(in: text)) else {return nil}
                return textView.textRange(from: start, to: end)
            }
        default:
            return nil

        }
    }
}

extension UITextRange {
    func textSelection(_ textView: UITextView) -> TextSelection? {
        guard let text = textView.text else { return nil }
        let start = textView.offset(from: textView.beginningOfDocument, to: self.start)

        if self.isEmpty {
            return .init(insertionPoint: .init(utf16Offset: start, in: text))
        }

        let end = textView.offset(from: textView.beginningOfDocument, to: self.end)

        return .init(range: String.Index.init(utf16Offset: start, in: text)..<String.Index.init(utf16Offset: end, in: text))
    }
}
