import SwiftUI
import AppKit

struct EditorPanel: NSViewRepresentable {
    @ObservedObject var viewModel: EditorViewModel

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.delegate = context.coordinator
        
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        // Only update if the text view is not being edited and content differs
        // This preserves cursor position and prevents disrupting user input
        guard let window = textView.window,
              window.firstResponder != textView,
              textView.string != viewModel.content else {
            return
        }
        
        let selectedRange = textView.selectedRange()
        textView.string = viewModel.content
        
        // Attempt to restore selection if valid
        if selectedRange.location != NSNotFound && selectedRange.location <= textView.string.count {
            textView.setSelectedRange(selectedRange)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        weak var viewModel: EditorViewModel?
        
        init(_ viewModel: EditorViewModel) {
            self.viewModel = viewModel
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let content = textView.string
            Task { @MainActor in
                self.viewModel?.content = content
            }
        }
    }
}
