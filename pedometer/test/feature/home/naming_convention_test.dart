import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion detail code avoids the forbidden english token', () {
    final forbidden = RegExp('${'Act'}${'ivity'}|${'act'}${'ivity'}');
    final files = [
      ...Directory('lib').listSync(recursive: true),
      ...Directory('test').listSync(recursive: true),
    ].whereType<File>().where((file) => file.path.endsWith('.dart'));

    final offenders = <String>[];
    for (final file in files) {
      if (forbidden.hasMatch(file.path)) {
        offenders.add(file.path);
      }

      final text = file.readAsStringSync();
      if (forbidden.hasMatch(text)) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('production routes use GetX instead of Navigator APIs', () {
    final forbidden = RegExp(
      r'Navigator|MaterialPageRoute|CupertinoPageRoute|PageRouteBuilder|'
      r'pushNamed|pushReplacement|maybePop|popUntil',
    );
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    final offenders = <String>[];
    for (final file in files) {
      final text = file.readAsStringSync();
      if (forbidden.hasMatch(text)) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });
}
