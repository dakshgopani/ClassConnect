import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CcLoadingAnimation extends StatelessWidget {
  const CcLoadingAnimation({
    super.key,
    this.size = 200,
    this.color,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    this.strokeWidth,
    this.value,
    this.valueColor,
    this.semanticsLabel,
    this.semanticsValue,
  });

  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double? strokeWidth;
  final double? value;
  final Animation<Color?>? valueColor;
  final String? semanticsLabel;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final tintColor =
        color ?? valueColor?.value ?? Theme.of(context).colorScheme.primary;
    final loader = Lottie.asset(
      'assets/animation/flip_book_loader.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );

    final animatedLoader = ColorFiltered(
      colorFilter: ColorFilter.mode(tintColor, BlendMode.srcIn),
      child: loader,
    );

    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: Padding(
        padding: padding,
        child: Semantics(
          label: semanticsLabel,
          value: semanticsValue,
          child: Center(child: animatedLoader),
        ),
      ),
    );
  }
}
