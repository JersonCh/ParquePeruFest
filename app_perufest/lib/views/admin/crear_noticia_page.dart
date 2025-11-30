import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../viewmodels/noticias_viewmodel.dart';

class CrearNoticiaPage extends StatefulWidget {
  const CrearNoticiaPage({super.key});

  @override
  State<CrearNoticiaPage> createState() => _CrearNoticiaPageState();
}

class _CrearNoticiaPageState extends State<CrearNoticiaPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _textoCortoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _enlaceExternoController = TextEditingController();
  
  File? _imagenSeleccionada;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _tituloController.dispose();
    _textoCortoController.dispose();
    _descripcionController.dispose();
    _enlaceExternoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Noticia', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF8B1B1B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Consumer<NoticiasViewModel>(
            builder: (context, viewModel, child) {
              return TextButton(
                onPressed: (_isLoading || viewModel.isLoading) ? null : _guardarNoticia,
                child: const Text(
                  'PUBLICAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<NoticiasViewModel>(
        builder: (context, viewModel, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicador de carga mejorado
                  if (viewModel.isLoading || _isLoading)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B1B1B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B1B1B).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF8B1B1B)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoading ? 'Subiendo imagen...' : 'Publicando noticia...',
                                  style: TextStyle(
                                    color: const Color(0xFF8B1B1B),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Por favor espera un momento',
                                  style: TextStyle(
                                    color: const Color(0xFF8B1B1B).withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Card para el formulario principal
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header del formulario
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B1B1B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.create,
                                  color: const Color(0xFF8B1B1B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Información de la Noticia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),

                          // Título
                          _buildSectionTitle('Título *'),
                          TextFormField(
                            controller: _tituloController,
                            decoration: _buildInputDecoration('Ingresa el título de la noticia'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El título es obligatorio';
                              }
                              return null;
                            },
                            maxLength: 100,
                            textInputAction: TextInputAction.next,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Texto corto
                          _buildSectionTitle('Texto corto *'),
                          _buildHelpText('Breve descripción para captar la atención (máx. 100 caracteres)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _textoCortoController,
                            decoration: _buildInputDecoration('Texto breve y atractivo'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El texto corto es obligatorio';
                              }
                              if (value.length > 100) {
                                return 'Máximo 100 caracteres';
                              }
                              return null;
                            },
                            maxLength: 100,
                            maxLines: 2,
                            textInputAction: TextInputAction.next,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Descripción/Contenido
                          _buildSectionTitle('Contenido de la noticia *'),
                          _buildHelpText('Descripción completa de la noticia (500-1000 caracteres)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _descripcionController,
                            decoration: _buildInputDecoration('Escribe el contenido completo...'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El contenido es obligatorio';
                              }
                              if (value.length < 50) {
                                return 'El contenido debe tener al menos 50 caracteres';
                              }
                              return null;
                            },
                            maxLength: 1000,
                            maxLines: 8,
                            minLines: 4,
                            textInputAction: TextInputAction.newline,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Card para multimedia
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header multimedia
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.perm_media,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Multimedia y Enlaces',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Imagen
                          _buildSectionTitle('Imagen (opcional)'),
                          _buildHelpText('Selecciona una imagen para hacer la noticia más visual'),
                          const SizedBox(height: 12),
                          
                          // Selector de imagen mejorado
                          Container(
                            width: double.infinity,
                            height: _imagenSeleccionada != null ? 220 : 140,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[50],
                            ),
                            child: _imagenSeleccionada != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _imagenSeleccionada!,
                                          width: double.infinity,
                                          height: 220,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _imagenSeleccionada = null;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: _seleccionarImagen,
                                      child: Container(
                                        width: double.infinity,
                                        height: 140,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.add_photo_alternate,
                                                size: 32,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Toca para seleccionar imagen',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'JPG, PNG • Máx. 10MB',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Enlace externo
                          _buildSectionTitle('Enlace externo (opcional)'),
                          _buildHelpText('URL para más información o recursos relacionados'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _enlaceExternoController,
                            decoration: _buildInputDecoration('https://ejemplo.com'),
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                if (Uri.tryParse(value)?.hasAbsolutePath != true) {
                                  return 'Ingresa una URL válida';
                                }
                              }
                              return null;
                            },
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Información adicional mejorada
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1B1B).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF8B1B1B).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B1B1B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: const Color(0xFF8B1B1B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Información de publicación',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8B1B1B),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...[ 
                          '• Se usará tu información de usuario como autor',
                          '• Las imágenes se subirán automáticamente a la nube',
                          '• Los campos marcados con * son obligatorios'
                        ].map((text) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: const Color(0xFF8B1B1B).withOpacity(0.8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildHelpText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        height: 1.3,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B1B1B), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.grey[50],
      hintStyle: TextStyle(color: Colors.grey[500]),
    );
  }

  Future<void> _seleccionarImagen() async {
    try {
      // Verificar si el ImagePicker está disponible
      if (!await _picker.supportsImageSource(ImageSource.gallery)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La galería no está disponible en este dispositivo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // Verificar que la imagen no sea null antes de usarla
      if (imagen != null) {
        // Verificar que el archivo existe
        final file = File(imagen.path);
        if (await file.exists()) {
          // Verificar el tamaño del archivo (máximo 10MB)
          final fileSize = await file.length();
          if (fileSize > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La imagen es muy grande. Máximo 10MB'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }

          setState(() {
            _imagenSeleccionada = file;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Imagen seleccionada correctamente'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: El archivo de imagen no existe'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // El usuario canceló la selección - no mostrar error
        print('📷 Usuario canceló la selección de imagen');
      }
    } on PlatformException catch (e) {
      // Errores específicos de la plataforma
      String mensaje = 'Error al acceder a la galería';
      
      if (e.code == 'photo_access_denied') {
        mensaje = 'Acceso denegado a la galería. Verifica los permisos';
      } else if (e.code == 'camera_access_denied') {
        mensaje = 'Acceso denegado a la cámara. Verifica los permisos';
      } else if (e.code == 'invalid_image') {
        mensaje = 'El archivo seleccionado no es una imagen válida';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(mensaje)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _seleccionarImagen();
                });
              },
            ),
          ),
        );
      }
      
      print('❌ PlatformException al seleccionar imagen: ${e.code} - ${e.message}');
    } on FileSystemException catch (e) {
      // Errores del sistema de archivos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error de acceso al almacenamiento')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('❌ FileSystemException: ${e.message}');
    } catch (e) {
      // Cualquier otro error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error inesperado: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      print('❌ Error general al seleccionar imagen: $e');
    }
  }

  Future<void> _guardarNoticia() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<NoticiasViewModel>(context, listen: false);
      
      final success = await viewModel.crearNoticia(
        titulo: _tituloController.text.trim(),
        textoCorto: _textoCortoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        imagenFile: _imagenSeleccionada,
        enlaceExterno: _enlaceExternoController.text.trim().isEmpty 
            ? null 
            : _enlaceExternoController.text.trim(),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('¡Noticia publicada exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(viewModel.errorMessage.isEmpty 
                        ? 'Error al publicar la noticia' 
                        : viewModel.errorMessage),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}