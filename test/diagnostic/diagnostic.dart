import 'package:test/test.dart';
import 'dart:io';

import 'package:y_lsp_protocol_client/lsp_protocol.dart';

void main() async {
  print("Use .clangd: ${Directory.current.path}/.clangd");
  LanguageConnection connection = LanguageConnection();
  await connection.connect();
  await connection.requestInitialize("file:///${Directory.current.path}/test");
  await connection.notifyOpenSource(
      "file:///${Directory.current.path}/test/Main.cpp",
      File("./test/Main.cpp").readAsStringSync());
  test('Diagnostic Expect No Error', () async {
    expect(connection.latestDiagnostic.diagnostics.length, equals(0));
  });
}
