import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/noticias.dart';
import '../../viewmodels/noticias_viewmodel.dart';

class DetalleNoticiaPage extends StatefulWidget {
  final Noticia noticia;

  const DetalleNoticiaPage({super.key, required this.noticia});

  @override
  State<DetalleNoticiaPage> createState() => _DetalleNoticiaPageState();
}

class _DetalleNoticiaPageState extends State<DetalleNoticiaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _textoCortoController;
  late TextEditingController _descripcionController;
  late TextEditingController _enlaceExternoController;
  
  bool _isEditing = false;
  File? _nuevaImagen;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController(text: widget.noticia.titulo);
    _textoCortoController = TextEditingController(text: widget.noticia.textoCorto);
    _descripcionController = TextEditingController(text: widget.noticia.descripcion);
    _enlaceExternoController = TextEditingController(text: widget.noticia.enlaceExterno ?? '');
  }

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
        title: Text(
          _isEditing ? 'Editar Noticia' : 'Detalle de Noticia',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF8B1B1B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (!_isEditing) ...[
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                tooltip: 'Editar noticia',
              ),
            ),
            PopupMenuButton<String>(
              icon: Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert, size: 20),
              ),
              onSelected: (value) {
                if (value == 'eliminar') {
                  _mostrarDialogoEliminar();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Eliminar noticia', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            TextButton.icon(
              onPressed: _cancelarEdicion,
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              label: const Text(
                'CANCELAR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Consumer<NoticiasViewModel>(
              builder: (context, viewModel, child) {
                return TextButton.icon(
                  onPressed: (_isLoading || viewModel.isLoading) 
                      ? null 
                      : _guardarCambios,
                  icon: const Icon(Icons.save, color: Colors.white, size: 18),
                  label: const Text(
                    'GUARDAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ],
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
                                  _isLoading ? 'Subiendo imagen...' : 'Guardando cambios...',
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

                  // Card principal con información de la noticia
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
                          // Header con información de la noticia
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B1B1B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _isEditing ? Icons.edit : Icons.article,
                                  color: const Color(0xFF8B1B1B),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isEditing ? 'Editando Noticia' : 'Detalle de la Noticia',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    if (!_isEditing)
                                      Text(
                                        'Publicado ${_formatDateRelative(widget.noticia.fechaPublicacion)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isEditing)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Publicada',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),

                          // Título
                          _buildSectionTitle('Título'),
                          _isEditing
                              ? TextFormField(
                                  controller: _tituloController,
                                  decoration: _buildInputDecoration('Título de la noticia'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El título es obligatorio';
                                    }
                                    return null;
                                  },
                                  maxLength: 100,
                                  textInputAction: TextInputAction.next,
                                )
                              : _buildDisplayField(widget.noticia.titulo, 18, FontWeight.bold),

                          const SizedBox(height: 20),

                          // Texto corto
                          _buildSectionTitle('Texto corto'),
                          if (_isEditing)
                            _buildHelpText('Breve descripción para captar la atención (máx. 100 caracteres)'),
                          SizedBox(height: _isEditing ? 8 : 0),
                          _isEditing
                              ? TextFormField(
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
                                )
                              : _buildDisplayField(widget.noticia.textoCorto, 15, FontWeight.normal),

                          const SizedBox(height: 20),

                          // Descripción/Contenido
                          _buildSectionTitle('Contenido'),
                          if (_isEditing)
                            _buildHelpText('Descripción completa de la noticia (50-1000 caracteres)'),
                          SizedBox(height: _isEditing ? 8 : 0),
                          _isEditing
                              ? TextFormField(
                                  controller: _descripcionController,
                                  decoration: _buildInputDecoration('Contenido completo de la noticia'),
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
                                )
                              : _buildDisplayField(widget.noticia.descripcion, 14, FontWeight.normal),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Card de multimedia
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
                          _buildSectionTitle('Imagen'),
                          if (_isEditing)
                            _buildHelpText('Imagen principal de la noticia (opcional)'),
                          SizedBox(height: _isEditing ? 12 : 8),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _buildImageSection(),
                          ),

                          const SizedBox(height: 24),

                          // Enlace externo
                          _buildSectionTitle('Enlace externo'),
                          if (_isEditing)
                            _buildHelpText('URL para más información o recursos relacionados (opcional)'),
                          SizedBox(height: _isEditing ? 8 : 0),
                          _isEditing
                              ? TextFormField(
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
                                )
                              : _buildLinkField(widget.noticia.enlaceExterno),
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
                        _buildInfoRow(Icons.person, 'Autor', widget.noticia.autorNombre),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, 'Fecha de publicación', _formatDate(widget.noticia.fechaPublicacion)),
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

  Widget _buildDisplayField(String text, double fontSize, FontWeight fontWeight) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildLinkField(String? enlace) {
    if (enlace == null || enlace.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.link_off, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Text(
              'Sin enlace externo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              enlace,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                decoration: TextDecoration.underline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.open_in_new, color: Colors.blue.shade600, size: 16),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B1B1B).withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: const Color(0xFF8B1B1B).withOpacity(0.8),
                fontSize: 13,
                height: 1.4,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildImageSection() {
    if (_nuevaImagen != null) {
      // Mostrar nueva imagen seleccionada
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _nuevaImagen!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          if (_isEditing)
            Positioned(
              top: 12,
              right: 12,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _nuevaImagen = null;
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
      );
    } else if (widget.noticia.imagenUrl != null) {
      // Mostrar imagen existente
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              widget.noticia.imagenUrl!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey[500]),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF8B1B1B).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _seleccionarImagen,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Cambiar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // No hay imagen
      return Container(
        height: _isEditing ? 140 : 80,
        child: _isEditing
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _seleccionarImagen,
                  child: Container(
                    width: double.infinity,
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
                          'Toca para agregar imagen',
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
              )
            : Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported, color: Colors.grey[400], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Sin imagen',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${meses[date.month - 1]} de ${date.year} a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateRelative(DateTime date) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    // Formatear hora
    String formatTime(DateTime dt) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    
    if (difference.inDays == 0) {
      return 'hoy a las ${formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'ayer a las ${formatTime(date)}';
    } else if (difference.inDays < 7) {
      return 'hace ${difference.inDays} días a las ${formatTime(date)}';
    } else {
      return 'el ${date.day} ${meses[date.month - 1]} ${date.year} a las ${formatTime(date)}';
    }
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
            _nuevaImagen = file;
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

  void _cancelarEdicion() {
    setState(() {
      _isEditing = false;
      _nuevaImagen = null;
      // Restaurar valores originales
      _tituloController.text = widget.noticia.titulo;
      _textoCortoController.text = widget.noticia.textoCorto;
      _descripcionController.text = widget.noticia.descripcion;
      _enlaceExternoController.text = widget.noticia.enlaceExterno ?? '';
    });
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<NoticiasViewModel>(context, listen: false);
      
      final success = await viewModel.actualizarNoticia(
        id: widget.noticia.id,
        titulo: _tituloController.text.trim(),
        textoCorto: _textoCortoController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        imagenFile: _nuevaImagen,
        imagenUrlActual: widget.noticia.imagenUrl,
        enlaceExterno: _enlaceExternoController.text.trim().isEmpty 
            ? null 
            : _enlaceExternoController.text.trim(),
      );

      if (success) {
        if (mounted) {
          setState(() {
            _isEditing = false;
            _nuevaImagen = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('¡Noticia actualizada exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Regresar a la página anterior
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
                        ? 'Error al actualizar la noticia' 
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

  void _mostrarDialogoEliminar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning, color: Colors.red.shade600, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Confirmar eliminación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres eliminar la noticia:',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${widget.noticia.titulo}"',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.red[600], fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _eliminarNoticia();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarNoticia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final viewModel = Provider.of<NoticiasViewModel>(context, listen: false);
      
      final success = await viewModel.eliminarNoticia(widget.noticia.id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Noticia eliminada exitosamente'),
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
              content: Text(viewModel.errorMessage.isEmpty 
                  ? 'Error al eliminar la noticia' 
                  : viewModel.errorMessage),
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