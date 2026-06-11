import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/common/config/resource_loader.dart';

void main() {
  setUp(() {
    ResourceLoader.loadForTest(
      colors: {
        'common': {'brandGreen': '#24F04E', 'transparent': 'transparent'},
        'home': {},
      },
      strings: {
        'common': {'app_name': 'Pedometer'},
        'home': {},
      },
    );
  });

  test('parses 6-digit hex into opaque color', () {
    expect(ResourceLoader.color('common', 'brandGreen'),
        const Color(0xFF24F04E));
  });

  test('falls back across modules then to fallback color', () {
    expect(
      ResourceLoader.color('home', 'brandGreen', fallbackModule: 'common'),
      const Color(0xFF24F04E),
    );
    expect(
      ResourceLoader.color('home', 'missing', fallback: Colors.red),
      Colors.red,
    );
  });

  test('reads string with fallback', () {
    expect(ResourceLoader.string('common', 'app_name'), 'Pedometer');
    expect(
      ResourceLoader.string('common', 'missing', fallback: 'x'),
      'x',
    );
  });
}
