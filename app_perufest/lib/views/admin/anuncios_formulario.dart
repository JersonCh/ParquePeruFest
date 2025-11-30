import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio.dart';
import '../../viewmodels/anuncios_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AnunciosPageSimple extends StatefulWidget {
  const AnunciosPageSimple({super.key});

  @override
  State<AnunciosPageSimple> createState() => _AnunciosPageSimpleState();
}

class _AnunciosPageSimpleState extends State<AnunciosPageSimple> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _imagenUrlController = TextEditingController();
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _posicionSeleccionada = 'superior';
  
  final List<String> _posiciones = ['superior', 'inferior'];
  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _contenidoController.dispose();
    _imagenUrlController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esFechaInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() {
        if (esFechaInicio) {
          _fechaInicio = fecha;
        } else {
          _fechaFin = fecha;
        }
      });
    }
  }

  Future<void> _guardarAnuncio() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona las fechas')),
      );
      return;
    }

    if (_fechaFin!.isBefore(_fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha de fin debe ser posterior a la de inicio')),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final currentUser = authViewModel.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado')),
        );
        return;
      }

      final anuncio = Anuncio(
        id: '',
        titulo: _tituloController.text.trim(),
        contenido: _contenidoController.text.trim(),
        imagenUrl: _imagenUrlController.text.trim().isEmpty 
          ? null 
          : _imagenUrlController.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        posicion: _posicionSeleccionada,
        activo: true,
        orden: 1,
        fechaCreacion: DateTime.now(),
        creadoPor: currentUser.id,
      );

      final anunciosViewModel = context.read<AnunciosViewModel>();
      await anunciosViewModel.crearAnuncio(
        titulo: anuncio.titulo,
        contenido: anuncio.contenido,
        fechaInicio: anuncio.fechaInicio,
        fechaFin: anuncio.fechaFin,
        posicion: anuncio.posicion,
        creadoPor: anuncio.creadoPor,
        imagenPath: anuncio.imagenUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anuncio creado exitosamente')),
        );
        _limpiarFormulario();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear anuncio: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  void _limpiarFormulario() {
    _tituloController.clear();
    _contenidoController.clear();
    _imagenUrlController.clear();
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _posicionSeleccionada = 'superior';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Anuncios'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título del anuncio
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título del Anuncio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el título del anuncio';
                  }
                  if (value.trim().length < 3) {
                    return 'El título debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contenido del anuncio
              TextFormField(
                controller: _contenidoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción del Anuncio *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa la descripción del anuncio';
                  }
                  if (value.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // URL de la imagen
              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de la Imagen (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://ejemplo.com/imagen.jpg',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!Uri.tryParse(value)!.isAbsolute) {
                      return 'Por favor ingresa una URL válida';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Posición del anuncio
              DropdownButtonFormField<String>(
                value: _posicionSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Posición *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                items: _posiciones.map((posicion) => DropdownMenuItem(
                  value: posicion,
                  child: Text(posicion == 'superior' ? 'Parte Superior' : 'Parte Inferior'),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _posicionSeleccionada = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Fecha de inicio
              InkWell(
                onTap: () => _seleccionarFecha(context, true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Inicio *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(
                    _fechaInicio == null 
                      ? 'Seleccionar fecha de inicio'
                      : '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}',
                    style: TextStyle(
                      color: _fechaInicio == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fecha de fin
              InkWell(
                onTap: () => _seleccionarFecha(context, false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Fin *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.date_range),
                  ),
                  child: Text(
                    _fechaFin == null 
                      ? 'Seleccionar fecha de fin'
                      : '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}',
                    style: TextStyle(
                      color: _fechaFin == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón para guardar
              ElevatedButton(
                onPressed: _guardando ? null : _guardarAnuncio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1B1B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _guardando
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Guardando...'),
                      ],
                    )
                  : const Text(
                      'Crear Anuncio',
                      style: TextStyle(fontSize: 16),
                    ),
              ),
              const SizedBox(height: 32),

              // Lista de anuncios existentes
              Consumer<AnunciosViewModel>(
                builder: (context, anunciosViewModel, child) {
                  if (anunciosViewModel.anuncios.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.info_outline, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No hay anuncios creados',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Crea tu primer anuncio usando el formulario anterior',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Anuncios Existentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: anunciosViewModel.anuncios.length,
                        itemBuilder: (context, index) {
                          final anuncio = anunciosViewModel.anuncios[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: anuncio.activo 
                                  ? Colors.green.shade100 
                                  : Colors.grey.shade100,
                                child: Icon(
                                  anuncio.activo ? Icons.visibility : Icons.visibility_off,
                                  color: anuncio.activo ? Colors.green : Colors.grey,
                                ),
                              ),
                              title: Text(anuncio.titulo),
                              subtitle: Text(
                                '${anuncio.contenido}\n'
                                'Posición: ${anuncio.posicion}\n'
                                'Desde: ${anuncio.fechaInicio.day}/${anuncio.fechaInicio.month}/${anuncio.fechaInicio.year}\n'
                                'Hasta: ${anuncio.fechaFin.day}/${anuncio.fechaFin.month}/${anuncio.fechaFin.year}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirmar = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar eliminación'),
                                      content: Text('¿Estás seguro de eliminar el anuncio "${anuncio.titulo}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Eliminar'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirmar == true) {
                                    try {
                                      await anunciosViewModel.eliminarAnuncio(anuncio.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Anuncio eliminado exitosamente')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al eliminar: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}