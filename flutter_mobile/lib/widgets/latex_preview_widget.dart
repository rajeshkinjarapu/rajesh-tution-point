import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class LatexPreviewWidget extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final bool isSelectable;

  const LatexPreviewWidget({
    super.key,
    required this.text,
    this.textStyle,
    this.isSelectable = false,
  });

  @override
  Widget build(BuildContext context) {
    // Process text for KaTeX to handle the common formats like $$..$$ or \(..\)
    String processedText = text;
    
    // Ensure line breaks are preserved in the HTML structure
    processedText = processedText.replaceAll('\n', '<br/>');
    
    return TeXView(
      child: TeXViewDocument(
        processedText,
        style: TeXViewStyle(
          contentColor: textStyle?.color ?? Colors.black87,
          fontStyle: TeXViewFontStyle(
            fontSize: textStyle?.fontSize?.toInt() ?? 16,
          ),
          padding: const TeXViewPadding.all(4),
        ),
      ),
      style: const TeXViewStyle(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      loadingWidgetBuilder: (context) => const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
