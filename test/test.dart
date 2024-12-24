import 'dart:io';

import 'package:lsp_protocol/lsp_protocol.dart';

void main() async {
  print("Use .clangd: ${Directory.current.path}/.clangd");
  LanguageConnection connection = LanguageConnection();
  await connection.connect();
  await connection.requestInitialize("file:///${Directory.current.path}/test");
  await connection.notifyOpenSource("file:///${Directory.current.path}/test/Main.cpp", File("./test/Main.cpp").readAsStringSync());
  for (var diagnostic in connection.latestDiagnostic.diagnostics) {
    print("${diagnostic.severity.toString()}: ${diagnostic.message}");
  }
}
