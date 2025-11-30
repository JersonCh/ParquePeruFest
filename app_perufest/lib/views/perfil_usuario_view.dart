import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../services/perfil_service.dart';
import '../services/imgbb_service.dart';
import '../viewmodels/auth_viewmodel.dart';

class PerfilUsuarioView extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const PerfilUsuarioView({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<PerfilUsuarioView> createState() => _PerfilUsuarioViewState();
}

class _PerfilUsuarioViewState extends State<PerfilUsuarioView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _usuarioController;
  late TextEditingController _celularController;
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Variables para manejo de imagen de perfil
  File? _nuevaImagenPerfil;
  String? _urlImagenPerfil;
  bool _subiendoImagen = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.userData['username'] ?? widget.userData['usuario'] ?? '',
    );
    _usuarioController = TextEditingController(
      text: widget.userData['username'] ?? widget.userData['usuario'] ?? '',
    );
    _celularController = TextEditingController(
      text: widget.userData['telefono'] ?? widget.userData['celular'] ?? '',
    );
    
    // Inicializar URL de imagen de perfil
    _urlImagenPerfil = widget.userData['imagenPerfil'];
    
    // Cargar datos más actuales desde Firebase
    _cargarDatosActuales();
  }
  
  // Método para cargar los datos más actuales desde Firebase
  Future<void> _cargarDatosActuales() async {
    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('usuarios').doc(widget.userId).get();

      if (userDoc.exists) {
        final datosActualizados = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _usuarioController.text =
              datosActualizados['username']?.toString() ??
              datosActualizados['usuario']?.toString() ??
              '';
          _celularController.text =
              datosActualizados['telefono']?.toString() ??
              datosActualizados['celular']?.toString() ??
              '';
          // Actualizar la imagen de perfil con los datos más recientes
          _urlImagenPerfil = datosActualizados['imagenPerfil'];
        });
      }
    } catch (e) {
      print('Error cargando datos actuales: $e');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _usuarioController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  // Método para mostrar opciones de selección de imagen
  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            if (_urlImagenPerfil != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar imagen'),
                onTap: () {
                  Navigator.pop(context);
                  _eliminarImagenPerfil();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Método para seleccionar imagen de galería o cámara
  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (imagen != null) {
        setState(() {
          _nuevaImagenPerfil = File(imagen.path);
        });
        await _subirImagenPerfil();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para subir imagen a ImgBB y actualizar perfil
  Future<void> _subirImagenPerfil() async {
    if (_nuevaImagenPerfil == null) return;

    setState(() => _subiendoImagen = true);

    try {
      // Subir imagen a ImgBB
      final urlImagen = await ImgBBService.subirImagenPerfil(
        _nuevaImagenPerfil!,
        widget.userId,
      );

      if (urlImagen != null) {
        // Actualizar en Firestore
        final success = await PerfilService.actualizarImagenPerfil(
          widget.userId,
          urlImagen,
        );

        if (success) {
          setState(() {
            _urlImagenPerfil = urlImagen;
            _nuevaImagenPerfil = null;
          });

          // Actualizar el AuthViewModel para reflejar los cambios
          if (mounted) {
            final authViewModel = context.read<AuthViewModel>();
            await authViewModel.actualizarUsuario();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Imagen de perfil actualizada'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Error al guardar en la base de datos');
        }
      } else {
        throw Exception('Error al subir la imagen');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  // Método para eliminar imagen de perfil
  Future<void> _eliminarImagenPerfil() async {
    setState(() => _subiendoImagen = true);

    try {
      final success = await PerfilService.actualizarImagenPerfil(
        widget.userId,
        '', // Pasar string vacío para eliminar
      );

      if (success) {
        setState(() {
          _urlImagenPerfil = null;
          _nuevaImagenPerfil = null;
        });

        // Actualizar el AuthViewModel para reflejar los cambios
        if (mounted) {
          final authViewModel = context.read<AuthViewModel>();
          await authViewModel.actualizarUsuario();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Imagen de perfil eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error al eliminar de la base de datos');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _subiendoImagen = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final datos = {
      'username': _usuarioController.text.trim(),
      'telefono': _celularController.text.trim(),
    };

    final success = await PerfilService.actualizarDatosBasicos(
      widget.userId,
      datos,
    );

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos actualizados correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      // Recargar datos para refrescar la UI
      await Future.delayed(const Duration(milliseconds: 500)); // Pequeño delay
      await _recargarDatos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al actualizar los datos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isEditable = false,
    TextEditingController? controller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8B1B1B).withOpacity(0.1),
                    const Color(0xFFB91C1C).withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8B1B1B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing && isEditable && controller != null)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: controller,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8B1B1B),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          fillColor: const Color(0xFFF8FAFC),
                          filled: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Este campo es requerido';
                          }
                          return null;
                        },
                      ),
                    )
                  else
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con avatar elegante
            _buildElegantHeader(),
            
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de sección
                    Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarjetas de información
                    _buildInfoCard(
                      title: 'Nombre de Usuario',
                      subtitle: _usuarioController.text.isEmpty ? 'No especificado' : _usuarioController.text,
                      icon: Icons.person_rounded,
                      isEditable: true,
                      controller: _usuarioController,
                    ),
                    _buildInfoCard(
                      title: 'Correo Electrónico',
                      subtitle: widget.userData['email'] ?? 'No especificado',
                      icon: Icons.email_rounded,
                      isEditable: false,
                    ),
                    _buildInfoCard(
                      title: 'Número de Celular',
                      subtitle: _celularController.text.isEmpty ? 'No especificado' : _celularController.text,
                      icon: Icons.phone_rounded,
                      isEditable: true,
                      controller: _celularController,
                    ),
                    _buildInfoCard(
                      title: 'Rol en el Sistema',
                      subtitle: widget.userData['rol'] ?? 'Visitante',
                      icon: Icons.verified_user_rounded,
                      isEditable: false,
                    ),

                    const SizedBox(height: 40),

                    // Botones de acción elegantes
                    if (_isEditing) _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElegantHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B1B1B),
            Color(0xFFB91C1C),
            Color(0xFF8B1B1B),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // AppBar personalizada
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.person,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Mi Perfil',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_isEditing)
                    GestureDetector(
                      onTap: () => setState(() => _isEditing = true),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Avatar y información principal
            Stack(
              children: [
                // Avatar principal
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: Colors.white,
                    backgroundImage: (_nuevaImagenPerfil != null)
                        ? FileImage(_nuevaImagenPerfil!)
                        : (_urlImagenPerfil != null && _urlImagenPerfil!.isNotEmpty)
                            ? NetworkImage(_urlImagenPerfil!)
                            : null,
                    child: (_nuevaImagenPerfil == null && 
                           (_urlImagenPerfil == null || _urlImagenPerfil!.isEmpty))
                        ? Text(
                            (_usuarioController.text.isNotEmpty
                                    ? _usuarioController.text
                                    : 'U')
                                .toString()
                                .toUpperCase()[0],
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B1B1B),
                            ),
                          )
                        : null,
                  ),
                ),
                
                // Botón de editar imagen
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _subiendoImagen ? null : _mostrarOpcionesImagen,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B1B1B), Color(0xFFB91C1C)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: _subiendoImagen
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Información del usuario
            Text(
              _usuarioController.text.isNotEmpty
                  ? _usuarioController.text
                  : 'Usuario',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.userData['rol'] ?? 'Visitante',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _isEditing = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B1B1B).withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1B1B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Text(
                      'Guardar Cambios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _recargarDatos() async {
    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('usuarios').doc(widget.userId).get();

      if (userDoc.exists) {
        final datosActualizados = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _usuarioController.text =
              datosActualizados['username']?.toString() ??
              datosActualizados['usuario']?.toString() ??
              '';
          _celularController.text =
              datosActualizados['telefono']?.toString() ??
              datosActualizados['celular']?.toString() ??
              '';
          _urlImagenPerfil = datosActualizados['imagenPerfil'];
        });
      }
    } catch (e) {
      print('Error recargando datos: $e');
    }
  }
}
