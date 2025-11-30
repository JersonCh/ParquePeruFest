import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/faq_viewmodel.dart';
import '../../models/faq.dart';
import 'crear_faq_page.dart';
import 'editar_faq_page.dart';
import 'faq_debug_page.dart';

class FAQAdminOptimizada extends StatefulWidget {
  const FAQAdminOptimizada({super.key});

  @override
  State<FAQAdminOptimizada> createState() => _FAQAdminOptimizadaState();
}

class _FAQAdminOptimizadaState extends State<FAQAdminOptimizada> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosConTimeout();
  }

  Future<void> _cargarDatosConTimeout() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final faqViewModel = Provider.of<FAQViewModel>(context, listen: false);
      
      // Cargar con timeout de 8 segundos
      await Future.any([
        faqViewModel.cargarTodasLasFAQs(),
        Future.delayed(const Duration(seconds: 8), () => throw TimeoutException('Timeout')),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().contains('Timeout') 
              ? 'Tiempo de carga agotado. Verifica tu conexión.' 
              : 'Error al cargar las FAQs: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de FAQs',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFB71C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQDebugPage()),
              );
            },
            tooltip: 'Debug FAQs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatosConTimeout,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarACrearFAQ(context),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva FAQ'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    return Consumer<FAQViewModel>(
      builder: (context, faqViewModel, child) {
        return StreamBuilder<List<FAQ>>(
          stream: faqViewModel.streamTodasLasFAQs,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }
            
            if (snapshot.hasError) {
              return _buildErrorWidget(error: 'Error al cargar FAQs: ${snapshot.error}');
            }
            
            final faqs = snapshot.data ?? [];
            
            // Actualizar también el ViewModel con los datos del stream
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                faqViewModel.actualizarFAQsDesdeStream(faqs);
                if (faqs.isNotEmpty) {
                  setState(() {
                    _hasError = false;
                  });
                }
              }
            });
            
            return _buildFAQList(faqs);
          },
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB71C1C)),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando FAQs...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget({String? error}) {
    final errorText = error ?? _errorMessage;
    return Center(
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
              'Error',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatosConTimeout,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQList(List<FAQ> faqs) {
    if (faqs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsCard(faqs),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return _buildFAQCard(faq);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(List<FAQ> faqs) {
    final activaCount = faqs.where((faq) => faq.estado).length;
    final inactivaCount = faqs.length - activaCount;

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFB71C1C),
            const Color(0xFFB71C1C).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total FAQs', faqs.length.toString(), Icons.quiz),
          _buildStatItem('Activas', activaCount.toString(), Icons.check_circle),
          _buildStatItem('Inactivas', inactivaCount.toString(), Icons.pause_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay FAQs registradas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera pregunta frecuente\npara ayudar a los visitantes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navegarACrearFAQ(context),
              icon: const Icon(Icons.add),
              label: const Text('Crear primera FAQ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQ faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navegarAEditarFAQ(context, faq),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.pregunta,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: faq.estado ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      faq.estado ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: faq.estado ? Colors.green[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                faq.respuesta,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orden: ${faq.orden}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _navegarAEditarFAQ(context, faq),
                        icon: const Icon(Icons.edit, size: 20),
                        color: const Color(0xFFB71C1C),
                        tooltip: 'Editar FAQ',
                      ),
                      IconButton(
                        onPressed: () => _mostrarDialogoEliminar(context, faq),
                        icon: const Icon(Icons.delete, size: 20),
                        color: Colors.red,
                        tooltip: 'Eliminar FAQ',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navegarACrearFAQ(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearFAQPage()),
    ).then((_) {
      // Recargar datos después de crear
      _cargarDatosConTimeout();
    });
  }

  void _navegarAEditarFAQ(BuildContext context, FAQ faq) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarFAQPage(faq: faq)),
    ).then((_) {
      // Recargar datos después de editar
      _cargarDatosConTimeout();
    });
  }

  void _mostrarDialogoEliminar(BuildContext context, FAQ faq) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de eliminar la FAQ "${faq.pregunta}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _eliminarFAQ(faq);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarFAQ(FAQ faq) async {
    try {
      final faqViewModel = Provider.of<FAQViewModel>(context, listen: false);
      await faqViewModel.eliminarFAQ(faq.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FAQ eliminada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatosConTimeout();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar FAQ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}