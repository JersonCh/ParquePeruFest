import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Servicio para envío de emails con comprobantes de tickets
/// 
/// NOTA: Esta implementación requiere configurar Firebase Cloud Functions
/// para el envío real de emails. El método actual solo registra la solicitud
/// en Firestore para que una Cloud Function la procese.
/// 
/// Alternativa: Usar un servicio de email como SendGrid, Mailgun, o 
/// implementar SMTP directo con el paquete 'mailer'.
class EmailService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Enviar ticket por email
  /// 
  /// Este método crea un documento en Firestore que será procesado por
  /// una Cloud Function configurada para enviar emails.
  /// 
  /// Para implementación completa:
  /// 1. Crear Cloud Function en Firebase
  /// 2. Configurar servicio de email (SendGrid/Mailgun)
  /// 3. La función escucha nuevos documentos en 'email_queue'
  /// 4. Envía el email y actualiza el estado
  Future<bool> enviarTicketPorEmail({
    required String destinatario,
    required String nombreDestinatario,
    required String ticketId,
    required String pdfPath,
    String? ordenId,
  }) async {
    try {
      // Leer el archivo PDF y convertirlo a base64 o subirlo a Storage
      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('Archivo PDF no encontrado');
      }

      // Crear solicitud de email en Firestore
      // Una Cloud Function procesará este documento
      await _firestore.collection('email_queue').add({
        'to': destinatario,
        'toName': nombreDestinatario,
        'subject': 'Tu ticket para Parque Perú - $ticketId',
        'ticketId': ticketId,
        'ordenId': ordenId,
        'pdfPath': pdfPath,
        'template': 'ticket_comprobante',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'retries': 0,
      });

      return true;
    } catch (e) {
      throw Exception('Error al enviar email: $e');
    }
  }

  /// Enviar orden completa por email
  Future<bool> enviarOrdenPorEmail({
    required String destinatario,
    required String nombreDestinatario,
    required String ordenId,
    required List<String> ticketIds,
    required String pdfPath,
    required double montoTotal,
  }) async {
    try {
      final pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        throw Exception('Archivo PDF no encontrado');
      }

      await _firestore.collection('email_queue').add({
        'to': destinatario,
        'toName': nombreDestinatario,
        'subject': 'Confirmación de compra - Orden $ordenId',
        'ordenId': ordenId,
        'ticketIds': ticketIds,
        'pdfPath': pdfPath,
        'montoTotal': montoTotal,
        'template': 'orden_confirmacion',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'retries': 0,
      });

      return true;
    } catch (e) {
      throw Exception('Error al enviar email de orden: $e');
    }
  }

  /// Verificar estado de envío de email
  Future<EmailStatus> verificarEstadoEmail(String emailQueueId) async {
    try {
      final doc = await _firestore
          .collection('email_queue')
          .doc(emailQueueId)
          .get();

      if (!doc.exists) {
        return EmailStatus.notFound;
      }

      final status = doc.data()?['status'] as String?;
      
      switch (status) {
        case 'sent':
          return EmailStatus.sent;
        case 'failed':
          return EmailStatus.failed;
        case 'pending':
          return EmailStatus.pending;
        default:
          return EmailStatus.unknown;
      }
    } catch (e) {
      throw Exception('Error al verificar estado de email: $e');
    }
  }
}

enum EmailStatus {
  pending,
  sent,
  failed,
  notFound,
  unknown,
}

/* 
 * EJEMPLO DE CLOUD FUNCTION PARA PROCESAR EMAILS:
 * 
 * Crear en functions/src/index.ts:
 * 
 * import * as functions from 'firebase-functions';
 * import * as admin from 'firebase-admin';
 * import * as sgMail from '@sendgrid/mail';
 * 
 * admin.initializeApp();
 * sgMail.setApiKey(functions.config().sendgrid.key);
 * 
 * export const processEmailQueue = functions.firestore
 *   .document('email_queue/{emailId}')
 *   .onCreate(async (snap, context) => {
 *     const data = snap.data();
 *     
 *     try {
 *       // Descargar PDF de Storage o usar el path
 *       const pdfBuffer = await admin.storage()
 *         .bucket()
 *         .file(data.pdfPath)
 *         .download();
 *       
 *       const msg = {
 *         to: data.to,
 *         from: 'tickets@parqueperu.com',
 *         subject: data.subject,
 *         text: `Hola ${data.toName}, adjuntamos tu ticket.`,
 *         html: `<p>Hola <strong>${data.toName}</strong>,</p>
 *                <p>Adjuntamos tu ticket para el Parque Perú.</p>`,
 *         attachments: [{
 *           content: pdfBuffer[0].toString('base64'),
 *           filename: `ticket-${data.ticketId}.pdf`,
 *           type: 'application/pdf',
 *           disposition: 'attachment',
 *         }],
 *       };
 *       
 *       await sgMail.send(msg);
 *       
 *       // Actualizar estado
 *       await snap.ref.update({
 *         status: 'sent',
 *         sentAt: admin.firestore.FieldValue.serverTimestamp(),
 *       });
 *       
 *     } catch (error) {
 *       console.error('Error sending email:', error);
 *       await snap.ref.update({
 *         status: 'failed',
 *         error: error.message,
 *         retries: admin.firestore.FieldValue.increment(1),
 *       });
 *     }
 *   });
 */
