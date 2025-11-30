import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/anuncios_viewmodel.dart';
import '../models/anuncio.dart';

/// Widget compacto para mostrar anuncios entre contenido sin interrumpir la experiencia
class AnuncioCompacto extends StatelessWidget {
  final String zona; // 'eventos', 'actividades', 'noticias', 'general'
  final int indicePosicion; // Para determinar cuándo mostrar un anuncio
  final EdgeInsetsGeometry margin;
  final bool mostrarPatrocinado;

  const AnuncioCompacto({
    super.key,
    required this.zona,
    required this.indicePosicion,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
    this.mostrarPatrocinado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnunciosViewModel>(
      builder: (context, anunciosVM, child) {
        // Solo mostrar anuncios cada 4 elementos para no saturar
        if (indicePosicion % 4 != 0) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Anuncio>>(
          future: anunciosVM.obtenerAnunciosParaZona(zona),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final anuncios = snapshot.data!;
            
            // Filtrar anuncios de debug/prueba
            final anunciosFiltrados = anuncios.where((anuncio) {
              final titulo = anuncio.titulo.toLowerCase();
              return !titulo.contains('debug') && 
                     !titulo.contains('garantizado') && 
                     !titulo.contains('prueba') &&
                     !titulo.contains('test');
            }).toList();
            
            if (anunciosFiltrados.isEmpty) {
              return const SizedBox.shrink();
            }
            
            // Seleccionar anuncio basado en la posición para variedad
            final anuncio = anunciosFiltrados[indicePosicion % anunciosFiltrados.length];

            return Container(
              margin: margin,
              child: _buildAnuncioCard(context, anuncio),
            );
          },
        );
      },
    );
  }

  Widget _buildAnuncioCard(BuildContext context, Anuncio anuncio) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalleAnuncio(context, anuncio),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade50,
                Colors.orange.shade100.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de patrocinio (opcional)
              if (mostrarPatrocinado) ...[
                Row(
                  children: [
                    Icon(
                      Icons.local_offer,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'PATROCINADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Contenido principal
              Row(
                children: [
                  // Imagen si existe
                  if (anuncio.imagenUrl != null)
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(anuncio.imagenUrl!),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anuncio.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          anuncio.contenido,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Flecha
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleAnuncio(BuildContext context, Anuncio anuncio) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_offer, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'CONTENIDO PATROCINADO',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              anuncio.titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (anuncio.imagenUrl != null)
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(anuncio.imagenUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              anuncio.contenido,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Válido hasta: ${_formatearFecha(anuncio.fechaFin)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${fecha.day} ${meses[fecha.month - 1]} ${fecha.year}';
  }
}