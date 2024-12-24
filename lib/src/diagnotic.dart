import 'package:y_lsp_protocol_client/src/types.dart';

enum DiagnosticSeverity {
  error(1),
  warning(2),
  information(3),
  hint(4);

  const DiagnosticSeverity(this.value);

  final int value;
}

enum DiagnoticTag {
  unnecessary(1),
  deprecated(2);

  const DiagnoticTag(this.value);

  final int value;
}

class CodeDescription {
  CodeDescription(this.href);

  String href;
}

class DiagnoticRelatedInformation {
  DiagnoticRelatedInformation(this.location, this.message);

  Location location;
  String message;
}

class Diagnostic {
  Diagnostic(this.range, this.severity, this.code, this.codeDescription,
      this.source, this.message, this.tags, this.relatedInformation, this.data);

  Diagnostic.fromJSON(dynamic json)
      : range = Range.fromJson(json['range']),
        message = json['message'] {
    severity = DiagnosticSeverity.values[json['severity']];
    code = json['code'];
    codeDescription = json['codeDescription'] != null
        ? CodeDescription(json['codeDescription']['href'])
        : null;
    source = json['source'];
    tags = json['tags'] != null
        ? List<DiagnoticTag>.from(
            json['tags'].map((tag) => DiagnoticTag.values[tag]))
        : null;
    relatedInformation = json['relatedInformation'] != null
        ? List<DiagnoticRelatedInformation>.from(json['relatedInformation'].map(
            (info) => DiagnoticRelatedInformation(
                Location.fromJson(info['location']), info['message'])))
        : null;
    data = json['data'];
  }

  String toJson() {
    return '''
    {
      "range": ${range.toJson()},
      "severity": ${severity?.value},
      "code": "$code",
      "codeDescription": ${codeDescription?.href},
      "source": "$source",
      "message": "$message",
      "tags": ${tags?.map((tag) => tag.value).toList()},
      "relatedInformation": [
        ${relatedInformation?.map((info) => '''
          {
            "location": ${info.location.toJson()},
            "message": "${info.message}"
          }
        ''').join(',')}
      ],
      "data": $data
    }
    ''';
  }

  Range range;
  DiagnosticSeverity? severity;
  String? code;
  CodeDescription? codeDescription;
  String? source;
  String message;
  List<DiagnoticTag>? tags;
  List<DiagnoticRelatedInformation>? relatedInformation;
  dynamic data;
}

class PublishDiagnostics {
  PublishDiagnostics(this.uri, this.version, this.diagnostics);
  PublishDiagnostics.fromJson(dynamic json)
      : uri = json['uri'],
        version = json['version'],
        diagnostics = List<Diagnostic>.from(
            json['diagnostics'].map((diag) => Diagnostic.fromJSON(diag)));

  String toJson() {
    return '''
    {
      "uri": "$uri",
      "version": $version,
      "diagnostics": [
        ${diagnostics.map((diag) => diag.toJson()).join(',')}
      ]
    }
    ''';
  }

  DocumentUri uri;
  int? version;
  List<Diagnostic> diagnostics;
}
