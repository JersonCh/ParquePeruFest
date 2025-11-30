import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/anuncios_viewmodel.dart';
import 'editar_anuncio_page.dart';

class ListaAnunciosPage extends StatefulWidget {
  const ListaAnunciosPage({super.key});

  @override
  State<ListaAnunciosPage> createState() => _ListaAnunciosPageState();
}

class _ListaAnunciosPageState extends State<ListaAnunciosPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnunciosViewModel>().initialize();
    });
  }

  Future<void> _toggleActivo(anuncio, AnunciosViewModel anunciosViewModel) async {
    try {
      final resultado = await anunciosViewModel.cambiarEstadoAnuncio(anuncio.id, !anuncio.activo);
      
      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anuncio ${anuncio.activo ? 'desactivado' : 'activado'} exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar estado del anuncio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarAnuncio(anuncio, AnunciosViewModel anunciosViewModel) async {
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
        if (resultado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anuncio eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el anuncio'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editarAnuncio(anuncio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarAnuncioPage(anuncio: anuncio),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Anuncios'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AnunciosViewModel>().initialize(),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<AnunciosViewModel>(
        builder: (context, anunciosViewModel, child) {
          if (anunciosViewModel.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B1B1B)),
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
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      anunciosViewModel.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => anunciosViewModel.initialize(),
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
            );
          }

          if (anunciosViewModel.anuncios.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No hay anuncios',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu primer anuncio desde el formulario',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: anunciosViewModel.anuncios.length,
            itemBuilder: (context, index) {
              final anuncio = anunciosViewModel.anuncios[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: anuncio.activo ? Colors.green : Colors.grey,
                        child: Icon(
                          anuncio.activo ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        anuncio.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(anuncio.contenido, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.place, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                'Posición: ${anuncio.posicion}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${anuncio.fechaInicio.day}/${anuncio.fechaInicio.month}/${anuncio.fechaInicio.year} - ${anuncio.fechaFin.day}/${anuncio.fechaFin.month}/${anuncio.fechaFin.year}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                    
                    if (anuncio.imagenUrl != null) 
                      Container(
                        height: 120,
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            anuncio.imagenUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              Container(
                                color: Colors.grey.shade100,
                                child: const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                          ),
                        ),
                      ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editarAnuncio(anuncio),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Editar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
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
                                foregroundColor: anuncio.activo ? Colors.grey : Colors.green,
                                side: BorderSide(color: anuncio.activo ? Colors.grey : Colors.green),
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
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}