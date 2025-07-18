import 'package:logger/logger.dart';

class LoggerReactivation {
  static final _logger = Logger();

  static void logGene(String geneName, {String? userId, Map<String, dynamic>? data}) {
    _logger.i('[GENE] $geneName chamado por $userId | Dados: ${data ?? '---'}');
  }
}

