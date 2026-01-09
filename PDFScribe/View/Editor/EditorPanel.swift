import SwiftUI
import AppKit

// Custom NSTextView that forces first responder on click
class EditableTextView: NSTextView {
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}

struct EditorPanel: NSViewRepresentable {
    @ObservedObject var viewModel: EditorViewModel

    func makeNSView(context: Context) -> NSScrollView {
        // Create scroll view manually with our custom text view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        let contentSize = scrollView.contentSize
        
        let textContainer = NSTextContainer(containerSize: NSSize(
            width: contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        ))
        textContainer.widthTracksTextView = true
        
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        let textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        let textView = EditableTextView(frame: NSRect(x: 0, y: 0, width: contentSize.width, height: contentSize.height), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        
        // Core editing settings
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.allowsUndo = true
        
        // Appearance - "Digital Study" design system
        // Use system serif font (New York) for editorial feel
        let serifDescriptor = NSFontDescriptor.preferredFontDescriptor(forTextStyle: .body)
            .withDesign(.serif)!
        let serifFont = NSFont(descriptor: serifDescriptor, size: 16)!
        textView.font = serifFont
        textView.textContainerInset = NSSize(width: 32, height: 24) // Generous padding
        
        // Paper-like background - PaperWhite color (adapts to light/dark mode)
        textView.backgroundColor = NSColor(named: "PaperWhite") ?? NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.labelColor
        textView.textColor = NSColor.labelColor
        
        // Set delegate
        textView.delegate = context.coordinator
        
        scrollView.documentView = textView
        
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        
        // Skip update if text view is first responder (user is typing)
        if let window = textView.window, window.firstResponder === textView {
            return
        }
        
        if textView.string != viewModel.content {
            textView.string = viewModel.content
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var viewModel: EditorViewModel
        
        init(_ viewModel: EditorViewModel) {
            self.viewModel = viewModel
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            viewModel.content = textView.string
        }
    }
}
