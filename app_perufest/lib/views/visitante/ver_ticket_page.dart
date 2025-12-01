import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class VerTicketPage extends StatefulWidget {
  final String pdfPath;
  final String ticketId;

  const VerTicketPage({
    super.key,
    required this.pdfPath,
    required this.ticketId,
  });

  @override
  State<VerTicketPage> createState() => _VerTicketPageState();
}

class _VerTicketPageState extends State<VerTicketPage> {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket ${widget.ticketId}'),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _compartirPDF,
            tooltip: 'Compartir',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar el PDF',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            )
          else
            PDFView(
              filePath: widget.pdfPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: _currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  _errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                setState(() {
                  _errorMessage = '$error (página $page)';
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  _currentPage = page ?? 0;
                });
              },
            ),
          
          // Indicador de carga
          if (!_isReady && _errorMessage.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            ),
          
          // Indicador de página
          if (_isReady && _totalPages > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Página ${_currentPage + 1} de $_totalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _compartirPDF() async {
    try {
      final file = File(widget.pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(widget.pdfPath)],
          text: 'Mi ticket para Parque Perú - ${widget.ticketId}',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Archivo PDF no encontrado'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
