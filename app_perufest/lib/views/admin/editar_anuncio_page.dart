import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/anuncio.dart';
import '../../viewmodels/anuncios_viewmodel.dart';

class EditarAnuncioPage extends StatefulWidget {
  final Anuncio anuncio;
  
  const EditarAnuncioPage({super.key, required this.anuncio});

  @override
  State<EditarAnuncioPage> createState() => _EditarAnuncioPageState();
}

class _EditarAnuncioPageState extends State<EditarAnuncioPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _contenidoController;
  late final TextEditingController _imagenUrlController;
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos del anuncio
    _tituloController = TextEditingController(text: widget.anuncio.titulo);
    _contenidoController = TextEditingController(text: widget.anuncio.contenido);
    _imagenUrlController = TextEditingController(text: widget.anuncio.imagenUrl ?? '');
    _fechaInicio = widget.anuncio.fechaInicio;
    _fechaFin = widget.anuncio.fechaFin;
  }

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
      initialDate: esFechaInicio ? _fechaInicio ?? DateTime.now() : _fechaFin ?? DateTime.now(),
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

  Future<void> _actualizarAnuncio() async {
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
      final anunciosViewModel = context.read<AnunciosViewModel>();
      
      final resultado = await anunciosViewModel.actualizarAnuncio(
        anuncioId: widget.anuncio.id,
        titulo: _tituloController.text.trim(),
        contenido: _contenidoController.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        posicion: 'global',
        imagenUrlActual: _imagenUrlController.text.trim().isEmpty ? null : _imagenUrlController.text.trim(),
      );

      if (resultado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anuncio actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Regresar con éxito
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el anuncio'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Anuncio'),
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
              // Información del anuncio
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Editando anuncio',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${widget.anuncio.id}'),
                      Text('Creado: ${widget.anuncio.fechaCreacion.day}/${widget.anuncio.fechaCreacion.month}/${widget.anuncio.fechaCreacion.year}'),
                      Text('Estado: ${widget.anuncio.activo ? "Activo" : "Inactivo"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                    return 'Por favor ingresa el título';
                  }
                  if (value.trim().length < 3) {
                    return 'El título debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Descripción
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Descripción *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa la descripción';
                  }
                  if (value.trim().length < 10) {
                    return 'La descripción debe tener al menos 10 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // URL de imagen
              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de Imagen (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
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

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _guardando ? null : _actualizarAnuncio,
                      icon: _guardando 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                      label: Text(_guardando ? 'Guardando...' : 'Actualizar Anuncio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1B1B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}