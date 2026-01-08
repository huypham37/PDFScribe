import SwiftUI
import PDFKit

struct PDFControlBar: View {
    @ObservedObject var viewModel: PDFViewModel
    let pdfView: PDFView?
    
    var body: some View {
        HStack(spacing: 16) {
            // Navigation controls
            Button(action: previousPage) {
                Image(systemName: "chevron.left")
            }
            .disabled(viewModel.currentPage <= 1)
            
            Text("\(viewModel.currentPage) / \(viewModel.totalPages)")
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 60)
            
            Button(action: nextPage) {
                Image(systemName: "chevron.right")
            }
            .disabled(viewModel.currentPage >= viewModel.totalPages)
            
            Divider()
                .frame(height: 20)
            
            // Zoom controls
            Button(action: zoomOut) {
                Image(systemName: "minus.magnifyingglass")
            }
            
            Button(action: resetZoom) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
            }
            
            Button(action: zoomIn) {
                Image(systemName: "plus.magnifyingglass")
            }
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func previousPage() {
        pdfView?.goToPreviousPage(nil)
        updateCurrentPage()
    }
    
    private func nextPage() {
        pdfView?.goToNextPage(nil)
        updateCurrentPage()
    }
    
    private func zoomIn() {
        pdfView?.zoomIn(nil)
    }
    
    private func zoomOut() {
        pdfView?.zoomOut(nil)
    }
    
    private func resetZoom() {
        pdfView?.scaleFactor = 1.0
    }
    
    private func updateCurrentPage() {
        guard let pdfView = pdfView,
              let currentPage = pdfView.currentPage,
              let document = pdfView.document else {
            return
        }
        
        Task { @MainActor in
            viewModel.currentPage = document.index(for: currentPage) + 1
        }
    }
}
