import SwiftUI
import PDFKit

struct PDFPanel: NSViewRepresentable {
    @ObservedObject var viewModel: PDFViewModel

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayBox = .mediaBox
        
        context.coordinator.pdfView = pdfView
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionChanged(_:)),
            name: .PDFViewSelectionChanged,
            object: pdfView
        )
        
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        if pdfView.document != viewModel.document {
            pdfView.document = viewModel.document
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }
    
    static func dismantleNSView(_ nsView: PDFView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewSelectionChanged, object: nsView)
    }
    
    class Coordinator: NSObject {
        weak var viewModel: PDFViewModel?
        weak var pdfView: PDFView?
        
        init(_ viewModel: PDFViewModel) {
            self.viewModel = viewModel
        }
        
        deinit {
            if let pdfView = pdfView {
                NotificationCenter.default.removeObserver(self, name: .PDFViewSelectionChanged, object: pdfView)
            }
        }
        
        @MainActor
        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let selection = pdfView.currentSelection,
                  let text = selection.string else {
                return
            }
            
            viewModel?.selectedText = text
        }
    }
}
