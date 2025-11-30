import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/faq.dart';
import 'crear_faq_page.dart';
import 'editar_faq_page.dart';

class FAQAdminSimple extends StatefulWidget {
  const FAQAdminSimple({super.key});

  @override
  State<FAQAdminSimple> createState() => _FAQAdminSimpleState();
}

class _FAQAdminSimpleState extends State<FAQAdminSimple> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FAQ> _faqs = [];
  bool _isLoading = false;
  String? _error;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarFAQs();
    });
  }

  Future<void> _cargarFAQs() async {
    if (!mounted || _isLoadingData) return;
    
    _isLoadingData = true;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Consulta simple sin índices compuestos
      final querySnapshot = await _firestore
          .collection('faqs')
          .get()
          .timeout(const Duration(seconds: 10));

      final faqs = querySnapshot.docs
          .map((doc) => FAQ.fromFirestore(doc))
          .toList();

      // Ordenar en memoria
      faqs.sort((a, b) {
        if (a.orden != b.orden) {
          return a.orden.compareTo(b.orden);
        }
        return a.fechaCreacion.compareTo(b.fechaCreacion);
      });

      if (mounted) {
        setState(() {
          _faqs = faqs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar FAQs: $e';
          _isLoading = false;
        });
      }
    } finally {
      _isLoadingData = false;
    }
  }

  Future<void> _eliminarFAQ(FAQ faq) async {
    try {
      await _firestore.collection('faqs').doc(faq.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FAQ eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarFAQs(); // Recargar la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar FAQ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cambiarEstado(FAQ faq) async {
    try {
      await _firestore.collection('faqs').doc(faq.id).update({
        'estado': !faq.estado,
        'fechaModificacion': Timestamp.fromDate(DateTime.now()),
      });
      _cargarFAQs(); // Recargar la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar estado: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarFAQs,
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
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
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
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarFAQs,
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

    if (_faqs.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsCard(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _faqs.length,
            itemBuilder: (context, index) {
              final faq = _faqs[index];
              return _buildFAQCard(faq);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    final activaCount = _faqs.where((faq) => faq.estado).length;
    final inactivaCount = _faqs.length - activaCount;

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
          _buildStatItem('Total', _faqs.length.toString(), Icons.quiz),
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
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
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
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orden: ${faq.orden}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _cambiarEstado(faq),
                      icon: Icon(
                        faq.estado ? Icons.pause : Icons.play_arrow,
                        size: 20,
                      ),
                      color: faq.estado ? Colors.orange : Colors.green,
                      tooltip: faq.estado ? 'Desactivar' : 'Activar',
                    ),
                    IconButton(
                      onPressed: () => _navegarAEditarFAQ(context, faq),
                      icon: const Icon(Icons.edit, size: 20),
                      color: const Color(0xFFB71C1C),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      onPressed: () => _mostrarDialogoEliminar(context, faq),
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navegarACrearFAQ(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearFAQPage()),
    ).then((_) {
      _cargarFAQs(); // Recargar después de crear
    });
  }

  void _navegarAEditarFAQ(BuildContext context, FAQ faq) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditarFAQPage(faq: faq)),
    ).then((_) {
      _cargarFAQs(); // Recargar después de editar
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
              onPressed: () {
                Navigator.of(context).pop();
                _eliminarFAQ(faq);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}