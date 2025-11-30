import 'package:cloud_firestore/cloud_firestore.dart';

class Noticia {
  final String id;
  final String titulo;
  final String textoCorto;
  final String descripcion;
  final String? imagenUrl;
  final String? enlaceExterno;
  final DateTime fechaPublicacion;
  final String autorId;
  final String autorNombre;

  Noticia({
    required this.id,
    required this.titulo,
    required this.textoCorto,
    required this.descripcion,
    this.imagenUrl,
    this.enlaceExterno,
    required this.fechaPublicacion,
    required this.autorId,
    required this.autorNombre,
  });

  factory Noticia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Noticia(
      id: doc.id,
      titulo: data['titulo'] ?? '',
      textoCorto: data['textoCorto'] ?? '',
      descripcion: data['descripcion'] ?? '',
      imagenUrl: data['imagenUrl'],
      enlaceExterno: data['enlaceExterno'],
      fechaPublicacion: (data['fechaPublicacion'] as Timestamp).toDate(),
      autorId: data['autorId'] ?? '',
      autorNombre: data['autorNombre'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'titulo': titulo,
      'textoCorto': textoCorto,
      'descripcion': descripcion,
      'imagenUrl': imagenUrl,
      'enlaceExterno': enlaceExterno,
      'fechaPublicacion': Timestamp.fromDate(fechaPublicacion),
      'autorId': autorId,
      'autorNombre': autorNombre,
    };
  }

  @override
  String toString() {
    return 'Noticia(id: $id, titulo: $titulo, autor: $autorNombre)';
  }
}