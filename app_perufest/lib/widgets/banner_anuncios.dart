import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/anuncio.dart';

class BannerAnuncios extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  
  const BannerAnuncios({
    super.key,
    this.padding,
  });

  @override
  State<BannerAnuncios> createState() => _BannerAnunciosState();
}

class _BannerAnunciosState extends State<BannerAnuncios> {
  Timer? _rotationTimer;
  int _currentIndex = 0;
  List<Anuncio> _anunciosActivos = [];
  Stream<QuerySnapshot>? _anunciosStream; // Cache del stream

  @override
  void initState() {
    super.initState();
    // Inicializar stream una sola vez - ahora sin filtro por posición
    _anunciosStream = FirebaseFirestore.instance
        .collection('anuncios')
        .where('activo', isEqualTo: true)
        .snapshots();
    _iniciarRotacion();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  void _iniciarRotacion() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (_anunciosActivos.isNotEmpty && mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _anunciosActivos.length;
        });
      }
    });
  }

  void _actualizarAnuncios(List<Anuncio> nuevosAnuncios) {
    if (mounted) {
      setState(() {
        _anunciosActivos = nuevosAnuncios;
        if (_currentIndex >= _anunciosActivos.length) {
          _currentIndex = 0;
        }
      });
      
      // Reiniciar timer si hay cambios en los anuncios
      if (nuevosAnuncios.isNotEmpty) {
        _iniciarRotacion();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _anunciosStream, // Usar stream cacheado
      builder: (context, snapshot) {
        // Manejar estado de loading sin mostrar/ocultar
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Si ya tenemos anuncios, mostrarlos mientras carga
          if (_anunciosActivos.isNotEmpty) {
            final anuncioActual = _anunciosActivos[_currentIndex % _anunciosActivos.length];
            return _buildBannerContent(anuncioActual);
          }
          // Si no, mostrar un placeholder sin parpadear
          return Container(
            height: 50,
            margin: widget.padding ?? const EdgeInsets.all(8),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final docs = snapshot.data!.docs;
        
        // Filtrar por vigencia - ahora sin filtro por posición
        final ahora = DateTime.now();
        print('🔍 BannerAnuncios: Verificando ${docs.length} anuncios activos');
        
        final anunciosVigentes = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          try {
            final fechaInicio = (data['fechaInicio'] as Timestamp).toDate();
            final fechaFin = (data['fechaFin'] as Timestamp).toDate();
            final titulo = data['titulo']?.toString().toLowerCase() ?? '';
            final activo = data['activo'] == true;
            
            print('📝 Evaluando anuncio: $titulo');
            print('   ✅ Activo: $activo');
            print('   📅 Inicio: $fechaInicio');
            print('   📅 Fin: $fechaFin');
            print('   ⏰ Ahora: $ahora');
            
            // Verificar que esté activo (ya filtrado en query pero verificamos por seguridad)
            if (!activo) {
              print('   ❌ No está activo');
              return false;
            }
            
            // Verificar vigencia
            final vigente = ahora.isAfter(fechaInicio) && ahora.isBefore(fechaFin);
            if (!vigente) {
              print('   ❌ No está vigente');
              return false;
            }
            
            // Excluir anuncios de debug/prueba (TEMPORALMENTE DESHABILITADO PARA PRUEBAS)
            // final esDebug = titulo.contains('debug') || titulo.contains('garantizado') || titulo.contains('prueba') || titulo.contains('test');
            
            print('   ✅ Anuncio válido para mostrar');
            return true;
          } catch (e) {
            print('   ❌ Error procesando anuncio: $e');
            return false;
          }
        }).toList();
        
        if (anunciosVigentes.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Convertir a objetos Anuncio para compatibilidad
        final anuncios = anunciosVigentes.map((doc) {
          try {
            return Anuncio.fromFirestore(doc);
          } catch (e) {
            return null;
          }
        }).where((anuncio) => anuncio != null).cast<Anuncio>().toList();
        
        if (anuncios.isEmpty) {
          return const SizedBox.shrink();
        }

        // Solo actualizar si la lista cambió realmente
        if (_anunciosActivos.length != anuncios.length || 
            !_listasIguales(_anunciosActivos, anuncios)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _actualizarAnuncios(anuncios);
          });
        }

        final anuncioActual = anuncios[_currentIndex % anuncios.length];
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _buildBannerContent(anuncioActual),
        );
      },
    );
  }

  Widget _buildBannerContent(Anuncio anuncio) {
    return Container(
      key: ValueKey(anuncio.id),
      width: double.infinity,
      height: 76, // Altura ajustada para evitar overflow
      margin: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3), // Color beige/crema más claro como en la imagen
        borderRadius: BorderRadius.circular(16), // Bordes más redondeados
        border: Border.all(
          color: const Color(0xFFE8D5B7), // Borde sutil
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _mostrarDetalleAnuncio(anuncio),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Padding reducido
            child: Row(
              children: [
                // Icono de patrocinado - más grande y estilizado
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39C12), // Color naranja para el icono
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF39C12).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_offer,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Contenido del anuncio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Evita overflow
                    children: [
                      // Badge de patrocinado más elegante
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF39C12), // Color naranja
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'PATROCINADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Título más prominente
                      Text(
                        anuncio.titulo,
                        style: const TextStyle(
                          color: Color(0xFF2C3E50), // Color de texto oscuro
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (anuncio.contenido.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          anuncio.contenido,
                          style: const TextStyle(
                            color: Color(0xFF7F8C8D), // Color de texto gris
                            fontSize: 12,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Sección derecha con indicadores y flecha
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Indicador de múltiples anuncios - más visible
                    if (_anunciosActivos.length > 1)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _anunciosActivos.length.clamp(0, 4), // Máximo 4 puntos
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentIndex
                                  ? const Color(0xFFF39C12)
                                  : const Color(0xFFF39C12).withOpacity(0.3),
                              boxShadow: index == _currentIndex ? [
                                BoxShadow(
                                  color: const Color(0xFFF39C12).withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                      ),
                    if (_anunciosActivos.length > 1) const SizedBox(height: 8),
                    // Flecha indicativa más elegante
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C3E50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: const Color(0xFF2C3E50).withOpacity(0.7),
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

  void _mostrarDetalleAnuncio(Anuncio anuncio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFF8B1B1B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                anuncio.titulo,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (anuncio.imagenUrl != null)
              Container(
                width: double.infinity,
                height: 150,
                margin: const EdgeInsets.only(bottom: 16),
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
            const SizedBox(height: 16),
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
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  // Método auxiliar para comparar listas de anuncios
  bool _listasIguales(List<Anuncio> lista1, List<Anuncio> lista2) {
    if (lista1.length != lista2.length) return false;
    for (int i = 0; i < lista1.length; i++) {
      if (lista1[i].id != lista2[i].id) return false;
    }
    return true;
  }
}