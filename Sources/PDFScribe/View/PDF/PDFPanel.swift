import SwiftUI
import PDFKit

struct PDFPanel: NSViewRepresentable {
    @ObservedObject var viewModel: PDFViewModel

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayBox = .mediaBox
        
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
    
    class Coordinator: NSObject {
        var viewModel: PDFViewModel
        
        init(_ viewModel: PDFViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor
        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let selection = pdfView.currentSelection,
                  let text = selection.string else {
                return
            }
            
            viewModel.selectedText = text
        }
    }
}
