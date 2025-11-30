import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class PDFViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String fileName;

  const PDFViewerPage({
    Key? key,
    required this.pdfUrl,
    required this.fileName,
  }) : super(key: key);

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localPath;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int currentPage = 0;
  int totalPages = 0;
  bool isReady = false;
  PDFViewController? pdfViewController;

  @override
  void initState() {
    super.initState();
    _descargarPDF();
  }

  Future<void> _descargarPDF() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final dir = await getTemporaryDirectory();
      final fileName = widget.fileName.endsWith('.pdf') 
          ? widget.fileName 
          : '${widget.fileName}.pdf';
      final filePath = '${dir.path}/$fileName';

      // Descargar PDF usando Dio
      final dio = Dio();
      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Descargando PDF: $progress%');
          }
        },
      );

      setState(() {
        localPath = filePath;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error al cargar el PDF: ${e.toString()}';
      });
      debugPrint('Error al descargar PDF: $e');
    }
  }

  Future<void> _descargarPDFParaGuardar() async {
    try {
      // Solicitar permisos según la versión de Android
      bool permisoConcedido = false;
      
      if (Platform.isAndroid) {
        await Permission.storage.request();
        
        // Para Android 13+ (API 33+), no se necesitan permisos especiales para descargas
        // Para Android 10-12 (API 29-32), usar diferentes estrategias
        if (await Permission.storage.isGranted) {
          permisoConcedido = true;
        } else if (await Permission.manageExternalStorage.isGranted) {
          permisoConcedido = true;
        } else if (await Permission.photos.isGranted) {
          permisoConcedido = true;
        } else {
          // Intentar solicitar manageExternalStorage
          final status = await Permission.manageExternalStorage.request();
          if (status.isGranted) {
            permisoConcedido = true;
          } else {
            // Si no se concede, intentar de todas formas (funciona en Android 13+)
            permisoConcedido = true;
          }
        }
      } else {
        permisoConcedido = true;
      }

      if (!permisoConcedido) {
        _mostrarMensaje('Se necesitan permisos de almacenamiento', Colors.red);
        return;
      }

      _mostrarMensaje('Descargando PDF...', const Color(0xFF8B1B1B));

      // Obtener directorio de descargas
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        // Asegurarse de que el directorio existe
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final fileName = widget.fileName.endsWith('.pdf') 
          ? widget.fileName 
          : '${widget.fileName}.pdf';
      final savePath = '${downloadsDir.path}/$fileName';

      // Descargar archivo
      final dio = Dio();
      await dio.download(widget.pdfUrl, savePath);

      _mostrarMensaje('PDF guardado en Descargas/$fileName', Colors.green);
    } catch (e) {
      _mostrarMensaje('Error al guardar PDF: $e', Colors.red);
      debugPrint('Error al guardar PDF: $e');
    }
  }

  void _mostrarMensaje(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _compartirPDF() async {
    if (localPath != null) {
      try {
        await Share.shareXFiles(
          [XFile(localPath!)],
          text: 'Documento: ${widget.fileName}',
        );
      } catch (e) {
        _mostrarMensaje('Error al compartir PDF', Colors.red);
      }
    }
  }

  Future<void> _irAPagina(int pagina) async {
    if (pdfViewController != null && pagina >= 0 && pagina < totalPages) {
      await pdfViewController!.setPage(pagina);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fileName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (isReady && totalPages > 0)
              Text(
                'Página ${currentPage + 1} de $totalPages',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF8B1B1B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón de descargar
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Descargar PDF',
            onPressed: _descargarPDFParaGuardar,
          ),
          // Botón de compartir
          if (!Platform.isWindows && !Platform.isLinux)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Compartir',
              onPressed: _compartirPDF,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Contenido del PDF
          if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1B1B)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando documento...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar el PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _descargarPDF,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1B1B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (localPath != null)
            PDFView(
              filePath: localPath!,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              defaultPage: currentPage,
              fitPolicy: FitPolicy.BOTH,
              preventLinkNavigation: false,
              onRender: (pages) {
                setState(() {
                  totalPages = pages ?? 0;
                  isReady = true;
                });
              },
              onError: (error) {
                setState(() {
                  hasError = true;
                  errorMessage = error.toString();
                });
              },
              onPageError: (page, error) {
                debugPrint('Error en página $page: $error');
              },
              onViewCreated: (PDFViewController vc) {
                pdfViewController = vc;
              },
              onPageChanged: (int? page, int? total) {
                setState(() {
                  currentPage = page ?? 0;
                  totalPages = total ?? 0;
                });
              },
            ),
        ],
      ),
      // Controles de navegación flotantes
      floatingActionButton: isReady && !isLoading && !hasError && totalPages > 1
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Ir a primera página
                if (currentPage > 0)
                  FloatingActionButton.small(
                    heroTag: 'first_page',
                    onPressed: () => _irAPagina(0),
                    backgroundColor: const Color(0xFF8B1B1B),
                    tooltip: 'Primera página',
                    child: const Icon(Icons.first_page, color: Colors.white, size: 20),
                  ),
                if (currentPage > 0) const SizedBox(height: 8),
                
                // Página anterior
                if (currentPage > 0)
                  FloatingActionButton.small(
                    heroTag: 'prev_page',
                    onPressed: () => _irAPagina(currentPage - 1),
                    backgroundColor: const Color(0xFF8B1B1B),
                    tooltip: 'Página anterior',
                    child: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  ),
                if (currentPage > 0) const SizedBox(height: 8),
                
                // Indicador de página actual
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1B1B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentPage + 1}/$totalPages',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Página siguiente
                if (currentPage < totalPages - 1)
                  FloatingActionButton.small(
                    heroTag: 'next_page',
                    onPressed: () => _irAPagina(currentPage + 1),
                    backgroundColor: const Color(0xFF8B1B1B),
                    tooltip: 'Página siguiente',
                    child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  ),
                if (currentPage < totalPages - 1) const SizedBox(height: 8),
                
                // Ir a última página
                if (currentPage < totalPages - 1)
                  FloatingActionButton.small(
                    heroTag: 'last_page',
                    onPressed: () => _irAPagina(totalPages - 1),
                    backgroundColor: const Color(0xFF8B1B1B),
                    tooltip: 'Última página',
                    child: const Icon(Icons.last_page, color: Colors.white, size: 20),
                  ),
              ],
            )
          : null,
    );
  }
}
