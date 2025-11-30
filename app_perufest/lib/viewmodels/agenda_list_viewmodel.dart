import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/actividad.dart';
import '../services/timezone_service.dart'; // Añadir esta importación

class AgendaListViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _actividadesAgenda = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get actividadesAgenda => _actividadesAgenda;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> cargarActividadesAgenda(String userId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Obtener la agenda del usuario
      final agendaDoc = await _firestore.collection('agenda_usuarios').doc(userId).get();
      
      if (!agendaDoc.exists || agendaDoc.data() == null) {
        _actividadesAgenda = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final agendaData = agendaDoc.data()!;
      final actividadesIds = List<String>.from(agendaData['actividades'] ?? []);
      final detalles = Map<String, dynamic>.from(agendaData['detalles'] ?? {});

      if (actividadesIds.isEmpty) {
        _actividadesAgenda = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Obtener los datos completos de cada actividad
      List<Map<String, dynamic>> actividadesCompletas = [];

      for (String actividadId in actividadesIds) {
        try {
          final actividadDoc = await _firestore.collection('actividades').doc(actividadId).get();
          
          if (actividadDoc.exists && actividadDoc.data() != null) {
            final actividadData = actividadDoc.data()!;
            final detalleAgenda = detalles[actividadId] ?? {};
            
            // Convertir timestamps a fechas de Perú
            final fechaInicio = TimezoneService.timestampToPeru(actividadData['fechaInicio']);
            final fechaFin = TimezoneService.timestampToPeru(actividadData['fechaFin']);
            final fechaAgregado = TimezoneService.timestampToPeru(detalleAgenda['fechaAgregado']);
            
            // Combinar datos de actividad con detalles de agenda
            actividadesCompletas.add({
              'id': actividadId,
              'nombre': actividadData['nombre'] ?? 'Sin nombre',
              'zona': actividadData['zona'] ?? 'Sin zona',
              'fechaInicio': fechaInicio,
              'fechaFin': fechaFin,
              'eventoId': actividadData['eventoId'] ?? '',
              'fechaAgregado': fechaAgregado,
              'recordatorioMinutos': detalleAgenda['recordatorioMinutos'] ?? 30,
            });
          }
        } catch (e) {
          debugPrint('Error al obtener actividad $actividadId: $e');
        }
      }

      // Ordenar por fecha de inicio más próxima (ya en zona horaria de Perú)
      actividadesCompletas.sort((a, b) {
        final fechaA = a['fechaInicio'] as DateTime? ?? TimezoneService.nowInPeru();
        final fechaB = b['fechaInicio'] as DateTime? ?? TimezoneService.nowInPeru();
        return fechaA.compareTo(fechaB);
      });

      _actividadesAgenda = actividadesCompletas;
    } catch (e) {
      _error = 'Error al cargar actividades: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removerActividad(String userId, String actividadId) async {
    try {
      await _firestore.collection('agenda_usuarios').doc(userId).update({
        'actividades': FieldValue.arrayRemove([actividadId]),
        'detalles.$actividadId': FieldValue.delete(),
      });
      
      // Recargar la lista
      await cargarActividadesAgenda(userId);
      return true;
    } catch (e) {
      _error = 'Error al remover actividad: $e';
      notifyListeners();
      return false;
    }
  }
}