import 'package:flutter/material.dart';
import '../../models/evento.dart';
import 'actividades_evento_view.dart';
import 'stands_evento_view.dart';
import 'pdf_viewer_page.dart';

class EventoOpcionesView extends StatelessWidget {
  final Evento evento;
  final String userId;

  const EventoOpcionesView({
    super.key,
    required this.evento,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stack con imagen y botones
            Stack(
              children: [
                // Imagen del evento
                Container(
                  height: 320, // Incrementado para hacer la imagen más alta
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: evento.imagenUrl.isNotEmpty
                          ? NetworkImage(evento.imagenUrl)
                          : const AssetImage('assets/images/placeholder.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Botón de regreso
                Positioned(
                  top: 32,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.85),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Botón de favorito (corazón)
                Positioned(
                  top: 40,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white, size: 20),
                      onPressed: () {
                        // Acción de favorito
                      },
                    ),
                  ),
                ),
              ],
            ),

            // Contenedor blanco con bordes redondeados superiores
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              transform: Matrix4.translationValues(0, -24, 0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del evento
                    Text(
                      evento.nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Organizador
                    Text(
                      'Organizado por: ${evento.organizador}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Grid de información (2 columnas)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.calendar_today_outlined,
                            title: '${_formatearFechaCompacta(evento.fechaInicio)} - ${_formatearFechaCompacta(evento.fechaFin)}, ${evento.fechaInicio.year}',
                            subtitle: '${evento.horaInicioFormateada} - ${evento.horaFinFormateada}',
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.location_on_outlined,
                            title: evento.lugar,
                            subtitle: 'Tacna, Perú',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Segunda fila del grid
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.wine_bar_outlined,
                            title: evento.tipoEvento,
                            subtitle: 'Tipo de evento',
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.confirmation_number_outlined,
                            title: evento.categoria,
                            subtitle: 'Categoría',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Divisor
                    Divider(
                      thickness: 1.5, // Incrementado para que la línea sea más visible
                      color: const Color.fromARGB(255, 211, 209, 209), // Color ajustado para mayor contraste
                      height: 1, // Reducido para disminuir la separación
                    ),
                    const SizedBox(height: 24),

                    // Sección "Acerca del Evento"
                    const Text(
                      'Acerca del Evento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            evento.descripcion,
                            style: const TextStyle(
                              fontSize: 14, // Ajustado para coincidir con la segunda imagen
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Título "¿Qué deseas explorar?"
                    const Text(
                      '¿Qué deseas explorar?',
                      style: TextStyle(
                        fontSize: 18, // Ajustado para coincidir con "Acerca del Evento"
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B1B1B), // Color guinda
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Cards de Actividades y Stands
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/actividades.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildOpcionCard(
                            context: context,
                            icon: Icons.event,
                            title: 'Actividades',
                            subtitle: 'Ver todas las actividades del evento',
                            color: Colors.transparent, // Fondo transparente para mostrar la imagen
                            onTap: () => _navegarAActividades(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/stands.jpg'),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildOpcionCard(
                            context: context,
                            icon: Icons.store,
                            title: 'Stands',
                            subtitle: 'Explora los stands y empresas participantes',
                            color: Colors.transparent, // Fondo transparente para mostrar la imagen
                            onTap: () => _navegarAStands(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón de información adicional (restaurado)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: Text(
                          _tienePDF() ? 'Ver información adicional' : 'Sin información adicional',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _tienePDF() ? const Color(0xFF8B1B1B) : Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _tienePDF() ? () => _abrirPDF(context) : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 218, 218, 218),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF666666)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOpcionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Iconos decorativos de fondo
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                icon,
                size: 100,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            Positioned(
              left: -10,
              top: -10,
              child: Icon(
                icon,
                size: 60,
                color: Colors.white.withOpacity(0.1),
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 28, color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Explorar',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white.withOpacity(0.95),
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatearFechaCompacta(DateTime fecha) {
    const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 
                   'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${fecha.day} ${meses[fecha.month - 1]}';
  }

  void _navegarAActividades(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActividadesEventoView(evento: evento, userId: userId),
      ),
    );
  }

  void _navegarAStands(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StandsEventoView(evento: evento)),
    );
  }

  bool _tienePDF() {
    if (evento.pdfUrl != null && evento.pdfUrl!.isNotEmpty) {
      return true;
    }
    return evento.pdfBase64 != null && evento.pdfBase64!.isNotEmpty;
  }

  Future<void> _abrirPDF(BuildContext context) async {
    if (evento.pdfUrl != null && evento.pdfUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(
            pdfUrl: evento.pdfUrl!,
            fileName: evento.pdfNombre ?? 'documento_${evento.nombre}.pdf',
          ),
        ),
      );
    } else if (evento.pdfBase64 != null && evento.pdfBase64!.isNotEmpty) {
      _abrirPDFDesdeBase64(context);
    }
  }

  Future<void> _abrirPDFDesdeBase64(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este documento usa el formato antiguo. Por favor, pide al administrador que lo actualice.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}