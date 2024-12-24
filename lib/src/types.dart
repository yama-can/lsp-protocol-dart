class Position {
  Position(this.line, this.character);
  Position.fromJson(dynamic json)
      : line = json['line'],
        character = json['character'];

  String toJson() {
    return '''
    {
      "line": $line,
      "character": $character
    }
    ''';
  }

  int line, character;
}

class Range {
  Range(this.start, this.end);
  Range.fromJson(dynamic json)
      : start = Position(json['start']['line'], json['start']['character']),
        end = Position(json['end']['line'], json['end']['character']);

  String toJson() {
    return '''
    {
      "start": ${start.toJson()},
      "end": ${end.toJson()}
    }
    ''';
  }

  Position start, end;
}

typedef DocumentUri = String;

class Location {
  Location(this.uri, this.range);
  Location.fromJson(dynamic json)
      : uri = json['uri'],
        range = Range.fromJson(json['range']);

  String toJson() {
    return '''
    {
      "uri": "$uri",
      "range": ${range.toJson()}
    }
    ''';
  }

  DocumentUri uri;
  Range range;
}
