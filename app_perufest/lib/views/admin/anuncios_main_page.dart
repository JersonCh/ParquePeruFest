import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/anuncios_viewmodel.dart';
import '../../models/anuncio.dart';
import 'crear_anuncio_page.dart';
import 'editar_anuncio_page.dart';

class AnunciosMainPage extends StatefulWidget {
  const AnunciosMainPage({super.key});

  @override
  State<AnunciosMainPage> createState() => _AnunciosMainPageState();
}

class _AnunciosMainPageState extends State<AnunciosMainPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnunciosViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Anuncios'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AnunciosViewModel>(
        builder: (context, anunciosViewModel, child) {
          if (anunciosViewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando anuncios...'),
                ],
              ),
            );
          }

          if (anunciosViewModel.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar anuncios',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anunciosViewModel.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => anunciosViewModel.initialize(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (anunciosViewModel.anuncios.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No hay anuncios creados',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crea tu primer anuncio tocando el botón +',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              anunciosViewModel.initialize();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: anunciosViewModel.anuncios.length,
              itemBuilder: (context, index) {
                final anuncio = anunciosViewModel.anuncios[index];
                return _buildAnuncioCard(anuncio, anunciosViewModel);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCrearAnuncio(),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Anuncio'),
      ),
    );
  }

  Widget _buildAnuncioCard(Anuncio anuncio, AnunciosViewModel anunciosViewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: anuncio.activo 
                ? const Color(0xFF4CAF50)
                : Colors.grey[400],
              child: Icon(
                anuncio.activo ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              anuncio.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  anuncio.contenido,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.place, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Posición: ${anuncio.posicion}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.date_range, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${anuncio.fechaInicio.day}/${anuncio.fechaInicio.month}/${anuncio.fechaInicio.year} - ${anuncio.fechaFin.day}/${anuncio.fechaFin.month}/${anuncio.fechaFin.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (anuncio.imagenUrl != null) ...[
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  anuncio.imagenUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[100],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToEditarAnuncio(anuncio),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[600],
                      side: BorderSide(color: Colors.orange[600]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleActivo(anuncio, anunciosViewModel),
                    icon: Icon(
                      anuncio.activo ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                    ),
                    label: Text(anuncio.activo ? 'Desactivar' : 'Activar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: anuncio.activo ? Colors.grey[600] : Colors.green[600],
                      side: BorderSide(
                        color: anuncio.activo ? Colors.grey[600]! : Colors.green[600]!,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _eliminarAnuncio(anuncio, anunciosViewModel),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Eliminar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[600]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCrearAnuncio() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CrearAnuncioPage()),
    );
    
    if (resultado == true) {
      context.read<AnunciosViewModel>().initialize();
    }
  }

  void _navigateToEditarAnuncio(Anuncio anuncio) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarAnuncioPage(anuncio: anuncio),
      ),
    );
    
    if (resultado == true) {
      context.read<AnunciosViewModel>().initialize();
    }
  }

  Future<void> _toggleActivo(Anuncio anuncio, AnunciosViewModel anunciosViewModel) async {
    try {
      final resultado = await anunciosViewModel.cambiarEstadoAnuncio(
        anuncio.id, 
        !anuncio.activo
      );
      
      if (resultado && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Anuncio ${anuncio.activo ? 'desactivado' : 'activado'} exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarAnuncio(Anuncio anuncio, AnunciosViewModel anunciosViewModel) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de eliminar el anuncio "${anuncio.titulo}"?'),
            const SizedBox(height: 8),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      try {
        final resultado = await anunciosViewModel.eliminarAnuncio(anuncio.id);
        if (resultado && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anuncio eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}