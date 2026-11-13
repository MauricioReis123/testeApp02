import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OmniBackendUniversal {
  static String? _ipManualForcado;
  static String? _ipDinamicoDetectado;

  static const String _domainLocalhost = 'http://localhost';
  static const String _domainAndroidEmulator = 'http://10.0.2.2';
  static const String _domainProduction =
      'https://www.servshop.com.br';

  static const String _wpPath = '/servshop/wp-admin/admin-ajax.php';
  static const Duration _timeoutRequisicao =
      Duration(seconds: 15);
  static const Duration _timeoutVarredura =
      Duration(milliseconds: 700);

  /// Define o endereço manual do servidor.
  static void definirIpManual(String ipDigitado) {
    String ipLimpo = ipDigitado.trim();

    if (ipLimpo.isEmpty) {
      _ipManualForcado = null;
      _ipDinamicoDetectado = null;
      return;
    }

    if (!ipLimpo.startsWith('http://') &&
        !ipLimpo.startsWith('https://')) {
      ipLimpo = 'http://$ipLimpo';
    }

    while (ipLimpo.endsWith('/')) {
      ipLimpo = ipLimpo.substring(0, ipLimpo.length - 1);
    }

    final uri = Uri.tryParse(ipLimpo);

    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw FormatException(
        'Endereço IP ou URL inválida: $ipDigitado',
      );
    }

    _ipManualForcado = ipLimpo;
    _ipDinamicoDetectado = null;

    debugPrint('[OMNI] IP MANUAL: $_ipManualForcado');
  }

  static void limparCacheIp() {
    _ipDinamicoDetectado = null;
  }

  /// PRIORIDADE:
  /// 1. IP manual.
  /// 2. IP dinâmico encontrado.
  /// 3. Produção.
  /// 4. Localhost / emulador / varredura.
  static Future<String> get baseUrl async {
    // 1. PRIORIDADE ABSOLUTA: IP MANUAL.
    // Funciona também em APK RELEASE.
    if (_ipManualForcado != null &&
        _ipManualForcado!.isNotEmpty) {
      debugPrint(
        '[OMNI] UTILIZANDO IP MANUAL: $_ipManualForcado',
      );

      return _ipManualForcado!;
    }

    // 2. Cache de IP descoberto.
    if (_ipDinamicoDetectado != null) {
      return _ipDinamicoDetectado!;
    }

    // 3. Produção somente quando não existe IP manual.
    if (!kDebugMode) {
      return _domainProduction;
    }

    // 4. Windows Desktop.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.windows) {
      return _domainLocalhost;
    }

    // 5. Emulador Android.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android) {

      if (await _testarConexaoRapida(
        '$_domainAndroidEmulator$_wpPath',
      )) {
        _ipDinamicoDetectado = _domainAndroidEmulator;

        return _ipDinamicoDetectado!;
      }
    }

    // 6. Varredura de rede local.
    final subRedes = await _obterSubRedesLocais();

    for (final subRede in subRedes) {
      final ipEncontrado = await _varrerSubRede(subRede);

      if (ipEncontrado != null) {
        _ipDinamicoDetectado = ipEncontrado;

        return ipEncontrado;
      }
    }

    return _domainLocalhost;
  }

  /// Descobre sub-redes IPv4 privadas.
  static Future<List<String>> _obterSubRedesLocais() async {
    final List<String> subRedes = [];

    try {
      if (!kIsWeb) {
        final interfaces = await NetworkInterface.list(
          includeLoopback: false,
          type: InternetAddressType.IPv4,
        );

        for (final interface in interfaces) {
          for (final endereco in interface.addresses) {
            if (endereco.type != InternetAddressType.IPv4 ||
                endereco.isLoopback) {
              continue;
            }

            final partes = endereco.address.split('.');

            if (partes.length != 4) continue;

            final primeiro = int.tryParse(partes[0]) ?? 0;
            final segundo = int.tryParse(partes[1]) ?? 0;

            final privado =
                primeiro == 10 ||
                (primeiro == 172 &&
                    segundo >= 16 &&
                    segundo <= 31) ||
                (primeiro == 192 && segundo == 168);

            if (privado) {
              final subRede =
                  '${partes[0]}.${partes[1]}.${partes[2]}';

              if (!subRedes.contains(subRede)) {
                subRedes.add(subRede);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[OMNI] Erro de rede: $e');
    }

    if (subRedes.isEmpty) {
      subRedes.add('192.168.12');
    }

    return subRedes;
  }

  /// Varredura por lotes.
  static Future<String?> _varrerSubRede(
    String subRede,
  ) async {
    const int tamanhoLote = 32;

    for (int inicio = 1; inicio <= 254;
        inicio += tamanhoLote) {

      final int fim =
          (inicio + tamanhoLote - 1).clamp(1, 254).toInt();

      final List<Future<String?>> testes = [];

      for (int i = inicio; i <= fim; i++) {
        final ip = 'http://$subRede.$i';

        testes.add(_verificarServidor(ip));
      }

      final resultados = await Future.wait(testes);

      for (final resultado in resultados) {
        if (resultado != null) {
          return resultado;
        }
      }
    }

    return null;
  }

  static Future<String?> _verificarServidor(
    String ip,
  ) async {
    if (await _testarConexaoRapida('$ip$_wpPath')) {
      return ip;
    }

    return null;
  }

  /// Teste HTTP rápido.
  static Future<bool> _testarConexaoRapida(
    String url,
  ) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(_timeoutVarredura);

      return response.statusCode >= 200 &&
          response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  /// Monta a URL do WordPress.
  static Future<String> getWpAjaxUrl(
    String ajaxActionValue,
  ) async {
    final base = await baseUrl;

    final uri = Uri.parse('$base$_wpPath').replace(
      queryParameters: {
        'action': ajaxActionValue,
      },
    );

    return uri.toString();
  }

  /// Motor universal de transporte HTTP.
  static Future<Map<String, dynamic>> executar({
    required String ajaxActionValue,
    required String targetMethod,
    Map<String, dynamic> args =
        const <String, dynamic>{},
  }) async {
    String? fullUrl;

    try {
      final payloadJson = jsonEncode({
        'target_method': targetMethod,
        'args': args,
      });

      fullUrl = await getWpAjaxUrl(ajaxActionValue);

      debugPrint('================================');
      debugPrint('[OMNI] SERVIDOR: $fullUrl');
      debugPrint('[OMNI] MÉTODO: $targetMethod');
      debugPrint('[OMNI] PAYLOAD: $payloadJson');

      final response = await http
          .post(
            Uri.parse(fullUrl),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded; charset=UTF-8',
              'Accept': 'application/json',
            },
            body: {
              'payload': payloadJson,
            },
          )
          .timeout(_timeoutRequisicao);

      debugPrint('[OMNI] HTTP: ${response.statusCode}');
      debugPrint('[OMNI] RESPOSTA: ${response.body}');

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message':
              'Erro HTTP ${response.statusCode}.',
          'raw': response.body,
          'url': fullUrl,
        };
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': false,
        'message': 'Resposta JSON em formato inesperado.',
        'raw': response.body,
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message': 'Erro de interpretação JSON: ${e.message}',
        'url': fullUrl,
      };
    } on SocketException catch (e) {
      return {
        'success': false,
        'message':
            'Não foi possível alcançar o servidor Laragon.',
        'details': e.message,
        'url': fullUrl,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de comunicação: $e',
        'url': fullUrl,
      };
    }
  }
}