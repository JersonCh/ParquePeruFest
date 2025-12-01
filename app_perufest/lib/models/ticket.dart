import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de entrada disponibles
enum TipoEntrada {
  entrada,    // Solo ingreso al parque
  cochera,    // Solo estacionamiento
  combo       // Entrada + Cochera
}

/// Tipos de ticket según cantidad de personas
enum TipoTicket {
  individual,    // 1 persona, 1 QR
  grupal,        // N personas, 1 QR compartido
  multiple       // N personas, N QRs individuales
}

/// Estados del ticket
enum EstadoTicket {
  pendiente,    // Pago en proceso
  pagado,       // Pagado pero no usado
  usado,        // Ya validado en puerta
  cancelado,    // Cancelado por usuario
  expirado      // Pasó la fecha de validez
}

/// Tipos de persona para clasificación
enum TipoPersona {
  adulto,
  nino,           // Podría tener precio diferencial en el futuro
  adultoMayor,    // Podría tener descuento en el futuro
  estudiante      // Para promociones futuras
}

/// Tipos de vehículo
enum TipoVehiculo {
  automovil,
  camioneta,
  motocicleta,
  otro
}

/// Modelo principal del Ticket
class Ticket {
  final String id;
  final String userId;
  final String transactionId;
  final TipoEntrada tipo;
  
  // Campos para compras múltiples
  final int cantidadPersonas;
  final TipoTicket tipoTicket;
  final List<PersonaTicket>? personas;
  
  final double monto;
  final DateTime fechaCompra;
  final DateTime fechaValidez;
  
  // Datos del comprador/responsable
  final String nombreComprador;
  final String dniComprador;
  final String emailComprador;
  final String? telefonoComprador;
  
  // Cochera
  final String? placaVehiculo;
  final TipoVehiculo? tipoVehiculo;
  final int? cantidadVehiculos;
  
  final EstadoTicket estado;
  final DateTime? fechaValidacion;
  final String? validadoPor;
  final String qrData;
  
  // Contador de usos para tickets grupales
  final int usosRestantes;
  final int usosRealizados;
  
  // ID de la orden a la que pertenece
  final String? ordenId;

  Ticket({
    required this.id,
    required this.userId,
    required this.transactionId,
    required this.tipo,
    this.cantidadPersonas = 1,
    this.tipoTicket = TipoTicket.individual,
    this.personas,
    required this.monto,
    required this.fechaCompra,
    required this.fechaValidez,
    required this.nombreComprador,
    required this.dniComprador,
    required this.emailComprador,
    this.telefonoComprador,
    this.placaVehiculo,
    this.tipoVehiculo,
    this.cantidadVehiculos,
    this.estado = EstadoTicket.pendiente,
    this.fechaValidacion,
    this.validadoPor,
    required this.qrData,
    this.usosRestantes = 0,
    this.usosRealizados = 0,
    this.ordenId,
  });

  /// Prefijo del ID según tipo de entrada
  String get prefijoId {
    switch (tipo) {
      case TipoEntrada.entrada:
        return 'TKT-ENT';
      case TipoEntrada.cochera:
        return 'TKT-COC';
      case TipoEntrada.combo:
        return 'TKT-CMB';
    }
  }

  /// Color del tema según tipo
  Color get colorTema {
    switch (tipo) {
      case TipoEntrada.entrada:
        return const Color(0xFF4CAF50); // Verde
      case TipoEntrada.cochera:
        return const Color(0xFFFF9800); // Naranja
      case TipoEntrada.combo:
        return const Color(0xFF9C27B0); // Morado
    }
  }

  /// Icono según tipo
  IconData get icono {
    switch (tipo) {
      case TipoEntrada.entrada:
        return Icons.confirmation_number;
      case TipoEntrada.cochera:
        return Icons.local_parking;
      case TipoEntrada.combo:
        return Icons.card_giftcard;
    }
  }

  /// Título descriptivo del ticket
  String get titulo {
    if (tipoTicket == TipoTicket.grupal) {
      switch (tipo) {
        case TipoEntrada.entrada:
          return 'ENTRADA GRUPAL';
        case TipoEntrada.cochera:
          return 'COCHERA';
        case TipoEntrada.combo:
          return 'COMBO FAMILIAR';
      }
    } else {
      switch (tipo) {
        case TipoEntrada.entrada:
          return 'ENTRADA AL PARQUE';
        case TipoEntrada.cochera:
          return 'ESTACIONAMIENTO';
        case TipoEntrada.combo:
          return 'COMBO COMPLETO';
      }
    }
  }

  /// Verifica si el ticket está activo y puede usarse
  bool get estaActivo {
    return estado == EstadoTicket.pagado && 
           DateTime.now().isBefore(fechaValidez.add(const Duration(days: 1)));
  }

  /// Verifica si el ticket ya expiró
  bool get estaExpirado {
    return DateTime.now().isAfter(fechaValidez.add(const Duration(days: 1)));
  }

  /// ID formateado para mostrar
  String get idFormateado {
    return '$prefijoId-${id.substring(0, 8).toUpperCase()}';
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'transactionId': transactionId,
      'tipo': tipo.name,
      'cantidadPersonas': cantidadPersonas,
      'tipoTicket': tipoTicket.name,
      'personas': personas?.map((p) => p.toMap()).toList(),
      'monto': monto,
      'fechaCompra': Timestamp.fromDate(fechaCompra),
      'fechaValidez': Timestamp.fromDate(fechaValidez),
      'nombreComprador': nombreComprador,
      'dniComprador': dniComprador,
      'emailComprador': emailComprador,
      'telefonoComprador': telefonoComprador,
      'placaVehiculo': placaVehiculo,
      'tipoVehiculo': tipoVehiculo?.name,
      'cantidadVehiculos': cantidadVehiculos,
      'estado': estado.name,
      'fechaValidacion': fechaValidacion != null 
          ? Timestamp.fromDate(fechaValidacion!) 
          : null,
      'validadoPor': validadoPor,
      'qrData': qrData,
      'usosRestantes': usosRestantes,
      'usosRealizados': usosRealizados,
      'ordenId': ordenId,
    };
  }

  /// Crear desde Map de Firestore
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as String,
      userId: map['userId'] as String,
      transactionId: map['transactionId'] as String,
      tipo: TipoEntrada.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoEntrada.entrada,
      ),
      cantidadPersonas: map['cantidadPersonas'] as int? ?? 1,
      tipoTicket: TipoTicket.values.firstWhere(
        (e) => e.name == map['tipoTicket'],
        orElse: () => TipoTicket.individual,
      ),
      personas: map['personas'] != null
          ? (map['personas'] as List).map((p) => PersonaTicket.fromMap(p)).toList()
          : null,
      monto: (map['monto'] as num).toDouble(),
      fechaCompra: (map['fechaCompra'] as Timestamp).toDate(),
      fechaValidez: (map['fechaValidez'] as Timestamp).toDate(),
      nombreComprador: map['nombreComprador'] as String,
      dniComprador: map['dniComprador'] as String,
      emailComprador: map['emailComprador'] as String,
      telefonoComprador: map['telefonoComprador'] as String?,
      placaVehiculo: map['placaVehiculo'] as String?,
      tipoVehiculo: map['tipoVehiculo'] != null
          ? TipoVehiculo.values.firstWhere(
              (e) => e.name == map['tipoVehiculo'],
              orElse: () => TipoVehiculo.automovil,
            )
          : null,
      cantidadVehiculos: map['cantidadVehiculos'] as int?,
      estado: EstadoTicket.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoTicket.pendiente,
      ),
      fechaValidacion: map['fechaValidacion'] != null
          ? (map['fechaValidacion'] as Timestamp).toDate()
          : null,
      validadoPor: map['validadoPor'] as String?,
      qrData: map['qrData'] as String,
      usosRestantes: map['usosRestantes'] as int? ?? 0,
      usosRealizados: map['usosRealizados'] as int? ?? 0,
      ordenId: map['ordenId'] as String?,
    );
  }

  /// Copiar con modificaciones
  Ticket copyWith({
    String? id,
    String? userId,
    String? transactionId,
    TipoEntrada? tipo,
    int? cantidadPersonas,
    TipoTicket? tipoTicket,
    List<PersonaTicket>? personas,
    double? monto,
    DateTime? fechaCompra,
    DateTime? fechaValidez,
    String? nombreComprador,
    String? dniComprador,
    String? emailComprador,
    String? telefonoComprador,
    String? placaVehiculo,
    TipoVehiculo? tipoVehiculo,
    int? cantidadVehiculos,
    EstadoTicket? estado,
    DateTime? fechaValidacion,
    String? validadoPor,
    String? qrData,
    int? usosRestantes,
    int? usosRealizados,
    String? ordenId,
  }) {
    return Ticket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      transactionId: transactionId ?? this.transactionId,
      tipo: tipo ?? this.tipo,
      cantidadPersonas: cantidadPersonas ?? this.cantidadPersonas,
      tipoTicket: tipoTicket ?? this.tipoTicket,
      personas: personas ?? this.personas,
      monto: monto ?? this.monto,
      fechaCompra: fechaCompra ?? this.fechaCompra,
      fechaValidez: fechaValidez ?? this.fechaValidez,
      nombreComprador: nombreComprador ?? this.nombreComprador,
      dniComprador: dniComprador ?? this.dniComprador,
      emailComprador: emailComprador ?? this.emailComprador,
      telefonoComprador: telefonoComprador ?? this.telefonoComprador,
      placaVehiculo: placaVehiculo ?? this.placaVehiculo,
      tipoVehiculo: tipoVehiculo ?? this.tipoVehiculo,
      cantidadVehiculos: cantidadVehiculos ?? this.cantidadVehiculos,
      estado: estado ?? this.estado,
      fechaValidacion: fechaValidacion ?? this.fechaValidacion,
      validadoPor: validadoPor ?? this.validadoPor,
      qrData: qrData ?? this.qrData,
      usosRestantes: usosRestantes ?? this.usosRestantes,
      usosRealizados: usosRealizados ?? this.usosRealizados,
      ordenId: ordenId ?? this.ordenId,
    );
  }
}

/// Información de cada persona en tickets múltiples
class PersonaTicket {
  final String nombre;
  final String? dni;
  final String ticketId;
  final String qrData;
  final bool validado;
  final DateTime? fechaIngreso;
  final TipoPersona tipo;

  PersonaTicket({
    required this.nombre,
    this.dni,
    required this.ticketId,
    required this.qrData,
    this.validado = false,
    this.fechaIngreso,
    this.tipo = TipoPersona.adulto,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'dni': dni,
      'ticketId': ticketId,
      'qrData': qrData,
      'validado': validado,
      'fechaIngreso': fechaIngreso != null 
          ? Timestamp.fromDate(fechaIngreso!) 
          : null,
      'tipo': tipo.name,
    };
  }

  factory PersonaTicket.fromMap(Map<String, dynamic> map) {
    return PersonaTicket(
      nombre: map['nombre'] as String,
      dni: map['dni'] as String?,
      ticketId: map['ticketId'] as String,
      qrData: map['qrData'] as String,
      validado: map['validado'] as bool? ?? false,
      fechaIngreso: map['fechaIngreso'] != null
          ? (map['fechaIngreso'] as Timestamp).toDate()
          : null,
      tipo: TipoPersona.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoPersona.adulto,
      ),
    );
  }

  PersonaTicket copyWith({
    String? nombre,
    String? dni,
    String? ticketId,
    String? qrData,
    bool? validado,
    DateTime? fechaIngreso,
    TipoPersona? tipo,
  }) {
    return PersonaTicket(
      nombre: nombre ?? this.nombre,
      dni: dni ?? this.dni,
      ticketId: ticketId ?? this.ticketId,
      qrData: qrData ?? this.qrData,
      validado: validado ?? this.validado,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      tipo: tipo ?? this.tipo,
    );
  }
}
