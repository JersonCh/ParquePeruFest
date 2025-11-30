import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/evento.dart';
import '../viewmodels/eventos_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'visitante/evento_opciones_view.dart';
import 'perfil_usuario_view.dart';
import 'visitante/mapa_view.dart';
import 'visitante/faq_visitante_simple.dart';
import 'visitante/agenda_view.dart';
import 'visitante/noticias_visitante_view.dart';
import '../widgets/banner_anuncios.dart';

class DashboardUserView extends StatefulWidget {
  const DashboardUserView({super.key});

  @override
  State<DashboardUserView> createState() => _DashboardUserViewState();
}

class _DashboardUserViewState extends State<DashboardUserView> {
    Widget _buildEventosList(List<Evento> eventos) {
      // Filtrar solo eventos activos
      final eventosActivos = eventos.where((e) => e.estado == 'activo').toList();

      return Column(
        children: List.generate(eventosActivos.length, (index) {
          final evento = eventosActivos[index];
          final color = _eventoColors[index % _eventoColors.length];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildEventoCard(evento, color),
          );
        }),
      );
    }
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Color> _eventoColors = [
    const Color(0xFFBEE3DB), // Verde pastel
    const Color(0xFFF6D6D6), // Rosa claro
    const Color(0xFFF7F7FF), // Blanco suave
    const Color(0xFFE2ECEC), // Celeste pastel
    const Color(0xFFF0EFEB), // Gris claro
    const Color(0xFFF7D9C4), // Naranja pastel
    const Color(0xFFD6E2E9), // Azul pastel
    const Color(0xFFF1F1F1), // Gris muy claro
    const Color(0xFFEDEDED), // Gris claro
    const Color(0xFFF9F9F9), // Blanco casi puro
    const Color(0xFFE3F6F5), // Verde agua
    const Color(0xFFFDE2E4), // Rosa muy claro
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEventos();
    });
  }

  Future<void> _cargarEventos() async {
    final eventosViewModel = context.read<EventosViewModel>();
    await eventosViewModel.cargarEventos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FF), // Fondo claro modo día
      body: Column(
        children: [
          // Banner único global - aparece en todas las pestañas
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF7F7FF),
                  Color(0xFFE3F6F5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.07),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const BannerAnuncios(
              padding: EdgeInsets.zero,
            ),
          ),
          // Encabezado movido dentro de la página de Eventos (_buildEventosPage)
          // Contenido principal con PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildEventosPage(),
                const NoticiasVisitanteView(),
                _buildMapaPage(),
                const AgendaView(),
                const FAQVisitanteSimple(),
                _buildPerfilPage()
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildEventosPage() {
    return Consumer<EventosViewModel>(
      builder: (context, eventosViewModel, child) {
        // Mostrar el encabezado principal siempre dentro de la página de Eventos
        // y luego el contenido según el estado (loading / empty / lista).
        if (eventosViewModel.isLoading) {
          return ListView(
            padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
            children: [
              _buildMainHeader(),
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          );
        } else if (eventosViewModel.eventos.isEmpty) {
          return ListView(
            padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
            children: [
              _buildMainHeader(),
              _buildEmptyState(),
            ],
          );
        } else {
          return ListView(
            padding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
            children: [
              _buildMainHeader(),
              const SizedBox(height: 16),
              _buildEventosList(eventosViewModel.eventos),
            ],
          );
        }
      },
    );
  }

  Widget _buildMainHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 24),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 122, 0, 37),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Colors.white.withOpacity(0.9),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bienvenido al',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.celebration,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PerúFest 2025',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Descubre eventos únicos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140.0,
      floating: false,
      pinned: true,
      snap: false,
      stretch: false,
      backgroundColor: const Color.fromARGB(255, 122, 0, 37),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.12),
      forceElevated: true,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Colors.white.withOpacity(0.9),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bienvenido al',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Descubre eventos únicos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.celebration,
                  color: Colors.white.withOpacity(0.9),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'PerúFest 2025',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color.fromARGB(255, 122, 0, 37),
              Color.fromARGB(255, 140, 0, 45),
            ],
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/fondo.jpg'),
            fit: BoxFit.cover,
            opacity: 0.08,
          ),
        ),
      ),
    );
  }

  Widget _buildEventoCard(Evento evento, Color color) {
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final inicioEvento = DateTime(
      evento.fechaInicio.year,
      evento.fechaInicio.month,
      evento.fechaInicio.day,
    );
    final finEvento = DateTime(
      evento.fechaFin.year,
      evento.fechaFin.month,
      evento.fechaFin.day,
    );

    String estadoTexto = '';
    Color estadoColor = const Color(0xFF6B7280);

    if (hoy.isAtSameMomentAs(inicioEvento) ||
        (hoy.isAfter(inicioEvento) && hoy.isBefore(finEvento)) ||
        hoy.isAtSameMomentAs(finEvento)) {
      return Material(
        color: Colors.transparent,
        elevation: 3,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _verActividadesEvento(evento),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withOpacity(0.13),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen más compacta
                if (evento.imagenUrl.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      child: Image.network(
                        evento.imagenUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        ),
                      ),
                    ),
                  ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría pill elegante y botón flecha alineados arriba
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 122, 0, 37), // Guinda
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.circle, color: color.withOpacity(0.7), size: 8),
                                const SizedBox(width: 5),
                                Text(
                                  evento.categoria,
                                  style: TextStyle(
                                    color: Colors.white, // Blanco
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (estadoTexto.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 122, 0, 37), // Guinda
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                estadoTexto,
                                style: const TextStyle(
                                  color: Colors.white, // Blanco
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF4A4E69),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Título más compacto
                      Text(
                        evento.nombre,
                        style: const TextStyle(
                          color: Color(0xFF22223B),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      
                      // Información solo con fechas, estilo minimalista
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.calendar_today_outlined, color: const Color(0xFF4A4E69), size: 15),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Fechas', style: TextStyle(color: Color(0xFF4A4E69), fontSize: 11, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 1),
                                Text(
                                  '${_formatearFecha(evento.fechaInicio)} - ${_formatearFecha(evento.fechaFin)}',
                                  style: const TextStyle(color: Color(0xFF22223B), fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ...footer eliminado, flecha ahora arriba...
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Si el evento no está activo, retorna un widget vacío o alternativo
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay eventos disponibles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los eventos aparecerán aquí cuando estén disponibles',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarEventos,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 122, 0, 37),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildPerfilPage() {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no encontrado'));
    }

    return PerfilUsuarioView(
      userId: currentUser.id,
      userData: {
        'username': currentUser.username,
        'email': currentUser.correo,
        'telefono': currentUser.telefono,
        'rol': currentUser.rol,
        'imagenPerfil': currentUser.imagenPerfil,
      },
    );
  }

  Widget _buildMapaPage() {
    return const MapaView();
  }

  Widget _buildBottomNavigation() {
      // Colores para la barra inferior
      const colorActiveBg = Color(0xFF1A2233); // Azul oscuro para fondo activo
      const colorActiveIcon = Colors.white; // Blanco para ícono/texto activo
      const colorInactive = Color(0xFF6B7280); // Gris para los inactivos
    final items = [
      {'icon': Icons.celebration_outlined, 'activeIcon': Icons.celebration, 'label': 'Eventos'},
      {'icon': Icons.article_outlined, 'activeIcon': Icons.article, 'label': 'Noticias'},
      {'icon': Icons.map_outlined, 'activeIcon': Icons.map, 'label': 'Mapa'},
      {'icon': Icons.event_note_outlined, 'activeIcon': Icons.event_note, 'label': 'Agenda'},
      {'icon': Icons.more_horiz, 'activeIcon': Icons.more_horiz, 'label': 'Más'},
    ];

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white, // Fondo claro
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE2E8F0).withOpacity(0.7),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int index = 0; index < items.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (index == 4) {
                    // Abrir menú modal con opciones extra
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F7FB),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedIndex = 4;
                                });
                                _pageController.animateToPage(4, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    const Icon(Icons.help_center_outlined, color: Color(0xFF64748B)),
                                    const SizedBox(width: 18),
                                    const Text('FAQ', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedIndex = 5;
                                });
                                _pageController.animateToPage(5, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                                    const SizedBox(width: 18),
                                    const Text('Perfil', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _mostrarMenuCerrarSesion();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout, color: Color(0xFF64748B)),
                                    const SizedBox(width: 18),
                                    const Text('Salir', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _selectedIndex = index;
                  });
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _selectedIndex == index ? 36 : 0,
                          height: _selectedIndex == index ? 36 : 0,
                          decoration: BoxDecoration(
                            color: _selectedIndex == index ? colorActiveBg : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Icon(
                          _selectedIndex == index ? items[index]['activeIcon'] as IconData : items[index]['icon'] as IconData,
                          color: _selectedIndex == index ? colorActiveIcon : colorInactive,
                          size: _selectedIndex == index ? 20 : 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: _selectedIndex == index ? colorActiveBg : colorInactive,
                        fontWeight: _selectedIndex == index ? FontWeight.w700 : FontWeight.w500,
                        fontSize: _selectedIndex == index ? 13 : 11,
                        letterSpacing: _selectedIndex == index ? 0.3 : 0.2,
                      ),
                      child: Text(items[index]['label'] as String),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarMenuCerrarSesion() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(Icons.logout, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text(
                  '¿Cerrar Sesión?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Se cerrará tu sesión y regresarás a la pantalla de inicio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _cerrarSesion();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _cerrarSesion() async {
    final authViewModel = context.read<AuthViewModel>();
    authViewModel.logout();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _verActividadesEvento(Evento evento) {
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser?.id ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EventoOpcionesView(evento: evento, userId: currentUserId),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}
