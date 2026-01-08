import SwiftUI
import PDFKit

struct PDFPanel: NSViewRepresentable {
    @ObservedObject var viewModel: PDFViewModel
    @Binding var pdfViewInstance: PDFView?

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayBox = .mediaBox
        
        context.coordinator.pdfView = pdfView
        DispatchQueue.main.async {
            pdfViewInstance = pdfView
        }
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.selectionChanged(_:)),
            name: .PDFViewSelectionChanged,
            object: pdfView
        )
        
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
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
        NotificationCenter.default.removeObserver(coordinator, name: .PDFViewPageChanged, object: nsView)
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
                NotificationCenter.default.removeObserver(self, name: .PDFViewPageChanged, object: pdfView)
            }
        }
        
        @MainActor
        @objc func selectionChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let selection = pdfView.currentSelection,
                  let text = selection.string else {
                viewModel?.currentSelection = nil
                return
            }
            
            // Get the page number from the first page in the selection
            let pages = selection.pages
            let pageNumber: Int
            if let firstPage = pages.first,
               let document = pdfView.document {
                let pageIndex = document.index(for: firstPage)
                pageNumber = pageIndex + 1 // Convert 0-based to 1-based
            } else {
                pageNumber = 1 // Fallback to page 1
            }
            
            // Just update the current selection - don't trigger quote insertion
            viewModel?.currentSelection = PDFSelection(text: text, pageNumber: pageNumber)
        }
        
        @MainActor
        @objc func pageChanged(_ notification: Notification) {
            guard let pdfView = notification.object as? PDFView,
                  let currentPage = pdfView.currentPage,
                  let document = pdfView.document else {
                return
            }
            
            let pageIndex = document.index(for: currentPage)
            viewModel?.currentPage = pageIndex + 1
        }
    }
}
