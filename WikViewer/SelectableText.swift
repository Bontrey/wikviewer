import SwiftUI
import UIKit

// Selectable Text (as Label)
class SelectableTextLabel: UITextView {

    var onFind: ((String) -> Void)?
    var onSearch: ((String) -> Void)?

    // hide the cursor
    override func caretRect(for position: UITextPosition) -> CGRect {
        return .zero
    }

    // only allow copy, share, customFind, customSearch, lookup, and translate
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        switch action {
            case
            #selector(copy(_:)),
            #selector(customFind(_:)),
            #selector(customSearch(_:)):
            return true
        default:
            if (action == Selector(("_share:"))) {
                return true
            }
            if (action == Selector(("_define:"))) {
                return true
            }
            if (action == Selector(("_translate:"))) {
                return true
            }
            return false
        }
    }

    // Add custom Find and Search menu items
    override func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
        var actions = suggestedActions

        // Create custom Find action
        let findAction = UIAction(title: "Find", image: UIImage(systemName: "magnifyingglass")) { [weak self] _ in
            self?.customFind(nil)
        }

        // Create custom Search action
        let searchAction = UIAction(title: "Search", image: UIImage(systemName: "magnifyingglass.circle")) { [weak self] _ in
            self?.customSearch(nil)
        }

        actions.insert(findAction, at: 0)
        actions.insert(searchAction, at: 1)

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

    @objc func customSearch(_ sender: Any?) {
        guard let selectedRange = selectedTextRange,
              let selectedText = text(in: selectedRange),
              !selectedText.isEmpty else {
            return
        }
        onSearch?(selectedText)
    }
}

struct SelectableText: UIViewRepresentable {

    var text: String
    @Binding var selection: TextSelection?
    var uiFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var fontWeight: UIFont.Weight?
    var textColor: UIColor = .label
    var onFind: ((String) -> Void)?
    var onSearch: ((String) -> Void)?

    func makeUIView(context: Context) -> SelectableTextLabel {
        let textView = SelectableTextLabel()
        textView.delegate = context.coordinator
        textView.text = self.text
        textView.onFind = self.onFind
        textView.onSearch = self.onSearch

        // Configure for read-only selectable text
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.autocorrectionType = .no
        textView.textContentType = .none
        textView.font = applyFontWeight(to: uiFont, weight: fontWeight)
        textView.textColor = textColor

        return textView
    }

    func updateUIView(_ uiView: SelectableTextLabel, context: Context) {
        // Update text if it changed
        if uiView.text != self.text {
            uiView.text = self.text
        }

        // Update font and color
        uiView.font = applyFontWeight(to: uiFont, weight: fontWeight)
        uiView.textColor = textColor

        // Update callbacks
        uiView.onFind = self.onFind
        uiView.onSearch = self.onSearch

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

    private func applyFontWeight(to font: UIFont, weight: UIFont.Weight?) -> UIFont {
        guard let weight = weight else { return font }

        let traits: [UIFontDescriptor.TraitKey: Any] = [
            .weight: weight
        ]

        let descriptor = font.fontDescriptor.addingAttributes([
            .traits: traits
        ])

        return UIFont(descriptor: descriptor, size: font.pointSize)
    }
}

// SwiftUI modifiers for SelectableText
extension SelectableText {
    func font(_ font: Font) -> SelectableText {
        var view = self
        view.uiFont = font.toUIFont()
        return view
    }

    func fontWeight(_ weight: Font.Weight) -> SelectableText {
        var view = self
        view.fontWeight = weight.toUIFontWeight()
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
        switch self {
        case .largeTitle:
            return UIFont.preferredFont(forTextStyle: .largeTitle)
        case .title:
            return UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            return UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            return UIFont.preferredFont(forTextStyle: .subheadline)
        case .body:
            return UIFont.preferredFont(forTextStyle: .body)
        case .callout:
            return UIFont.preferredFont(forTextStyle: .callout)
        case .footnote:
            return UIFont.preferredFont(forTextStyle: .footnote)
        case .caption:
            return UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            return UIFont.preferredFont(forTextStyle: .caption2)
        default:
            return UIFont.preferredFont(forTextStyle: .body)
        }
    }
}

// Extension to convert SwiftUI Font.Weight to UIFont.Weight
extension Font.Weight {
    func toUIFontWeight() -> UIFont.Weight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        default:
            return .regular
        }
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
