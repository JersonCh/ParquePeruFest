import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../viewmodels/comentarios_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/comentario.dart';
import 'opiniones_todas_page.dart';

class ComentariosView extends StatefulWidget {
  final String standId;
  final String standNombre;

  const ComentariosView({
    super.key,
    required this.standId,
    required this.standNombre,
  });

  @override
  State<ComentariosView> createState() => _ComentariosViewState();
}

class _ComentariosViewState extends State<ComentariosView> {
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  int _estrellas = 5;
  bool _enviando = false;

  late ComentariosViewModel _vm;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _vm = context.read<ComentariosViewModel>();
    _listener = () {
      if (mounted) setState(() {});
    };
    _vm.addListener(_listener);
    _vm.cargarComentariosPorStand(widget.standId);
  }

  @override
  void dispose() {
    _vm.removeListener(_listener);
    _textoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<ComentariosViewModel>();

    final publicos =
        vm.comentarios
            .where((c) => c.publico && c.standId == widget.standId)
            .toList();
    publicos.sort((a, b) => b.utilSi.compareTo(a.utilSi));
    final top3 = publicos.length <= 3 ? publicos : publicos.sublist(0, 3);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Header personalizado
          Container(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 122, 0, 37),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Valorar: ${widget.standNombre}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Para balancear el botón de atrás
                  ],
                ),
              ),
            ),
          ),
          
          // Contenido
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildResumen(vm),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildForm(auth, vm),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: Text(
                            'Opiniones públicas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (vm.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color.fromARGB(255, 122, 0, 37),
                              ),
                            ),
                          )
                        else if (publicos.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aún no hay comentarios.\nSé el primero en valorar.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(
                            top3.length,
                            (index) => _buildComentarioCard(top3[index], vm),
                          ),
                        if (publicos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(255, 122, 0, 37),
                                      const Color(0xFF8B1B1B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => OpinionesTodasPage(standId: widget.standId),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Ver todas las opiniones',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildResumen(ComentariosViewModel vm) {
    final comentariosStand =
        vm.comentarios.where((c) => c.standId == widget.standId).toList();
    final total = comentariosStand.length;
    final counts = List<int>.filled(6, 0);
    for (final c in comentariosStand) {
      if (c.estrellas >= 1 && c.estrellas <= 5) counts[c.estrellas]++;
    }
    final sum = comentariosStand.fold<int>(0, (s, c) => s + c.estrellas);
    final average = total == 0 ? 0.0 : sum / total;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Rating summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade50,
                    Colors.orange.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.shade100,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.amber.shade700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < average.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$total calificaciones',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            
            // Rating distribution
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  final count = counts[star];
                  final fraction = total == 0 ? 0.0 : count / total;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          alignment: Alignment.center,
                          child: Text(
                            '$star',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade500,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade200,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: fraction,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber.shade400,
                                      Colors.orange.shade500,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 24,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AuthViewModel auth, ComentariosViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade100,
                          Colors.amber.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'TU OPINIÓN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Rating stars
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final idx = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _estrellas = idx),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: idx <= _estrellas ? Colors.amber.shade50 : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          idx <= _estrellas ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: idx <= _estrellas ? Colors.amber.shade600 : Colors.grey.shade400,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Comment text field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: TextFormField(
                  controller: _textoController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu comentario (opcional)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                  validator: (v) {
                    if ((v ?? '').length > 1000) return 'Comentario demasiado largo';
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Submit button
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromARGB(255, 122, 0, 37),
                      const Color(0xFF8B1B1B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 122, 0, 37).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : () => _enviarComentario(auth, vm),
                  icon: _enviando 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                  label: Text(
                    _enviando ? 'Enviando...' : 'Enviar valoración',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComentarioCard(Comentario c, ComentariosViewModel vm) {
    final fecha = tz.TZDateTime.from(c.fecha.toUtc(), tz.local);
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';
    final voto = vm.getVotoUsuario(c.id, userId); // 'si', 'no' o null
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  c.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < c.estrellas ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (c.texto.isNotEmpty) Text(c.texto),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd/MM/yyyy - hh:mm a', 'es').format(fecha),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text('Esta opinión les resultó útil a ${c.utilSi} personas'),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('¿Te resultó útil esta opinión?'),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Si'),
                      if (voto == 'si') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, color: Colors.green, size: 18),
                      ],
                    ],
                  ),
                  selected: voto == 'si',
                  selectedColor: Colors.green.shade100,
                  onSelected: (selected) async {
                    if (selected && voto != 'si') {
                      final ok = await vm.marcarVotoUnico(
                        c.id,
                        userId,
                        'si',
                        voto,
                      );
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Gracias por tu opinión!'),
                          ),
                        );
                        vm.cargarComentariosPorStand(widget.standId);
                      }
                    }
                  },
                ),
                SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No'),
                      if (voto == 'no') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check, color: Colors.red, size: 18),
                      ],
                    ],
                  ),
                  selected: voto == 'no',
                  selectedColor: Colors.red.shade100,
                  onSelected: (selected) async {
                    if (selected && voto != 'no') {
                      final ok = await vm.marcarVotoUnico(
                        c.id,
                        userId,
                        'no',
                        voto,
                      );
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Gracias por tu opinión!'),
                          ),
                        );
                        vm.cargarComentariosPorStand(widget.standId);
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviarComentario(
    AuthViewModel auth,
    ComentariosViewModel vm,
  ) async {
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    final comentario = Comentario(
      id: '',
      standId: widget.standId,
      userId: auth.currentUser!.id,
      userName: auth.currentUser!.nombre,
      texto: _textoController.text.trim(),
      estrellas: _estrellas,
      fecha: DateTime.now().toUtc(),
      publico: true,
    );

    final ok = await vm.publicarComentario(comentario);
    setState(() => _enviando = false);
    if (ok) {
      _textoController.clear();
      setState(() => _estrellas = 5);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Valoración enviada')));
      vm.cargarComentariosPorStand(widget.standId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al enviar valoración')),
      );
    }
  }
}
