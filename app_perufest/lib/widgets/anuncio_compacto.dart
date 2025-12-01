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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: () => _mostrarDetalleAnuncio(context, anuncio),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de patrocinio elegante
              if (mostrarPatrocinado) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.campaign_rounded,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Patrocinado',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Contenido principal elegante
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen mejorada
                  if (anuncio.imagenUrl != null)
                    Container(
                      width: 72,
                      height: 72,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          anuncio.imagenUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.image_rounded,
                              color: Colors.grey.shade400,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Contenido de texto mejorado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anuncio.titulo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF111827),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          anuncio.contenido,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Badge de acción sutil
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ver más',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Icono de acción elegante
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade500,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDetalleAnuncio(BuildContext context, Anuncio anuncio) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header elegante
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Contenido Patrocinado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade500,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade50,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Título
              Text(
                anuncio.titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Imagen si existe
              if (anuncio.imagenUrl != null) ...[
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      anuncio.imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(
                          Icons.image_rounded,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Contenido
              Text(
                anuncio.contenido,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Footer con fecha
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Válido hasta: ${_formatearFecha(anuncio.fechaFin)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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