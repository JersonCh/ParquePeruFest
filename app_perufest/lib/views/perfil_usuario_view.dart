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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 122, 0, 37).withOpacity(0.15),
                    const Color.fromARGB(255, 122, 0, 37).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: const Color.fromARGB(255, 122, 0, 37),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                              color: Color.fromARGB(255, 122, 0, 37),
                              width: 2,
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
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      width: double.infinity,
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
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
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con avatar elegante
            _buildElegantHeader(),
            
            // Contenido principal más compacto
            Transform.translate(
              offset: const Offset(0, -15),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de sección elegante
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INFORMACIÓN PERSONAL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color.fromARGB(255, 122, 0, 37),
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: const Offset(0, 0.5),
                                    blurRadius: 2,
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 1.5,
                              width: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 122, 0, 37),
                                    const Color.fromARGB(255, 122, 0, 37).withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(0.75),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Sección de datos personales
                        _buildSectionTitle('Datos de Acceso', Icons.account_circle_outlined),
                        const SizedBox(height: 12),
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
                        
                        const SizedBox(height: 16),
                        _buildSectionTitle('Información de Contacto', Icons.contact_phone_outlined),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          title: 'Número de Celular',
                          subtitle: _celularController.text.isEmpty ? 'No especificado' : _celularController.text,
                          icon: Icons.phone_rounded,
                          isEditable: true,
                          controller: _celularController,
                        ),


                        const SizedBox(height: 20),

                        // Botones de acción elegantes
                        if (_isEditing) 
                          Container(
                            padding: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: _buildActionButtons(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
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
            Color.fromARGB(255, 122, 0, 37),
            Color(0xFF8B1B1B),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // AppBar personalizada
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'MI PERFIL',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 2.5,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.3),
                              ),
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 1,
                          width: 60,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditing)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(
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
                  width: 100,
                  height: 100,
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
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 122, 0, 37),
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
            
            // Información del usuario con estilo elegante
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                (_usuarioController.text.isNotEmpty
                    ? _usuarioController.text
                    : 'Usuario').toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 3),
                      blurRadius: 6,
                      color: Colors.black45,
                    ),
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 12,
                      color: Colors.black26,
                    ),
                  ],
                ),
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
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
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
                  color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.35),
                  offset: const Offset(0, 4),
                  blurRadius: 14,
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
                backgroundColor: const Color.fromARGB(255, 122, 0, 37),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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
                      'GUARDAR CAMBIOS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 122, 0, 37).withOpacity(0.08),
            const Color.fromARGB(255, 122, 0, 37).withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color.fromARGB(255, 122, 0, 37),
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color.fromARGB(255, 122, 0, 37),
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  offset: const Offset(0, 0.5),
                  blurRadius: 1,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ],
      ),
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
