import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket.dart';
import '../models/orden_compra.dart';

class TicketsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final String _ticketsCollection = 'tickets';
  final String _ordenesCollection = 'ordenes_compra';

  /// Obtener tickets de una fecha específica
  Future<List<Ticket>> obtenerTicketsPorFecha(DateTime fecha) async {
    try {
      // Inicio y fin del día
      final inicioDia = DateTime(fecha.year, fecha.month, fecha.day);
      final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
      
      final querySnapshot = await _firestore
          .collection(_ticketsCollection)
          .where('fechaValidez', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fechaValidez', isLessThanOrEqualTo: Timestamp.fromDate(finDia))
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener tickets por fecha: $e');
    }
  }

  /// Obtener tickets de un usuario
  Future<List<Ticket>> obtenerTicketsPorUsuario(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ticketsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('fechaCompra', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Ticket.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Imprimir error detallado en consola
      print('═══════════════════════════════════════════════════════');
      print('❌ ERROR EN FIRESTORE - ÍNDICE REQUERIDO');
      print('═══════════════════════════════════════════════════════');
      print('Error: $e');
      print('');
      print('📋 SOLUCIÓN: Crea el índice compuesto en Firestore');
      print('');
      print('🔗 ENLACE DIRECTO (copia y pega en tu navegador):');
      print('https://console.firebase.google.com/v1/r/project/bd-parque-perufest/firestore/indexes?create_composite=ClJwem9qZWN0cy9iZC1wYXJxdWUtcGVydWZlc3QvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3RpY2tldHMvaW5kZXhlcy9fEAEaCgoGdXNlcklkEAEaEAoMZmVjaGFDb21wcmEQAhoMCghfX25hbWVfXxAB');
      print('');
      print('📝 O configura manualmente:');
      print('   Colección: tickets');
      print('   Campos:');
      print('   - userId (Ascending)');
      print('   - fechaCompra (Descending)');
      print('═══════════════════════════════════════════════════════');
      
      throw Exception('Error al obtener tickets del usuario: $e');
    }
  }

  /// Validar un ticket por QR
  Future<bool> validarTicket(String qrData, String validadorId) async {
    try {
      // Buscar el ticket por QR data
      final querySnapshot = await _firestore
          .collection(_ticketsCollection)
          .where('qrData', isEqualTo: qrData)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Ticket no encontrado');
      }

      final ticketDoc = querySnapshot.docs.first;
      final ticket = Ticket.fromMap(ticketDoc.data());

      // Validaciones
      if (ticket.estado == EstadoTicket.usado) {
        throw Exception('Ticket ya fue usado');
      }

      if (ticket.estado != EstadoTicket.pagado) {
        throw Exception('Ticket no está pagado o está cancelado');
      }

      if (ticket.estaExpirado) {
        throw Exception('Ticket expirado');
      }

      // Marcar como usado
      await ticketDoc.reference.update({
        'estado': EstadoTicket.usado.name,
        'fechaValidacion': Timestamp.now(),
        'validadoPor': validadorId,
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Crear orden completa con tickets
  Future<OrdenCompra> crearOrdenCompleta({
    required String userId,
    required String transactionId,
    required double montoTotal,
    required DateTime fechaVisita,
    required int cantidadEntradas,
    required int cantidadCocheras,
    required int totalPersonas,
    required String nombreComprador,
    required String dniComprador,
    required String emailComprador,
    String? telefonoComprador,
    required List<Ticket> tickets,
  }) async {
    try {
      // Crear la orden
      final ordenId = _firestore.collection(_ordenesCollection).doc().id;
      
      final orden = OrdenCompra(
        id: ordenId,
        userId: userId,
        transactionId: transactionId,
        montoTotal: montoTotal,
        fechaCompra: DateTime.now(),
        fechaVisita: fechaVisita,
        estado: EstadoOrden.pagada,
        ticketIds: tickets.map((t) => t.id).toList(),
        cantidadEntradas: cantidadEntradas,
        cantidadCocheras: cantidadCocheras,
        totalPersonas: totalPersonas,
        nombreComprador: nombreComprador,
        dniComprador: dniComprador,
        emailComprador: emailComprador,
        telefonoComprador: telefonoComprador,
      );

      // Guardar orden
      await _firestore
          .collection(_ordenesCollection)
          .doc(ordenId)
          .set(orden.toMap());

      // Guardar tickets
      final batch = _firestore.batch();
      for (final ticket in tickets) {
        final ticketRef = _firestore.collection(_ticketsCollection).doc(ticket.id);
        batch.set(ticketRef, ticket.toMap());
      }
      await batch.commit();

      return orden;
    } catch (e) {
      throw Exception('Error al crear orden: $e');
    }
  }

  /// Obtener una orden por ID
  Future<OrdenCompra?> obtenerOrden(String ordenId) async {
    try {
      final doc = await _firestore
          .collection(_ordenesCollection)
          .doc(ordenId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return OrdenCompra.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener orden: $e');
    }
  }

  /// Obtener ticket por ID
  Future<Ticket?> obtenerTicket(String ticketId) async {
    try {
      final doc = await _firestore
          .collection(_ticketsCollection)
          .doc(ticketId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Ticket.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener ticket: $e');
    }
  }

  /// Cancelar una orden (y sus tickets)
  Future<void> cancelarOrden(String ordenId, String motivo) async {
    try {
      final orden = await obtenerOrden(ordenId);
      if (orden == null) {
        throw Exception('Orden no encontrada');
      }

      if (!orden.puedeCancelar) {
        throw Exception('La orden no puede ser cancelada');
      }

      // Actualizar orden
      await _firestore.collection(_ordenesCollection).doc(ordenId).update({
        'estado': EstadoOrden.cancelada.name,
        'fechaCancelacion': Timestamp.now(),
        'motivoCancelacion': motivo,
      });

      // Cancelar todos los tickets asociados
      final batch = _firestore.batch();
      for (final ticketId in orden.ticketIds) {
        final ticketRef = _firestore.collection(_ticketsCollection).doc(ticketId);
        batch.update(ticketRef, {
          'estado': EstadoTicket.cancelado.name,
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Error al cancelar orden: $e');
    }
  }
}
