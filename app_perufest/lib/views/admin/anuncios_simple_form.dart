import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/anuncios_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'lista_anuncios_page.dart';

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

    setState(() {
      _guardando = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final anunciosViewModel = context.read<AnunciosViewModel>();
      
      await anunciosViewModel.crearAnuncio(
        titulo: _tituloController.text.trim(),
        contenido: _contenidoController.text.trim(),
        fechaInicio: _fechaInicio!,
        fechaFin: _fechaFin!,
        posicion: _posicionSeleccionada,
        creadoPor: authViewModel.currentUser?.id ?? '',
        imagenPath: _imagenUrlController.text.trim().isEmpty ? null : _imagenUrlController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio creado exitosamente')),
      );
      
      _tituloController.clear();
      _contenidoController.clear();
      _imagenUrlController.clear();
      setState(() {
        _fechaInicio = null;
        _fechaFin = null;
        _posicionSeleccionada = 'superior';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
        title: const Text('Gestión de Anuncios'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título del Anuncio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value?.isEmpty == true ? 'Ingresa el título' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Ingresa la descripción' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _imagenUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de Imagen (opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _posicionSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Posición',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                items: const [
                  DropdownMenuItem(value: 'superior', child: Text('Parte Superior')),
                  DropdownMenuItem(value: 'inferior', child: Text('Parte Inferior')),
                ],
                onChanged: (value) => setState(() => _posicionSeleccionada = value!),
              ),
              const SizedBox(height: 16),

              ListTile(
                title: Text(_fechaInicio == null 
                  ? 'Seleccionar Fecha de Inicio' 
                  : 'Inicio: ${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'),
                leading: const Icon(Icons.date_range),
                onTap: () => _seleccionarFecha(context, true),
                tileColor: Colors.grey[100],
              ),
              const SizedBox(height: 8),

              ListTile(
                title: Text(_fechaFin == null 
                  ? 'Seleccionar Fecha de Fin' 
                  : 'Fin: ${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'),
                leading: const Icon(Icons.date_range),
                onTap: () => _seleccionarFecha(context, false),
                tileColor: Colors.grey[100],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarAnuncio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1B1B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _guardando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Crear Anuncio', style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 32),
              
              // Botón para ver lista de anuncios
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.list_alt,
                        size: 48,
                        color: Color(0xFF8B1B1B),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gestionar Anuncios Existentes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ve, edita, activa/desactiva o elimina los anuncios que has creado',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ListaAnunciosPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.view_list),
                          label: const Text('Ver Lista de Anuncios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B1B1B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}