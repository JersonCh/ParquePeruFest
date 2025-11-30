import 'package:cloud_firestore/cloud_firestore.dart';

class FAQ {
  final String id;
  final String pregunta;
  final String respuesta;
  final bool estado; // true = activa, false = inactiva
  final DateTime fechaCreacion;
  final DateTime fechaModificacion;
  final int orden; // Para ordenar las preguntas

  FAQ({
    required this.id,
    required this.pregunta,
    required this.respuesta,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaModificacion,
    this.orden = 0,
  });

  // Constructor para crear desde Firestore
  factory FAQ.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FAQ(
      id: doc.id,
      pregunta: data['pregunta'] ?? '',
      respuesta: data['respuesta'] ?? '',
      estado: data['estado'] ?? true,
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      fechaModificacion: (data['fechaModificacion'] as Timestamp).toDate(),
      orden: data['orden'] ?? 0,
    );
  }

  // Constructor para crear desde Map
  factory FAQ.fromMap(Map<String, dynamic> map, String id) {
    return FAQ(
      id: id,
      pregunta: map['pregunta'] ?? '',
      respuesta: map['respuesta'] ?? '',
      estado: map['estado'] ?? true,
      fechaCreacion: map['fechaCreacion'] is Timestamp 
          ? (map['fechaCreacion'] as Timestamp).toDate()
          : DateTime.parse(map['fechaCreacion']),
      fechaModificacion: map['fechaModificacion'] is Timestamp 
          ? (map['fechaModificacion'] as Timestamp).toDate()
          : DateTime.parse(map['fechaModificacion']),
      orden: map['orden'] ?? 0,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'pregunta': pregunta,
      'respuesta': respuesta,
      'estado': estado,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaModificacion': Timestamp.fromDate(fechaModificacion),
      'orden': orden,
    };
  }

  // Método para copiar con cambios
  FAQ copyWith({
    String? id,
    String? pregunta,
    String? respuesta,
    bool? estado,
    DateTime? fechaCreacion,
    DateTime? fechaModificacion,
    int? orden,
  }) {
    return FAQ(
      id: id ?? this.id,
      pregunta: pregunta ?? this.pregunta,
      respuesta: respuesta ?? this.respuesta,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaModificacion: fechaModificacion ?? this.fechaModificacion,
      orden: orden ?? this.orden,
    );
  }

  @override
  String toString() {
    return 'FAQ(id: $id, pregunta: $pregunta, estado: $estado, orden: $orden)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FAQ && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}