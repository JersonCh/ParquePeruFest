import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../viewmodels/anuncios_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/anuncio.dart';

class CrearAnuncioPage extends StatefulWidget {
  final Anuncio? anuncioAEditar;
  
  const CrearAnuncioPage({super.key, this.anuncioAEditar});

  @override
  State<CrearAnuncioPage> createState() => _CrearAnuncioPageState();
}

class _CrearAnuncioPageState extends State<CrearAnuncioPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  File? _imagenSeleccionada;
  String? _imagenUrlActual;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _inicializarFormulario();
  }

  void _inicializarFormulario() {
    if (widget.anuncioAEditar != null) {
      final anuncio = widget.anuncioAEditar!;
      _tituloController.text = anuncio.titulo;
      _contenidoController.text = anuncio.contenido;
      _fechaInicio = anuncio.fechaInicio;
      _fechaFin = anuncio.fechaFin;
      _imagenUrlActual = anuncio.imagenUrl;
    } else {
      // Valores por defecto para nuevo anuncio
      _fechaInicio = DateTime.now();
      _fechaFin = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.anuncioAEditar != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Anuncio' : 'Crear Anuncio'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
        actions: [
          Consumer<AnunciosViewModel>(
            builder: (context, viewModel, child) {
              return TextButton(
                onPressed: viewModel.isLoading ? null : _guardarAnuncio,
                child: Text(
                  'GUARDAR',
                  style: TextStyle(
                    color: viewModel.isLoading ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AnunciosViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título del anuncio
                      _buildSeccionTitulo('Información Básica'),
                      _buildCampoTexto(
                        controller: _tituloController,
                        label: 'Título del anuncio',
                        hint: 'Ej: ¡Nueva Actividad Disponible!',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El título es requerido';
                          }
                          if (value.trim().length < 3) {
                            return 'El título debe tener al menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Contenido del anuncio
                      _buildCampoTexto(
                        controller: _contenidoController,
                        label: 'Contenido del anuncio',
                        hint: 'Describe brevemente el anuncio...',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El contenido es requerido';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Imagen del anuncio
                      _buildSeccionTitulo('Imagen del Anuncio'),
                      _buildSeccionImagen(),
                      
                      const SizedBox(height: 24),
                      
                      // Fechas
                      _buildSeccionFechas(),
                      
                      const SizedBox(height: 24),
                      
                      // Vista previa
                      _buildSeccionTitulo('Vista Previa'),
                      _buildVistaPrevia(),
                      
                      const SizedBox(height: 100), // Espacio extra para el scroll
                    ],
                  ),
                ),
              ),
              
              // Loading overlay
              if (viewModel.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Guardando anuncio...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF8B1B1B),
        ),
      ),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF8B1B1B), width: 2),
        ),
      ),
    );
  }

  Widget _buildSeccionImagen() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _imagenSeleccionada != null
          ? _buildImagenSeleccionada()
          : _imagenUrlActual != null
              ? _buildImagenExistente()
              : _buildSelectorImagen(),
    );
  }

  Widget _buildImagenSeleccionada() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            _imagenSeleccionada!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => setState(() => _imagenSeleccionada = null),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagenExistente() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _imagenUrlActual!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildSelectorImagen();
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => setState(() => _imagenUrlActual = null),
            icon: const Icon(Icons.edit),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorImagen() {
    return InkWell(
      onTap: _seleccionarImagen,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Toca para seleccionar una imagen',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            '(Opcional)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionFechas() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCampoFecha(
                label: 'Fecha de inicio',
                fecha: _fechaInicio,
                onTap: () => _seleccionarFecha(true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCampoFecha(
                label: 'Fecha de fin',
                fecha: _fechaFin,
                onTap: () => _seleccionarFecha(false),
              ),
            ),
          ],
        ),
        if (_fechaInicio != null && _fechaFin != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Duración: ${_calcularDuracion()} días',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCampoFecha({
    required String label,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          fecha != null ? _formatearFecha(fecha) : 'Seleccionar fecha',
          style: TextStyle(
            color: fecha != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildVistaPrevia() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF8B1B1B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B1B1B).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (_imagenSeleccionada != null || _imagenUrlActual != null)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: _imagenSeleccionada != null
                      ? FileImage(_imagenSeleccionada!)
                      : NetworkImage(_imagenUrlActual!) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _tituloController.text.isNotEmpty
                      ? _tituloController.text
                      : 'Título del anuncio',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_contenidoController.text.isNotEmpty)
                  Text(
                    _contenidoController.text,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.campaign, color: Color(0xFF8B1B1B)),
        ],
      ),
    );
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? imagen = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (imagen != null) {
        setState(() {
          _imagenSeleccionada = File(imagen.path);
          _imagenUrlActual = null; // Limpiar imagen existente
        });
      }
    } catch (e) {
      _mostrarError('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fechaInicial = esInicio ? _fechaInicio : _fechaFin;
    final primerFecha = esInicio ? DateTime.now() : (_fechaInicio ?? DateTime.now());
    
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: fechaInicial ?? primerFecha,
      firstDate: primerFecha,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B1B1B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = fechaSeleccionada;
          // Si la fecha de fin es anterior a la nueva fecha de inicio, ajustarla
          if (_fechaFin != null && _fechaFin!.isBefore(fechaSeleccionada)) {
            _fechaFin = fechaSeleccionada.add(const Duration(days: 1));
          }
        } else {
          _fechaFin = fechaSeleccionada;
        }
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  int _calcularDuracion() {
    if (_fechaInicio != null && _fechaFin != null) {
      return _fechaFin!.difference(_fechaInicio!).inDays;
    }
    return 0;
  }

  Future<void> _guardarAnuncio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      _mostrarError('Por favor selecciona las fechas de inicio y fin');
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!)) {
      _mostrarError('La fecha de fin debe ser posterior a la fecha de inicio');
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final anunciosViewModel = context.read<AnunciosViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      _mostrarError('Usuario no autenticado');
      return;
    }

    bool exito;
    if (widget.anuncioAEditar != null) {
      // Editar anuncio existente
      exito = await anunciosViewModel.actualizarAnuncio(
        anuncioId: widget.anuncioAEditar!.id,
        titulo: _tituloController.text.trim(),
        contenido: _contenidoController.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        posicion: 'global',
        nuevaImagenPath: _imagenSeleccionada?.path,
        imagenUrlActual: _imagenUrlActual,
      );
    } else {
      // Crear nuevo anuncio
      exito = await anunciosViewModel.crearAnuncio(
        titulo: _tituloController.text.trim(),
        contenido: _contenidoController.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        posicion: 'global',
        creadoPor: currentUser.id,
        imagenPath: _imagenSeleccionada?.path,
      );
    }

    if (exito && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.anuncioAEditar != null
                ? 'Anuncio actualizado correctamente'
                : 'Anuncio creado correctamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (anunciosViewModel.error != null && mounted) {
      _mostrarError(anunciosViewModel.error!);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}