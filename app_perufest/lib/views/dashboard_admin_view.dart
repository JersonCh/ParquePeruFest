import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin/noticias_page.dart';
import 'admin/eventos_page.dart';
import 'admin/actividades_page.dart';
import 'admin/stands_page.dart';
import 'admin/anuncios_main_page.dart';
import 'admin/faq_admin_simple.dart';
import 'admin/mapa_admin_view.dart';
import 'admin/estadisticas_page.dart';
import 'perfil_administrador_view.dart';
import '../viewmodels/auth_viewmodel.dart';

class DashboardAdminView extends StatefulWidget {
  const DashboardAdminView({super.key});

  @override
  State<DashboardAdminView> createState() => _DashboardAdminViewState();
}

class _DashboardAdminViewState extends State<DashboardAdminView> {
  int _currentIndex = 0;

  // Títulos para cada sección
  final List<String> _titles = [
    'Gestión de Noticias',
    'Gestión de Eventos',
    'Gestión de Actividades',
    'Gestión de Stands',
    'Gestión de Anuncios',
    'Gestión de FAQs',
    'Gestión de Zonas',
    'Estadísticas',
    'Mi Perfil',
  ];

  // Lista de páginas para cada sección
  final List<Widget> _pages = [
    const NoticiasPage(),
    const EventosPage(),
    const ActividadesPage(),
    const StandsPage(),
    const AnunciosMainPage(),
    const FAQAdminSimple(),
    const MapaAdminView(),
    const EstadisticasPage(),
  ];

  Widget _buildPerfilPage() {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Error: Usuario no encontrado'));
    }

    return PerfilAdministradorView(
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

  void _onMenuItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context); // Cierra el drawer
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthViewModel>().logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUser = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF8B1B1B),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: currentUser?.imagenPerfil != null
                        ? NetworkImage(currentUser!.imagenPerfil!)
                        : null,
                    child: currentUser?.imagenPerfil == null
                        ? const Icon(Icons.person, size: 35, color: Color(0xFF8B1B1B))
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser?.username ?? 'Administrador',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    currentUser?.correo ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.article,
              title: 'Noticias',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.event,
              title: 'Eventos',
              index: 1,
            ),
            _buildDrawerItem(
              icon: Icons.local_activity,
              title: 'Actividades',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.store,
              title: 'Stands',
              index: 3,
            ),
            _buildDrawerItem(
              icon: Icons.campaign,
              title: 'Anuncios',
              index: 4,
            ),
            _buildDrawerItem(
              icon: Icons.help_center,
              title: 'FAQs',
              index: 5,
            ),
            _buildDrawerItem(
              icon: Icons.map,
              title: 'Zonas',
              index: 6,
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.bar_chart,
              title: 'Estadísticas',
              index: 7,
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Mi Perfil',
              index: 8,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _currentIndex == 8 ? _buildPerfilPage() : _pages[_currentIndex],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF8B1B1B) : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF8B1B1B) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF8B1B1B).withOpacity(0.1),
      onTap: () => _onMenuItemTapped(index),
    );
  }
}
