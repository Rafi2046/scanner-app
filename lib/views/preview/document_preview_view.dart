import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:scanner_app/services/document_share_helper.dart';

/// Full-screen interactive PDF preview viewer.
class DocumentPreviewView extends StatefulWidget {
  const DocumentPreviewView({
    super.key,
    required this.title,
    required this.pdfPath,
  });

  final String title;
  final String pdfPath;

  @override
  State<DocumentPreviewView> createState() => _DocumentPreviewViewState();
}

class _DocumentPreviewViewState extends State<DocumentPreviewView> {
  final PdfViewerController _controller = PdfViewerController();
  int _pageNumber = 1;
  int _pageCount = 0;

  @override
  Widget build(BuildContext context) {
    final File file = File(widget.pdfPath);
    final bool exists = file.existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFF1E222B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161920),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (_pageCount > 0)
              Text(
                'Page $_pageNumber of $_pageCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: <Widget>[
          if (exists)
            IconButton(
              tooltip: 'Share PDF',
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              onPressed: () {
                DocumentShareHelper.sharePdfFile(
                  context,
                  pdfPath: widget.pdfPath,
                  title: widget.title,
                );
              },
            ),
        ],
      ),
      body: !exists
          ? const Center(
              child: Text(
                'PDF file not found on device.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : PdfViewer.file(
              widget.pdfPath,
              controller: _controller,
              params: PdfViewerParams(
                backgroundColor: const Color(0xFF1E222B),
                onPageChanged: (int? page) {
                  if (page != null && mounted) {
                    setState(() => _pageNumber = page);
                  }
                },
                onViewerReady: (PdfDocument doc, _) {
                  if (mounted) {
                    setState(() => _pageCount = doc.pages.length);
                  }
                },
              ),
            ),
    );
  }
}
