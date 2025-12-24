import 'dart:math' show Random;

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${this.substring(1)}';

  bool isNumeric() {
    try {
      double.parse(this);
      return true;
    } on FormatException {
      return false;
    }
  }

  bool hasUpperCaseLetter() => this.contains(RegExp(r'[A-Z]'));
  bool hasLowerCaseLetter() => this.contains(RegExp(r'[a-z]'));
  bool hasNumber() => this.contains(RegExp(r'[0-9]'));
  bool hasSpecialCharacters() {
    for (final char in _specialCharacters.split('')) {
      if (this.contains(char)) return true;
    }

    return false;
  }
}

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890[]{}!@#\$%^&*()';
const _specialCharacters = '!@#\$%^&*()_-+=[]{}|\\;:\'".,<>/?';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(
  Iterable.generate(
    length,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
  ),
);
