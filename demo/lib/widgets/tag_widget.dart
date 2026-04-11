import 'package:flutter/material.dart';
import 'package:demo/models/tag.dart';

class TagWidget extends StatelessWidget {
  final Tag tag;
  final VoidCallback? onTap;
  final bool isClickable;

  const TagWidget({
    super.key,
    required this.tag,
    this.onTap,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isClickable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(int.parse(tag.color.replaceFirst('#', '0xff'))).withOpacity(0.1),
          border: Border.all(
            color: Color(int.parse(tag.color.replaceFirst('#', '0xff'))),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          tag.name,
          style: TextStyle(
            color: Color(int.parse(tag.color.replaceFirst('#', '0xff'))),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
