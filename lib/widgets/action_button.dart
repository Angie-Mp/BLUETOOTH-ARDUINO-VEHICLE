import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.color,
    required this.text,
    this.onTap,
    this.icon,
  });

  final Color color;
  final String text;
  final VoidCallback? onTap;
  final icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 150.0,
          child: Center(
            child:Icon(icon,
              size: 65,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

