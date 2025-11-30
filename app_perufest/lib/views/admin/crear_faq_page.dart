import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/faq_viewmodel.dart';

class CrearFAQPage extends StatefulWidget {
  const CrearFAQPage({super.key});

  @override
  State<CrearFAQPage> createState() => _CrearFAQPageState();
}

class _CrearFAQPageState extends State<CrearFAQPage> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Limpiar el formulario al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FAQViewModel>().limpiarFormulario();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Pregunta Frecuente'),
        backgroundColor: const Color(0xFF8B1B1B),
        foregroundColor: Colors.white,
      ),
      body: Consumer<FAQViewModel>(
        builder: (context, faqViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildPreguntaField(faqViewModel),
                  const SizedBox(height: 16),
                  _buildRespuestaField(faqViewModel),
                  const SizedBox(height: 24),
                  if (faqViewModel.error != null)
                    _buildErrorMessage(faqViewModel.error!),
                  const SizedBox(height: 16),
                  _buildAcciones(faqViewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B1B1B).withOpacity(0.1),
            const Color(0xFF8B1B1B).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B1B1B).withOpacity(0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.help_center,
            color: Color(0xFF8B1B1B),
            size: 28,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva Pregunta Frecuente',
                  style: TextStyle(
                    color: Color(0xFF8B1B1B),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Agrega una nueva pregunta y respuesta para tus visitantes',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntaField(FAQViewModel faqViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pregunta *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B1B1B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: faqViewModel.preguntaController,
          decoration: InputDecoration(
            hintText: 'Ejemplo: ¿Cuál es el horario del festival?',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B1B1B), width: 2),
            ),
            prefixIcon: const Icon(Icons.help_outline, color: Color(0xFF8B1B1B)),
            counterText: '',
          ),
          maxLength: 200,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La pregunta es obligatoria';
            }
            if (value.trim().length < 10) {
              return 'La pregunta debe tener al menos 10 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildRespuestaField(FAQViewModel faqViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Respuesta *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B1B1B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: faqViewModel.respuestaController,
          decoration: InputDecoration(
            hintText: 'Escribe una respuesta completa y clara...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF8B1B1B), width: 2),
            ),
            prefixIcon: const Icon(Icons.message, color: Color(0xFF8B1B1B)),
            alignLabelWithHint: true,
            counterText: '',
          ),
          maxLength: 1000,
          maxLines: 6,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La respuesta es obligatoria';
            }
            if (value.trim().length < 20) {
              return 'La respuesta debe tener al menos 20 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcciones(FAQViewModel faqViewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: faqViewModel.isCreating ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: faqViewModel.isCreating ? null : () => _crearFAQ(faqViewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1B1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: faqViewModel.isCreating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Creando...'),
                    ],
                  )
                : const Text('Crear FAQ'),
          ),
        ),
      ],
    );
  }

  void _crearFAQ(FAQViewModel faqViewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await faqViewModel.crearFAQ();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FAQ creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (!success && mounted) {
        // El error ya se muestra en el UI a través del ViewModel
      }
    }
  }
}