import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:lsp_protocol/src/diagnotic.dart';

class LanguageConnection {
  late Process proc;

  Future<void> connect([String? projectRoot]) async {
    return Process.start(
      Platform.environment['YARC_LS_PATH'] ?? 'clangd',
      [
        "--project-root=${projectRoot ?? Directory.current.path}",
        "--enable-config",
        "--remote-index-address=${projectRoot ?? Directory.current.path}"
      ],
      mode: ProcessStartMode.normal,
    ).then((value) => _initializeProc(value));
  }

  Future<void> _initializeProc(Process proc) async {
    this.proc = proc;
    proc.stderr.listen((event) {
      print(String.fromCharCodes(event));
    });
    proc.stdout.listen((event) {
      String str = _buffer + String.fromCharCodes(event);
      if (_contentLength == -1) {
        final List<String> lines = str.split("\r\n");
        for (String line in lines) {
          if (line.startsWith("Content-Length: ")) {
            _contentLength = int.parse(line.substring(16));
            break;
          }
        }
        if (_contentLength == -1) {
          _buffer = str;
          return;
        }
        str = lines.sublist(2).join("\r\n");
      }
      if (str.length < _contentLength) {
        _buffer = str;
        return;
      }
      _buffer = "";
      final dynamic json = JsonDecoder().convert(str);
      _streamWaiter.complete(json);
      _streamWaiter = Completer();
      _contentLength = -1;
      _processResponse(json);
    });
    proc.exitCode.then((value) {
      if (value != 0) {
        throw Exception("Language Server exited with code   $value");
      }
    });
  }

  Future<dynamic> _send(dynamic data) async {
    final message = JsonEncoder().convert(data);
    proc.stdin.write(
      "Content-Length: ${message.length}\r\nContent-Type: application/vscode-jsonrpc; charset=utf-8\r\n\r\n$message",
    );
    await proc.stdin.flush();
    return _streamWaiter.future;
  }

  int _generateID() {
    return random.nextInt(1 << 30);
  }

  Future<dynamic> _waitID(int id) async {
    dynamic response = await _streamWaiter.future;
    while (response["id"] != id) {
      response = await _streamWaiter.future;
    }
    return response;
  }

  Future<dynamic> requestInitialize(String uri) async {
    final int id = _generateID();
    _send({
      "jsonrpc": "2.0",
      "method": "initialize",
      "id": id,
      "params": {
        "processId": pid,
        "rootUri": uri,
        "capabilities": {
          "textDocument": {
            "completion": {
              "completionItem": {"snippetSupport": true}
            }
          }
        },
        "trace": "off",
        "workspaceFolders": null
      },
    });
    return await _waitID(id);
  }

  Future<dynamic> notifyOpenSource(String uri, String text) async {
    return _send({
      "jsonrpc": "2.0",
      "method": "textDocument/didOpen",
      "params": {
        "textDocument": {
          "uri": uri,
          "languageId": "cpp",
          "version": 1,
          "text": text
        }
      }
    });
  }

  Future<dynamic> notifyChangeSource(
      String uri, int line, int character, int length, String text) async {
    return _send({
      "jsonrpc": "2.0",
      "method": "textDocument/didChange",
      "params": {
        "textDocument": {"uri": uri},
        "contentChanges": [
          {
            "range": {
              "start": {"line": line, "character": character},
              "end": {"line": line, "character": character + length}
            },
            "rangeLength": length,
            "text": text
          }
        ]
      }
    });
  }

  Future<dynamic> requestCompletion(String uri, int line, int character) async {
    final int id = _generateID();
    _send({
      "jsonrpc": "2.0",
      "method": "textDocument/completion",
      "id": id,
      "params": {
        "textDocument": {"uri": uri},
        "position": {"line": line, "character": character},
        "context": {"triggerKind": 1}
      }
    });
    return await _waitID(id);
  }

  Future<dynamic> inlayHint(String uri, int line, int character) async {
    return _send({
      "jsonrpc": "2.0",
      "method": "textDocument/inlayHint",
      "params": {
        "textDocument": {"uri": uri},
        "range": {
          "start": {"line": line, "character": character},
          "end": {"line": line, "character": character}
        }
      }
    });
  }

  void _processResponse(dynamic response) {
    if (response["method"] == "textDocument/publishDiagnostics") {
      _diagnostic = PublishDiagnostics.fromJson(response["params"]);
    }
  }

  PublishDiagnostics get latestDiagnostic => _diagnostic as PublishDiagnostics;

  Future<void> close() async {
    await proc.stdin.close();
    proc.kill();
  }

  void addStderrHandler(void Function(String) handler) {
    stderrHandlers.add(handler);
  }

  List<void Function(String)> stderrHandlers = [];
  Completer<dynamic> _streamWaiter = Completer();
  String _buffer = "";
  int _contentLength = -1;
  Random random = Random();
  PublishDiagnostics? _diagnostic;
}
