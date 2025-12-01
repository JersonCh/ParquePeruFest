import 'package:cloud_firestore/cloud_firestore.dart';

/// Estados de la orden de compra
enum EstadoOrden {
  pendiente,      // Pago en proceso
  pagada,         // Pago confirmado
  cancelada,      // Cancelada por usuario o timeout
  reembolsada,    // Reembolso procesado
}

/// Orden de compra que agrupa múltiples tickets
class OrdenCompra {
  final String id;
  final String userId;
  final String transactionId;
  final double montoTotal;
  final DateTime fechaCompra;
  final DateTime fechaVisita;
  final EstadoOrden estado;
  
  // Lista de IDs de tickets generados
  final List<String> ticketIds;
  
  // Resumen de la compra
  final int cantidadEntradas;
  final int cantidadCocheras;
  final int totalPersonas;
  
  // Datos del comprador principal
  final String nombreComprador;
  final String dniComprador;
  final String emailComprador;
  final String? telefonoComprador;
  
  // Metadata
  final DateTime? fechaCancelacion;
  final String? motivoCancelacion;
  final DateTime? fechaReembolso;

  OrdenCompra({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.montoTotal,
    required this.fechaCompra,
    required this.fechaVisita,
    this.estado = EstadoOrden.pendiente,
    required this.ticketIds,
    required this.cantidadEntradas,
    required this.cantidadCocheras,
    required this.totalPersonas,
    required this.nombreComprador,
    required this.dniComprador,
    required this.emailComprador,
    this.telefonoComprador,
    this.fechaCancelacion,
    this.motivoCancelacion,
    this.fechaReembolso,
  });

  /// Número de orden formateado
  String get numeroOrden => 'ORD-${id.substring(0, 8).toUpperCase()}';

  /// Verifica si la orden puede ser cancelada
  bool get puedeCancelar {
    return estado == EstadoOrden.pagada && 
           DateTime.now().isBefore(fechaVisita.subtract(const Duration(hours: 24)));
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'transactionId': transactionId,
      'montoTotal': montoTotal,
      'fechaCompra': Timestamp.fromDate(fechaCompra),
      'fechaVisita': Timestamp.fromDate(fechaVisita),
      'estado': estado.name,
      'ticketIds': ticketIds,
      'cantidadEntradas': cantidadEntradas,
      'cantidadCocheras': cantidadCocheras,
      'totalPersonas': totalPersonas,
      'nombreComprador': nombreComprador,
      'dniComprador': dniComprador,
      'emailComprador': emailComprador,
      'telefonoComprador': telefonoComprador,
      'fechaCancelacion': fechaCancelacion != null 
          ? Timestamp.fromDate(fechaCancelacion!) 
          : null,
      'motivoCancelacion': motivoCancelacion,
      'fechaReembolso': fechaReembolso != null 
          ? Timestamp.fromDate(fechaReembolso!) 
          : null,
    };
  }

  /// Crear desde Map de Firestore
  factory OrdenCompra.fromMap(Map<String, dynamic> map) {
    return OrdenCompra(
      id: map['id'] as String,
      userId: map['userId'] as String,
      transactionId: map['transactionId'] as String,
      montoTotal: (map['montoTotal'] as num).toDouble(),
      fechaCompra: (map['fechaCompra'] as Timestamp).toDate(),
      fechaVisita: (map['fechaVisita'] as Timestamp).toDate(),
      estado: EstadoOrden.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoOrden.pendiente,
      ),
      ticketIds: List<String>.from(map['ticketIds'] as List),
      cantidadEntradas: map['cantidadEntradas'] as int,
      cantidadCocheras: map['cantidadCocheras'] as int,
      totalPersonas: map['totalPersonas'] as int,
      nombreComprador: map['nombreComprador'] as String,
      dniComprador: map['dniComprador'] as String,
      emailComprador: map['emailComprador'] as String,
      telefonoComprador: map['telefonoComprador'] as String?,
      fechaCancelacion: map['fechaCancelacion'] != null
          ? (map['fechaCancelacion'] as Timestamp).toDate()
          : null,
      motivoCancelacion: map['motivoCancelacion'] as String?,
      fechaReembolso: map['fechaReembolso'] != null
          ? (map['fechaReembolso'] as Timestamp).toDate()
          : null,
    );
  }

  /// Copiar con modificaciones
  OrdenCompra copyWith({
    String? id,
    String? userId,
    String? transactionId,
    double? montoTotal,
    DateTime? fechaCompra,
    DateTime? fechaVisita,
    EstadoOrden? estado,
    List<String>? ticketIds,
    int? cantidadEntradas,
    int? cantidadCocheras,
    int? totalPersonas,
    String? nombreComprador,
    String? dniComprador,
    String? emailComprador,
    String? telefonoComprador,
    DateTime? fechaCancelacion,
    String? motivoCancelacion,
    DateTime? fechaReembolso,
  }) {
    return OrdenCompra(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionId: transactionId ?? this.transactionId,
      montoTotal: montoTotal ?? this.montoTotal,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaVisita: fechaVisita ?? this.fechaVisita,
      estado: estado ?? this.estado,
      ticketIds: ticketIds ?? this.ticketIds,
      cantidadEntradas: cantidadEntradas ?? this.cantidadEntradas,
      cantidadCocheras: cantidadCocheras ?? this.cantidadCocheras,
      totalPersonas: totalPersonas ?? this.totalPersonas,
      nombreComprador: nombreComprador ?? this.nombreComprador,
      dniComprador: dniComprador ?? this.dniComprador,
      emailComprador: emailComprador ?? this.emailComprador,
      telefonoComprador: telefonoComprador ?? this.telefonoComprador,
      fechaCancelacion: fechaCancelacion ?? this.fechaCancelacion,
      motivoCancelacion: motivoCancelacion ?? this.motivoCancelacion,
      fechaReembolso: fechaReembolso ?? this.fechaReembolso,
    );
  }
}
