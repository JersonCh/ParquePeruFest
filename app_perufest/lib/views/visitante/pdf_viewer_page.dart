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

  const PDFViewerPage({Key? key, required this.pdfUrl, required this.fileName})
    : super(key: key);

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
        isReady = false;
      });

      final dir = await getTemporaryDirectory();
      final fileName =
          widget.fileName.endsWith('.pdf')
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
        isReady = true;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        isReady = false;
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

      final fileName =
          widget.fileName.endsWith('.pdf')
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
        await Share.shareXFiles([
          XFile(localPath!),
        ], text: 'Documento: ${widget.fileName}');
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

  void _reintentar() {
    setState(() {
      hasError = false;
      isLoading = true;
      isReady = false;
      localPath = null;
    });
    _descargarPDF();
  }

  Widget _buildPDFContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (hasError) {
      return _buildErrorState();
    }

    if (localPath == null) {
      return _buildInitialState();
    }

    return PDFView(
      filePath: localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: false,
      pageSnap: true,
      defaultPage: currentPage,
      fitPolicy: FitPolicy.WIDTH,
      preventLinkNavigation: false,
      backgroundColor: Colors.white,
      nightMode: false,
      onRender: (pages) {
        setState(() {
          totalPages = pages ?? 0;
        });
      },
      onError: (error) {
        print('Error al renderizar PDF: $error');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      },
      onPageError: (page, error) {
        print('Error en página $page: $error');
      },
      onViewCreated: (PDFViewController controller) {
        this.pdfViewController = controller;
      },
      onLinkHandler: (String? uri) {
        print('Link: $uri');
      },
      onPageChanged: (int? page, int? total) {
        setState(() {
          currentPage = page ?? 0;
        });
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 122, 0, 37), Color(0xFF8B1538)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando documento...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando información del evento',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error al cargar documento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar la información adicional del evento. Verifica tu conexión a internet e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _reintentar(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 122, 0, 37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Reintentar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 122, 0, 37), Color(0xFF8B1538)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.description_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Documento listo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando visualización...',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color.fromARGB(255, 122, 0, 37),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // AppBar elegante
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color.fromARGB(255, 122, 0, 37),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 122, 0, 37),
                      Color(0xFF8B1538),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isReady && totalPages > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Página ${currentPage + 1} de $totalPages',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Botones de acción elegantes
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'Descargar',
                        onPressed: _descargarPDFParaGuardar,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!Platform.isWindows && !Platform.isLinux)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          tooltip: 'Compartir',
                          onPressed: _compartirPDF,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Contenido del PDF
          SliverFillRemaining(child: _buildPDFContent()),
        ],
      ),

      // Controles de navegación elegantes
      floatingActionButton:
          isReady && !isLoading && !hasError && totalPages > 1
              ? Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Panel de controles compacto
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Primera página
                          if (currentPage > 0) ...[
                            _buildNavButton(
                              icon: Icons.first_page_rounded,
                              onPressed: () => _irAPagina(0),
                              tooltip: 'Primera',
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Página anterior
                          if (currentPage > 0) ...[
                            _buildNavButton(
                              icon: Icons.chevron_left_rounded,
                              onPressed: () => _irAPagina(currentPage - 1),
                              tooltip: 'Anterior',
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Indicador de página
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 122, 0, 37),
                                  Color(0xFF8B1538),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${currentPage + 1}/$totalPages',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Página siguiente
                          if (currentPage < totalPages - 1) ...[
                            const SizedBox(width: 8),
                            _buildNavButton(
                              icon: Icons.chevron_right_rounded,
                              onPressed: () => _irAPagina(currentPage + 1),
                              tooltip: 'Siguiente',
                            ),
                            const SizedBox(width: 4),
                          ],

                          // Última página
                          if (currentPage < totalPages - 1)
                            _buildNavButton(
                              icon: Icons.last_page_rounded,
                              onPressed: () => _irAPagina(totalPages - 1),
                              tooltip: 'Última',
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
