import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/faq_viewmodel.dart';
import '../../models/faq.dart';
import '../../services/inicializador_faq.dart';
import 'crear_faq_page.dart';
import 'editar_faq_page.dart';

class FAQAdminPage extends StatefulWidget {
  const FAQAdminPage({super.key});

  @override
  State<FAQAdminPage> createState() => _FAQAdminPageState();
}

class _FAQAdminPageState extends State<FAQAdminPage> {
  @override
  void initState() {
    super.initState();
    // Cargar FAQs de manera asíncrona sin bloquear la UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inicializarFAQsSeguro();
      }
    });
  }

  // Método seguro que no bloquea la UI
  void _inicializarFAQsSeguro() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _inicializarFAQs().catchError((error) {
          debugPrint('Error en inicialización de FAQs: $error');
        });
      }
    });
  }

  Future<void> _inicializarFAQs() async {
    try {
      if (!mounted) return;
      
      // Cargar FAQs existentes primero (operación más rápida)
      final faqViewModel = Provider.of<FAQViewModel>(context, listen: false);
      await faqViewModel.cargarTodasLasFAQs();
      
      // Si no hay FAQs, inicializar las predeterminadas en segundo plano
      if (mounted && faqViewModel.faqs.isEmpty) {
        _inicializarFAQsPredeterminadas();
      }
    } catch (e) {
      debugPrint('Error al inicializar FAQs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar FAQs: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Reintentar',
              onPressed: () => _inicializarFAQs(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _inicializarFAQsPredeterminadas() async {
    try {
      await InicializadorFAQ.inicializarFAQsPredeterminadas();
      
      if (mounted) {
        final faqViewModel = Provider.of<FAQViewModel>(context, listen: false);
        await faqViewModel.cargarTodasLasFAQs();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FAQs inicializadas correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al crear FAQs predeterminadas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Consumer<FAQViewModel>(
          builder: (context, faqViewModel, child) {
            // Mostrar loading inicial
            if (faqViewModel.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF8B1B1B),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando preguntas frecuentes...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Mostrar error si existe
            if (faqViewModel.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar las FAQs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        faqViewModel.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => _inicializarFAQs(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1B1B),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Reintentar'),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () => _inicializarFAQsPredeterminadas(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF8B1B1B),
                          ),
                          child: const Text('Crear FAQs Iniciales'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            // Mostrar contenido principal
            return Column(
              children: [
                _buildHeader(faqViewModel),
                _buildEstadisticas(faqViewModel),
                Expanded(
                  child: _buildFAQsList(faqViewModel),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarACrearFAQ(),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva FAQ'),
      ),
    );
  }

  Widget _buildHeader(FAQViewModel faqViewModel) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B1B1B),
            const Color(0xFF8B1B1B).withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.help_center,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de FAQs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Administra las preguntas frecuentes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (faqViewModel.faqs.isEmpty)
            ElevatedButton.icon(
              onPressed: () => _crearFAQsPredeterminadas(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8B1B1B),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Crear FAQs Iniciales'),
            ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas(FAQViewModel faqViewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildEstadisticaItem(
            'Total',
            faqViewModel.totalFAQs.toString(),
            Icons.help_outline,
            const Color(0xFF8B1B1B),
          ),
          const SizedBox(width: 20),
          _buildEstadisticaItem(
            'Activas',
            faqViewModel.faqsActivasCount.toString(),
            Icons.visibility,
            Colors.green,
          ),
          const SizedBox(width: 20),
          _buildEstadisticaItem(
            'Inactivas',
            faqViewModel.faqsInactivasCount.toString(),
            Icons.visibility_off,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaItem(String titulo, String valor, IconData icono, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQsList(FAQViewModel faqViewModel) {
    if (faqViewModel.faqs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: faqViewModel.faqs.length,
      itemBuilder: (context, index) {
        final faq = faqViewModel.faqs[index];
        return _buildFAQCard(faq, faqViewModel);
      },
    );
  }

  Widget _buildFAQCard(FAQ faq, FAQViewModel faqViewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: faq.estado ? Colors.green.shade100 : Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            faq.estado ? Icons.check_circle : Icons.cancel,
            color: faq.estado ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          faq.pregunta,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: faq.estado ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: faq.estado ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  faq.estado ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    color: faq.estado ? Colors.green.shade700 : Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Orden: ${faq.orden}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Respuesta:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B1B1B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  faq.respuesta,
                  style: const TextStyle(height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Creada: ${_formatearFecha(faq.fechaCreacion)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Modificada: ${_formatearFecha(faq.fechaModificacion)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navegarAEditarFAQ(faq),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B1B1B),
                        side: const BorderSide(color: Color(0xFF8B1B1B)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cambiarEstado(faq, faqViewModel),
                      icon: Icon(faq.estado ? Icons.visibility_off : Icons.visibility),
                      label: Text(faq.estado ? 'Desactivar' : 'Activar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: faq.estado ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _confirmarEliminar(faq, faqViewModel),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay preguntas frecuentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea la primera pregunta frecuente para comenzar',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navegarACrearFAQ(),
                icon: const Icon(Icons.add),
                label: const Text('Crear FAQ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1B1B),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _crearFAQsPredeterminadas(),
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('FAQs Iniciales'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1B1B),
                  side: const BorderSide(color: Color(0xFF8B1B1B)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navegarACrearFAQ() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CrearFAQPage(),
      ),
    );
  }

  void _navegarAEditarFAQ(FAQ faq) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarFAQPage(faq: faq),
      ),
    );
  }

  void _cambiarEstado(FAQ faq, FAQViewModel faqViewModel) async {
    final success = await faqViewModel.cambiarEstadoFAQ(faq.id, !faq.estado);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'FAQ ${faq.estado ? 'desactivada' : 'activada'} correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(faqViewModel.error ?? 'Error al cambiar estado'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarEliminar(FAQ faq, FAQViewModel faqViewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar FAQ'),
        content: Text(
          '¿Estás seguro de que quieres eliminar la pregunta "${faq.pregunta}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await faqViewModel.eliminarFAQ(faq.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('FAQ eliminada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(faqViewModel.error ?? 'Error al eliminar FAQ'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _crearFAQsPredeterminadas() async {
    final faqViewModel = context.read<FAQViewModel>();
    final success = await faqViewModel.crearFAQsPredeterminadas();
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FAQs predeterminadas creadas correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(faqViewModel.error ?? 'Error al crear FAQs predeterminadas'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}