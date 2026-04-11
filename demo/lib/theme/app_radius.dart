import 'package:flutter/widgets.dart';

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 500;

  static const BorderRadius card = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius field = BorderRadius.all(Radius.circular(md));
}
