import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';

// Create a dialog for the image viewer
class PhotoViewDialog extends StatelessWidget {
  final String imageUrl;
  final String fileName;

  const PhotoViewDialog({Key? key, required this.imageUrl, required this.fileName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
              loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.white));
              },
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis)),
                  Container(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Create a dialog for the PDF viewer
class PDFViewerDialog extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PDFViewerDialog({Key? key, required this.pdfUrl, required this.fileName}) : super(key: key);

  @override
  State<PDFViewerDialog> createState() => _PDFViewerDialogState();
}

class _PDFViewerDialogState extends State<PDFViewerDialog> {
  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
        child:
            _error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 50, color: Colors.white),
                      const SizedBox(height: 16),
                      Text('Error loading PDF: $_error', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                        },
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                    ],
                  ),
                )
                : Stack(
                  children: [
                    PDFView(
                      filePath: widget.pdfUrl,
                      autoSpacing: true,
                      enableSwipe: true,
                      pageFling: true,
                      pageSnap: true,
                      swipeHorizontal: true,
                      nightMode: false,
                      onError: (error) {
                        setState(() {
                          _isLoading = false;
                          _error = error.toString();
                        });
                      },
                      onRender: (pages) {
                        setState(() {
                          _isLoading = false;
                        });
                      },
                      onViewCreated: (PDFViewController pdfViewController) {
                        setState(() {
                          _isLoading = false;
                        });
                      },
                    ),
                    if (_isLoading) const Center(child: CircularProgressIndicator()),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(widget.fileName, style: const TextStyle(color: Colors.white, fontSize: 16), overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                            child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
