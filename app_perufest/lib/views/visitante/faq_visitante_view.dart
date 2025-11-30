import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/faq_viewmodel.dart';
import '../../models/faq.dart';

class FAQVisitanteView extends StatefulWidget {
  const FAQVisitanteView({super.key});

  @override
  State<FAQVisitanteView> createState() => _FAQVisitanteViewState();
}

class _FAQVisitanteViewState extends State<FAQVisitanteView> {
  final TextEditingController _busquedaController = TextEditingController();
  List<FAQ> _faqsFiltradas = [];
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _buscarFAQs(String texto) async {
    if (texto.isEmpty) {
      setState(() {
        _faqsFiltradas = [];
        _buscando = false;
      });
      return;
    }

    setState(() {
      _buscando = true;
    });

    final faqViewModel = context.read<FAQViewModel>();
    final resultados = await faqViewModel.buscarFAQs(texto);

    setState(() {
      _faqsFiltradas = resultados;
      _buscando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<FAQViewModel>(
        builder: (context, faqViewModel, child) {
          return StreamBuilder<List<FAQ>>(
            stream: faqViewModel.streamFAQsActivas,
            builder: (context, snapshot) {
              // Manejar estados del stream
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B1B1B)),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar FAQs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              final faqsActivas = snapshot.data ?? [];
              
              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildBusqueda()),
                  if (_busquedaController.text.isNotEmpty && _faqsFiltradas.isEmpty && !_buscando)
                    _buildNoResultados()
                  else if (_busquedaController.text.isNotEmpty)
                    _buildFAQsList(_faqsFiltradas)
                  else if (faqsActivas.isEmpty)
                    _buildEmptyState()
                  else
                    _buildFAQsList(faqsActivas),
                  _buildSoporteSection(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF8B1B1B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Preguntas Frecuentes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(127, 0, 0, 0),
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF8B1B1B).withOpacity(0.9),
                const Color(0xFF8B1B1B),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Icon(
                  Icons.help_center,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              const Positioned(
                bottom: 60,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encuentra respuestas a',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      'tus preguntas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusqueda() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _busquedaController,
        decoration: InputDecoration(
          hintText: 'Buscar preguntas...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF8B1B1B)),
          suffixIcon: _busquedaController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busquedaController.clear();
                    _buscarFAQs('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF8B1B1B), width: 2),
          ),
          fillColor: Colors.white,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: _buscarFAQs,
      ),
    );
  }

  Widget _buildFAQsList(List<FAQ> faqs) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildFAQCard(faqs[index], index),
          childCount: faqs.length,
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQ faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B1B1B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFF8B1B1B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          faq.pregunta,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              faq.respuesta,
              style: const TextStyle(
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultados() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron resultados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otras palabras clave',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.help_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay preguntas frecuentes disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vuelve más tarde o contacta con el soporte',
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoporteSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B1B1B),
              const Color(0xFF8B1B1B).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.support_agent,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Tienes más preguntas?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Estamos aquí para ayudarte. Contáctanos en cualquier momento.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _contactarWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _contactarEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8B1B1B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    icon: const Icon(Icons.email),
                    label: const Text('Email'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _contactarWhatsApp() async {
    const telefono = '+51987654321'; // Cambia por el número real
    const mensaje = 'Hola, tengo una pregunta sobre el PeruFest 2025';
    final url = 'https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _mostrarError('No se puede abrir WhatsApp');
      }
    } catch (e) {
      _mostrarError('Error al abrir WhatsApp');
    }
  }

  void _contactarEmail() async {
    const email = 'soporte@perufest.com'; // Cambia por el email real
    const asunto = 'Consulta PeruFest 2025';
    final url = 'mailto:$email?subject=${Uri.encodeComponent(asunto)}';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _mostrarError('No se puede abrir el cliente de email');
      }
    } catch (e) {
      _mostrarError('Error al abrir el email');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }
}