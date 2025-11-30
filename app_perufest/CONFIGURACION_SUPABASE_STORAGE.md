# 📦 Configuración de Supabase Storage para PDFs

## ✅ Implementación Completada

Se ha migrado el sistema de almacenamiento de PDFs de **Base64 en Firestore** a **Supabase Storage** para solucionar el error de límite de tamaño (1MB en Firestore).

### 🎯 Ventajas de esta migración:
- ✅ Soporte para archivos hasta **5GB**
- ✅ URLs directas y públicas
- ✅ Mejor rendimiento
- ✅ **1GB gratis** en plan Supabase
- ✅ Tu PDF de 888KB funcionará perfectamente

---

## 🔧 Configuración en Supabase Dashboard (5 minutos)

### Paso 1: Acceder a Supabase Dashboard
1. Ve a: https://supabase.com/dashboard
2. Inicia sesión en tu proyecto
3. URL de tu proyecto: `https://miiavhizwsbjhqmwfsac.supabase.co`

### Paso 2: Crear Bucket de Storage
1. En el menú lateral, clic en **"Storage"**
2. Clic en **"Create a new bucket"**
3. Configuración del bucket:
   ```
   Name: eventos
   Public bucket: ✅ (MARCADO)
   File size limit: 5242880 (5MB en bytes)
   Allowed MIME types: application/pdf
   ```
4. Clic en **"Create bucket"**

### Paso 3: Configurar Políticas de Seguridad (Opcional)
Si quieres control más fino, puedes configurar policies:

```sql
-- Permitir lectura pública de PDFs
CREATE POLICY "PDFs públicos" ON storage.objects
FOR SELECT USING (bucket_id = 'eventos');

-- Permitir subida solo a usuarios autenticados (opcional)
CREATE POLICY "Subir PDFs autenticados" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'eventos' 
  AND auth.role() = 'authenticated'
);

-- Permitir actualización (upsert)
CREATE POLICY "Actualizar PDFs" ON storage.objects
FOR UPDATE USING (bucket_id = 'eventos');

-- Permitir eliminación
CREATE POLICY "Eliminar PDFs" ON storage.objects
FOR DELETE USING (bucket_id = 'eventos');
```

---

## 📝 Cambios Implementados en el Código

### 1. Nuevo Servicio: `supabase_storage_service.dart`
```dart
// Servicio para manejar archivos PDF en Supabase Storage
class SupabaseStorageService {
  Future<String?> subirPDF(File pdfFile, String eventoId);
  Future<bool> eliminarPDF(String eventoId);
  Future<bool> existePDF(String eventoId);
}
```

### 2. Modelo `Evento` Actualizado
```dart
class Evento {
  final String? pdfUrl;        // Nueva: URL de Supabase Storage
  final String? pdfBase64;     // Mantenida para compatibilidad
  final String? pdfNombre;     // Nombre del archivo
}
```

### 3. Servicios Actualizados
- ✅ `eventos_service.dart` - Soporta archivos PDF
- ✅ `eventos_viewmodel.dart` - Pasa archivos PDF
- ✅ `crear_evento_page.dart` - Usa archivos en lugar de Base64
- ✅ `editar_evento_page.dart` - Usa archivos en lugar de Base64
- ✅ `subir_pdf_widget.dart` - Retorna archivos File

---

## 🚀 Cómo Usar

### Crear Evento con PDF
```dart
final evento = Evento(...);
final pdfFile = File('ruta/al/archivo.pdf');

await eventosViewModel.crearEvento(evento, pdfFile: pdfFile);
```

### Actualizar Evento con PDF
```dart
await eventosViewModel.actualizarEvento(
  eventoId, 
  eventoActualizado,
  pdfFile: pdfFile
);
```

### Acceder al PDF
```dart
if (evento.pdfUrl != null) {
  // Abrir URL directamente en navegador o visor PDF
  launch(evento.pdfUrl!);
}
```

---

## 🔍 Verificación

### Comprobar que el bucket se creó correctamente:
1. Ve a Supabase Dashboard → Storage
2. Deberías ver el bucket **"eventos"**
3. Intenta crear un evento con PDF desde la app
4. Verifica en Storage → eventos → pdfs/
5. Deberías ver archivos con formato: `evento_[ID].pdf`

### Estructura de archivos en Storage:
```
eventos/
  └── pdfs/
      ├── evento_abc123.pdf
      ├── evento_def456.pdf
      └── evento_ghi789.pdf
```

---

## ⚠️ Migración de PDFs Existentes (Opcional)

Si tienes eventos con PDFs en Base64, puedes migrarlos:

```dart
// Script de migración (ejecutar una vez)
Future<void> migrarPDFsAStorage() async {
  final eventos = await EventosService.obtenerEventos();
  final supabaseService = SupabaseStorageService();
  
  for (var evento in eventos) {
    if (evento.pdfBase64 != null && evento.pdfUrl == null) {
      // Decodificar Base64
      final bytes = base64Decode(evento.pdfBase64!);
      
      // Crear archivo temporal
      final tempFile = File('${Directory.systemTemp.path}/temp_${evento.id}.pdf');
      await tempFile.writeAsBytes(bytes);
      
      // Subir a Storage
      final pdfUrl = await supabaseService.subirPDF(tempFile, evento.id);
      
      if (pdfUrl != null) {
        // Actualizar evento
        await FirebaseFirestore.instance
            .collection('eventos')
            .doc(evento.id)
            .update({
          'pdfUrl': pdfUrl,
          'pdfBase64': FieldValue.delete(), // Eliminar Base64
        });
        
        print('✅ Migrado: ${evento.nombre}');
      }
      
      // Limpiar archivo temporal
      await tempFile.delete();
    }
  }
}
```

---

## 🐛 Solución de Problemas

### Error: "Bucket not found"
- **Solución**: Verifica que creaste el bucket con nombre exacto `eventos`

### Error: "Permission denied"
- **Solución**: Marca el bucket como **Public** o configura las policies

### Error: "File too large"
- **Solución**: El límite es 5MB, comprime el PDF o aumenta el límite en Supabase

### PDF no se muestra
- **Solución**: Verifica que la URL sea pública: `Storage → eventos → Configuration → Public`

---

## 📊 Costos

### Plan Gratuito de Supabase:
- ✅ **1GB** de almacenamiento
- ✅ **2GB** de transferencia/mes
- ✅ Suficiente para **~1,000 PDFs** de 1MB cada uno

### Si necesitas más:
- Pro Plan: $25/mes
- Incluye: 100GB storage + 200GB bandwidth

---

## ✨ Próximos Pasos

1. ✅ Crear bucket en Supabase Dashboard
2. ✅ Probar subir un PDF desde la app
3. ✅ Verificar que aparece en Storage
4. ✅ Probar descargar/ver el PDF
5. 🔄 (Opcional) Migrar PDFs existentes

---

## 📞 Soporte

Si tienes problemas:
1. Revisa los logs en la consola
2. Verifica la configuración del bucket
3. Comprueba que Supabase está inicializado correctamente
4. Los PDFs ahora están en URLs como: 
   `https://miiavhizwsbjhqmwfsac.supabase.co/storage/v1/object/public/eventos/pdfs/evento_[ID].pdf`

---

## ✅ Estado de Implementación

- [x] Servicio de Supabase Storage creado
- [x] Modelo Evento actualizado con pdfUrl
- [x] EventosService modificado
- [x] EventosViewModel actualizado
- [x] Widget SubirPDF adaptado
- [x] Vista de crear evento actualizada
- [x] Vista de editar evento actualizada
- [x] Compatibilidad con pdfBase64 mantenida
- [ ] Bucket configurado en Supabase (pendiente tu acción)
- [ ] Prueba real con PDF de 888KB (pendiente)

🎉 **¡La implementación del código está completa!** Solo falta configurar el bucket en Supabase Dashboard.
