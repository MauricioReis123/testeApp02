import 'dart:convert';

import 'package:flutter/material.dart';

import 'tools/backends_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MeuAppTesteBackend());
}

class MeuAppTesteBackend extends StatelessWidget {
  const MeuAppTesteBackend({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const TelaTesteBackend(),
    );
  }
}

class TelaTesteBackend extends StatefulWidget {
  const TelaTesteBackend({super.key});

  @override
  State<TelaTesteBackend> createState() =>
      _TelaTesteBackendState();
}

class _TelaTesteBackendState extends State<TelaTesteBackend> {

  // IP FIXO PARA TESTES COM O LARAGON.
  static const String _ipServidorTeste = '192.168.12.8';

  late final TextEditingController _ipController;

  String _statusMensagem =
      'Aguardando execução do teste de conexão...';

  bool _carregando = false;

  bool? _conexaoSucesso;

  @override
  void initState() {
    super.initState();

    // Inicializa o campo com o IP do notebook.
    _ipController = TextEditingController(
      text: _ipServidorTeste,
    );

    // Define imediatamente o IP manual no serviço.
    OmniBackendUniversal.definirIpManual(
      _ipServidorTeste,
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  /// Executa o teste de comunicação com o PHP.
  Future<void> _testarConexaoBackend() async {

    if (_carregando) return;

    try {
      // Se o campo estiver vazio, utiliza o IP fixo.
      String ip = _ipController.text.trim();

      if (ip.isEmpty) {
        ip = _ipServidorTeste;
        _ipController.text = ip;
      }

      // Força o IP manual antes de qualquer requisição.
      OmniBackendUniversal.definirIpManual(ip);

      setState(() {
        _carregando = true;
        _conexaoSucesso = null;

        _statusMensagem =
            'Conectando ao servidor...\n\n'
            'IP selecionado: $ip\n'
            'Aguardando resposta do WordPress...';
      });

      final respostaTeste =
          await OmniBackendUniversal.executar(
        ajaxActionValue: 'omni_testes_router',

        targetMethod: 'teste_backend',

        args: {
          'prompt':
              'Escreva um texto persuasivo para anúncio '
              'de fone de ouvido sem fio.',

          'system_role':
              'Você é um copywriter de elite em e-commerce.',
        },
      );

      if (!mounted) return;

      final bool sucesso =
          respostaTeste['success'] == true;

      setState(() {
        _conexaoSucesso = sucesso;

        _statusMensagem =
            '${sucesso ? "CONEXÃO REALIZADA" : "RESPOSTA DO SERVIDOR"}\n'
            '========================================\n\n'
            '${jsonEncodePretty(respostaTeste)}';
      });

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _conexaoSucesso = false;
        _statusMensagem =
            'ERRO AO EXECUTAR TESTE:\n\n$e';
      });

    } finally {

      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  /// Formata JSON.
  String jsonEncodePretty(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent(' ');

    return encoder.convert(json);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: const Text(
          'Teste Backend Universal',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              // IDENTIFICAÇÃO DO SERVIDOR.
              Text(
                'CONFIGURAÇÃO DO SERVIDOR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 10),

              // CAMPO DE IP.
              TextField(
                controller: _ipController,

                enabled: !_carregando,

                keyboardType: TextInputType.url,

                decoration: InputDecoration(
                  labelText: 'IP do Notebook / Laragon',

                  hintText: '192.168.12.8',

                  prefixIcon: const Icon(
                    Icons.router,
                    color: Colors.indigo,
                  ),

                  filled: true,

                  fillColor: Colors.indigo.withValues(
                    alpha: 0.04,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // BOTÃO DE EXECUÇÃO.
              SizedBox(
                height: 54,

                child: ElevatedButton.icon(
                  onPressed: _carregando
                      ? null
                      : _testarConexaoBackend,

                  icon: _carregando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),

                  label: Text(
                    _carregando
                        ? 'Conectando...'
                        : 'Executar Teste Backend',
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // CABEÇALHO DO PAINEL.
              Row(
                children: [
                  const Icon(
                    Icons.terminal,
                    color: Colors.indigo,
                  ),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      'LOG DE COMUNICAÇÃO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),

                  if (_conexaoSucesso != null)
                    Icon(
                      _conexaoSucesso!
                          ? Icons.check_circle
                          : Icons.error_outline,
                      color: _conexaoSucesso!
                          ? Colors.green
                          : Colors.red,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // PAINEL DE RESPOSTA RESPONSIVO.
              Expanded(
                child: Container(
                  width: double.infinity,

                  decoration: BoxDecoration(
                    color: const Color(0xFF17191F),

                    borderRadius: BorderRadius.circular(14),

                    border: Border.all(
                      color: Colors.white12,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      // BARRA SUPERIOR DO TERMINAL.
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),

                        decoration: const BoxDecoration(
                          color: Color(0xFF252A33),

                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Text(
                                'OMNI BACKEND CONSOLE',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ÁREA ROLÁVEL DO RESULTADO.
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),

                          child: SelectableText(
                            _statusMensagem,

                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              height: 1.6,
                              color: Color(0xFF65E6B0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
