import 'package:flutter/material.dart';

class AnimatedThemeSwitch extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onToggle;

  const AnimatedThemeSwitch({
    Key? key,
    required this.isDark,
    required this.onToggle,
  }) : super(key: key);

  @override
  _AnimatedThemeSwitchState createState() => _AnimatedThemeSwitchState();
}

class _AnimatedThemeSwitchState extends State<AnimatedThemeSwitch> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }

  @override
  void didUpdateWidget(covariant AnimatedThemeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      _isDark = widget.isDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDark = !_isDark;
        });
        widget.onToggle(_isDark);
      },
      child: Container(
        width: 60,
        height: 30,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: _isDark ? Colors.grey[700] : Colors.yellow[700],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: _isDark ? Alignment.centerRight : Alignment.centerLeft,
          curve: Curves.easeInOut,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              _isDark ? Icons.nights_stay : Icons.wb_sunny,
              size: 16,
              color: _isDark ? Colors.black87 : Colors.orange,
            ),
          ),
        ),
      ),
    );
  }
}
