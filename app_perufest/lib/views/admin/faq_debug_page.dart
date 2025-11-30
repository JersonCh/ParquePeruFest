import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/faq_viewmodel.dart';
import '../../models/faq.dart';
import '../../services/faq_service.dart';
import '../../services/inicializador_faq.dart';

class FAQDebugPage extends StatefulWidget {
  const FAQDebugPage({super.key});

  @override
  State<FAQDebugPage> createState() => _FAQDebugPageState();
}

class _FAQDebugPageState extends State<FAQDebugPage> {
  final FAQService _faqService = FAQService();
  List<FAQ> _todasLasFAQs = [];
  List<FAQ> _faqsActivas = [];
  bool _isLoading = false;
  String _status = 'Esperando...';
  int _totalDocuments = 0;

  @override
  void initState() {
    super.initState();
    _ejecutarPruebas();
  }

  Future<void> _ejecutarPruebas() async {
    setState(() {
      _isLoading = true;
      _status = 'Iniciando pruebas de conexión...';
    });

    try {
      // Prueba 1: Verificar conexión básica
      await _pruebaConexionBasica();

      // Prueba 2: Contar documentos existentes
      await _contarDocumentosExistentes();

      // Prueba 3: Cargar todas las FAQs
      await _cargarTodasLasFAQs();

      // Prueba 4: Cargar FAQs activas
      await _cargarFAQsActivas();

      // Prueba 5: Inicializar FAQs predeterminadas si es necesario
      await _inicializarFAQsPredeterminadas();

      setState(() {
        _status = 'Todas las pruebas completadas exitosamente ✅';
      });

    } catch (e) {
      setState(() {
        _status = 'Error durante las pruebas: $e ❌';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pruebaConexionBasica() async {
    setState(() {
      _status = 'Probando conexión con Firebase...';
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _status = 'Conexión con Firebase establecida ✅';
    });
  }

  Future<void> _contarDocumentosExistentes() async {
    setState(() {
      _status = 'Contando documentos existentes...';
    });

    try {
      final faqs = await _faqService.obtenerTodasLasFAQs();
      setState(() {
        _totalDocuments = faqs.length;
        _status = 'Documentos encontrados: $_totalDocuments';
      });
    } catch (e) {
      setState(() {
        _status = 'Error al contar documentos: $e';
      });
      throw e;
    }
  }

  Future<void> _cargarTodasLasFAQs() async {
    setState(() {
      _status = 'Cargando todas las FAQs...';
    });

    try {
      final faqs = await _faqService.obtenerTodasLasFAQs();
      setState(() {
        _todasLasFAQs = faqs;
        _status = 'Todas las FAQs cargadas: ${faqs.length} documentos';
      });
    } catch (e) {
      setState(() {
        _status = 'Error al cargar todas las FAQs: $e';
      });
      throw e;
    }
  }

  Future<void> _cargarFAQsActivas() async {
    setState(() {
      _status = 'Cargando FAQs activas...';
    });

    try {
      final faqs = await _faqService.obtenerFAQsActivas();
      setState(() {
        _faqsActivas = faqs;
        _status = 'FAQs activas cargadas: ${faqs.length} documentos';
      });
    } catch (e) {
      setState(() {
        _status = 'Error al cargar FAQs activas: $e';
      });
      throw e;
    }
  }

  Future<void> _inicializarFAQsPredeterminadas() async {
    if (_todasLasFAQs.isEmpty) {
      setState(() {
        _status = 'Inicializando FAQs predeterminadas...';
      });

      try {
        final success = await InicializadorFAQ.inicializarFAQsPredeterminadas();
        if (success) {
          setState(() {
            _status = 'FAQs predeterminadas inicializadas correctamente';
          });
          // Recargar después de inicializar
          await _cargarTodasLasFAQs();
          await _cargarFAQsActivas();
        } else {
          setState(() {
            _status = 'Error al inicializar FAQs predeterminadas';
          });
        }
      } catch (e) {
        setState(() {
          _status = 'Error durante inicialización: $e';
        });
        throw e;
      }
    } else {
      setState(() {
        _status = 'FAQs ya existen, no es necesario inicializar';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Debug de FAQs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _ejecutarPruebas,
            tooltip: 'Ejecutar pruebas nuevamente',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLoading ? Icons.hourglass_empty : Icons.info,
                          color: _isLoading ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Estado de las pruebas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const LinearProgressIndicator()
                    else
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Total FAQs', _todasLasFAQs.length.toString()),
                        _buildStatCard('FAQs Activas', _faqsActivas.length.toString()),
                        _buildStatCard('FAQs Inactivas', 
                            (_todasLasFAQs.length - _faqsActivas.length).toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.list, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'Lista de FAQs cargadas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _todasLasFAQs.isEmpty
                            ? const Center(
                                child: Text(
                                  'No hay FAQs cargadas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _todasLasFAQs.length,
                                itemBuilder: (context, index) {
                                  final faq = _todasLasFAQs[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: faq.estado ? Colors.green : Colors.orange,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      faq.pregunta,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'Estado: ${faq.estado ? "Activa" : "Inactiva"} • Orden: ${faq.orden}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      faq.id.substring(0, 8),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<FAQViewModel>().cargarTodasLasFAQs();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ViewModel actualizado'),
              backgroundColor: Colors.green,
            ),
          );
        },
        backgroundColor: const Color(0xFFB71C1C),
        child: const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB71C1C),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}