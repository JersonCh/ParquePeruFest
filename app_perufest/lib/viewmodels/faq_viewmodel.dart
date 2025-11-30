import 'package:flutter/material.dart';
import '../models/faq.dart';
import '../services/faq_service.dart';

class FAQViewModel extends ChangeNotifier {
  final FAQService _faqService = FAQService();
  
  List<FAQ> _faqs = [];
  List<FAQ> _faqsActivas = [];
  bool _isLoading = false;
  String? _error;
  
  // Estados para formularios
  final TextEditingController preguntaController = TextEditingController();
  final TextEditingController respuestaController = TextEditingController();
  bool _isCreating = false;
  bool _isUpdating = false;
  FAQ? _faqEnEdicion;

  // Getters
  List<FAQ> get faqs => _faqs;
  List<FAQ> get faqsActivas => _faqsActivas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  FAQ? get faqEnEdicion => _faqEnEdicion;

  // Estadísticas
  int get totalFAQs => _faqs.length;
  int get faqsActivasCount => _faqs.where((faq) => faq.estado).length;
  int get faqsInactivasCount => _faqs.where((faq) => !faq.estado).length;

  @override
  void dispose() {
    preguntaController.dispose();
    respuestaController.dispose();
    super.dispose();
  }

  // Cargar todas las FAQs (para administrador)
  Future<void> cargarTodasLasFAQs() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final faqs = await _faqService.obtenerTodasLasFAQs();
      _faqs = faqs;
      debugPrint('FAQs cargadas: ${faqs.length}');
      notifyListeners();
    } catch (e) {
      debugPrint('Error en cargarTodasLasFAQs: $e');
      _setError('Error al cargar las preguntas frecuentes: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar solo FAQs activas (para visitantes)
  Future<void> cargarFAQsActivas() async {
    _setLoading(true);
    _setError(null);
    
    try {
      final faqs = await _faqService.obtenerFAQsActivas();
      _faqsActivas = faqs;
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar las preguntas frecuentes: $e');
    }
    
    _setLoading(false);
  }

  // Crear nueva FAQ
  Future<bool> crearFAQ() async {
    if (preguntaController.text.trim().isEmpty || 
        respuestaController.text.trim().isEmpty) {
      _setError('La pregunta y respuesta son obligatorias');
      return false;
    }

    _setCreating(true);
    _setError(null);

    try {
      final id = await _faqService.crearFAQ(
        pregunta: preguntaController.text.trim(),
        respuesta: respuestaController.text.trim(),
        estado: true,
        orden: _faqs.length,
      );

      if (id != null) {
        limpiarFormulario();
        await cargarTodasLasFAQs(); // Recargar la lista
        return true;
      } else {
        _setError('Error al crear la pregunta frecuente');
        return false;
      }
    } catch (e) {
      _setError('Error al crear la pregunta frecuente: $e');
      return false;
    } finally {
      _setCreating(false);
    }
  }

  // Actualizar FAQ existente
  Future<bool> actualizarFAQ() async {
    if (_faqEnEdicion == null) {
      _setError('No hay FAQ seleccionada para editar');
      return false;
    }

    if (preguntaController.text.trim().isEmpty || 
        respuestaController.text.trim().isEmpty) {
      _setError('La pregunta y respuesta son obligatorias');
      return false;
    }

    _setUpdating(true);
    _setError(null);

    try {
      final success = await _faqService.actualizarFAQ(
        _faqEnEdicion!.id,
        pregunta: preguntaController.text.trim(),
        respuesta: respuestaController.text.trim(),
      );

      if (success) {
        limpiarFormulario();
        cancelarEdicion();
        await cargarTodasLasFAQs(); // Recargar la lista
        return true;
      } else {
        _setError('Error al actualizar la pregunta frecuente');
        return false;
      }
    } catch (e) {
      _setError('Error al actualizar la pregunta frecuente: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  // Eliminar FAQ
  Future<bool> eliminarFAQ(String id) async {
    _setError(null);

    try {
      final success = await _faqService.eliminarFAQ(id);

      if (success) {
        await cargarTodasLasFAQs(); // Recargar la lista
        return true;
      } else {
        _setError('Error al eliminar la pregunta frecuente');
        return false;
      }
    } catch (e) {
      _setError('Error al eliminar la pregunta frecuente: $e');
      return false;
    }
  }

  // Cambiar estado de FAQ (activar/desactivar)
  Future<bool> cambiarEstadoFAQ(String id, bool nuevoEstado) async {
    _setError(null);

    try {
      final success = await _faqService.cambiarEstadoFAQ(id, nuevoEstado);

      if (success) {
        await cargarTodasLasFAQs(); // Recargar la lista
        return true;
      } else {
        _setError('Error al cambiar el estado de la pregunta frecuente');
        return false;
      }
    } catch (e) {
      _setError('Error al cambiar el estado de la pregunta frecuente: $e');
      return false;
    }
  }

  // Preparar FAQ para edición
  void prepararEdicion(FAQ faq) {
    _faqEnEdicion = faq;
    preguntaController.text = faq.pregunta;
    respuestaController.text = faq.respuesta;
    notifyListeners();
  }

  // Cancelar edición
  void cancelarEdicion() {
    _faqEnEdicion = null;
    limpiarFormulario();
    notifyListeners();
  }

  // Limpiar formulario
  void limpiarFormulario() {
    preguntaController.clear();
    respuestaController.clear();
    notifyListeners();
  }

  // Buscar FAQs
  Future<List<FAQ>> buscarFAQs(String textoBusqueda) async {
    try {
      return await _faqService.buscarFAQs(textoBusqueda);
    } catch (e) {
      _setError('Error al buscar preguntas frecuentes: $e');
      return [];
    }
  }

  // Reordenar FAQs
  Future<bool> reordenarFAQs(List<FAQ> faqsReordenadas) async {
    _setError(null);

    try {
      final idsOrdenados = faqsReordenadas.map((faq) => faq.id).toList();
      final success = await _faqService.reordenarFAQs(idsOrdenados);

      if (success) {
        await cargarTodasLasFAQs(); // Recargar la lista
        return true;
      } else {
        _setError('Error al reordenar las preguntas frecuentes');
        return false;
      }
    } catch (e) {
      _setError('Error al reordenar las preguntas frecuentes: $e');
      return false;
    }
  }

  // Obtener estadísticas
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      return await _faqService.obtenerEstadisticasFAQs();
    } catch (e) {
      _setError('Error al obtener estadísticas: $e');
      return {
        'total': 0,
        'activas': 0,
        'inactivas': 0,
      };
    }
  }

  // Crear FAQs predeterminadas
  Future<bool> crearFAQsPredeterminadas() async {
    _setLoading(true);
    _setError(null);

    try {
      final success = await _faqService.crearFAQsPredeterminadas();

      if (success) {
        await cargarTodasLasFAQs(); // Recargar la lista
        return true;
      } else {
        _setError('Error al crear las preguntas frecuentes predeterminadas');
        return false;
      }
    } catch (e) {
      _setError('Error al crear las preguntas frecuentes predeterminadas: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Validar formulario
  bool validarFormulario() {
    if (preguntaController.text.trim().isEmpty) {
      _setError('La pregunta es obligatoria');
      return false;
    }

    if (respuestaController.text.trim().isEmpty) {
      _setError('La respuesta es obligatoria');
      return false;
    }

    if (preguntaController.text.trim().length < 10) {
      _setError('La pregunta debe tener al menos 10 caracteres');
      return false;
    }

    if (respuestaController.text.trim().length < 20) {
      _setError('La respuesta debe tener al menos 20 caracteres');
      return false;
    }

    _setError(null);
    return true;
  }

  // Obtener Stream de FAQs activas
  Stream<List<FAQ>> get streamFAQsActivas => _faqService.streamFAQsActivas();

  // Obtener Stream de todas las FAQs
  Stream<List<FAQ>> get streamTodasLasFAQs => _faqService.streamTodasLasFAQs();

  // Actualizar FAQs desde stream
  void actualizarFAQsDesdeStream(List<FAQ> faqs) {
    _faqs = faqs;
    notifyListeners();
  }

  // Actualizar FAQs activas desde stream
  void actualizarFAQsActivasDesdeStream(List<FAQ> faqs) {
    _faqsActivas = faqs;
    notifyListeners();
  }

  // Métodos privados para actualizar estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }
}