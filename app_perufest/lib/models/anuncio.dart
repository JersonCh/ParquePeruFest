import 'package:cloud_firestore/cloud_firestore.dart';

class Anuncio {
  final String id;
  final String titulo;
  final String contenido;
  final String? imagenUrl;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String posicion; // 'superior' o 'inferior'
  final bool activo;
  final int orden; // Para el orden de rotación
  final DateTime fechaCreacion;
  final String creadoPor; // ID del usuario administrador

  Anuncio({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.imagenUrl,
    required this.fechaInicio,
    required this.fechaFin,
    required this.posicion,
    required this.activo,
    required this.orden,
    required this.fechaCreacion,
    required this.creadoPor,
  });

  // Crear desde Firestore
  factory Anuncio.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return Anuncio(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      contenido: data['contenido'] ?? '',
      imagenUrl: data['imagenUrl'],
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      posicion: data['posicion'] ?? 'superior',
      activo: data['activo'] ?? false,
      orden: data['orden'] ?? 0,
      fechaCreacion: (data['fechaCreacion'] as Timestamp).toDate(),
      creadoPor: data['creadoPor'] ?? '',
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'contenido': contenido,
      'imagenUrl': imagenUrl,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'posicion': posicion,
      'activo': activo,
      'orden': orden,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'creadoPor': creadoPor,
    };
  }

  // Verificar si el anuncio está vigente
  bool get esVigente {
    final ahora = DateTime.now();
    return activo && 
           ahora.isAfter(fechaInicio) && 
           ahora.isBefore(fechaFin);
  }

  // Crear copia con cambios
  Anuncio copyWith({
    String? id,
    String? titulo,
    String? contenido,
    String? imagenUrl,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? posicion,
    bool? activo,
    int? orden,
    DateTime? fechaCreacion,
    String? creadoPor,
  }) {
    return Anuncio(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      posicion: posicion ?? this.posicion,
      activo: activo ?? this.activo,
      orden: orden ?? this.orden,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      creadoPor: creadoPor ?? this.creadoPor,
    );
  }
}