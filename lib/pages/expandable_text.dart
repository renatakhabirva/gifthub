// Виджет для сворачиваемого текста
import 'package:flutter/cupertino.dart';

import '../themes/colors.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;
  final TextStyle style;

  const ExpandableText({
    Key? key,
    required this.text,
    this.maxLines = 3,
    required this.style,
  }) : super(key: key);

  @override
  _ExpandableTextState createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: widget.style,
          maxLines: _isExpanded ? null : widget.maxLines,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (widget.text.length >
            100) // Показываем кнопку только для длинного текста
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Text(
              _isExpanded ? 'Свернуть' : 'Развернуть',
              style: TextStyle(
                color: buttonGreenOpacity,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }
}
