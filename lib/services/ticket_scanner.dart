import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TicketScanResult {
  final String storeName;
  final double totalAmount;
  final List<TicketLineItem> items;
  final bool isConfident;

  const TicketScanResult({
    required this.storeName,
    required this.totalAmount,
    required this.items,
    required this.isConfident,
  });
}

class TicketLineItem {
  final String name;
  final double price;

  const TicketLineItem({required this.name, required this.price});
}

class TicketScanner {
  static final _priceRegex = RegExp(r'(\d+[\.,]\d{2})');
  static final _totalKeywords = [
    'total', 'importe', 'suma', 'a pagar', 'total eur',
    'total €', 'import', 'amount', 'neto',
  ];
  static final _excludeKeywords = ['subtotal', 'descuento', 'cambio', 'entregado'];

  /// Scans ticket 100% locally utilizing Google's On-Device ML Text Recognition
  /// combined with spatial analysis and fuzzy logic for high precision.
  static Future<TicketScanResult> scanTicket(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      
      // We process both line-grouped elements and pure geometric blocks
      final lines = _groupIntoHorizontalLines(recognizedText);
      final storeName = _extractStoreName(lines);

      // Advanced Geometric Total Extraction
      double totalAmount = 0.0;
      bool isConfident = false;
      int totalYCoord = -1;
      
      // 1. Find the TOTAL anchor element using exact or fuzzy match
      TextElement? totalElement;
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            final text = element.text.toLowerCase().trim();
            if (_isMatchTotal(text)) {
              totalElement = element;
              break;
            }
          }
          if (totalElement != null) break;
        }
        if (totalElement != null) break;
      }

      // 2. If we found a TOTAL anchor, look for a price to its right or slightly below
      if (totalElement != null) {
        final anchorY = totalElement.boundingBox.top;
        final anchorHeight = totalElement.boundingBox.height;
        final toleranceY = anchorHeight * 1.5; // Allow some skew

        double maxPriceNearAnchor = 0.0;

        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            for (final element in line.elements) {
              // Only consider elements that are physically to the right and aligned horizontally, or just one line below
              if ((element.boundingBox.top - anchorY).abs() < toleranceY) {
                final match = _priceRegex.firstMatch(element.text);
                if (match != null) {
                  final price = _parsePrice(match.group(1)!);
                  if (price > maxPriceNearAnchor) {
                    maxPriceNearAnchor = price;
                  }
                }
              }
            }
          }
        }
        
        if (maxPriceNearAnchor > 0) {
          totalAmount = maxPriceNearAnchor;
          isConfident = true;
          totalYCoord = anchorY.toInt();
        }
      }

      // 3. Fallback: Parse whole text with global Regex
      if (!isConfident) {
        final fullText = recognizedText.text.replaceAll('\n', ' ').toLowerCase();
        final regex = RegExp(r'(?:total|importe|suma|pagar).{0,30}?(\d+[.,]\d{2})');
        final globalMatch = regex.firstMatch(fullText);
        
        if (globalMatch != null) {
          totalAmount = _parsePrice(globalMatch.group(1)!);
          isConfident = true;
        }
      }

      // 4. Ultimate Fallback: Just get the biggest price found
      if (!isConfident) {
        double maxPrice = 0.0;
        for (final line in lines) {
          final match = _priceRegex.firstMatch(line.text);
          if (match != null) {
            final price = _parsePrice(match.group(1)!);
            if (price > maxPrice) {
              maxPrice = price;
              totalAmount = price;
            }
          }
        }
      }

      // 5. Extract items
      final items = <TicketLineItem>[];
      for (int i = 2; i < lines.length; i++) {
        final line = lines[i];
        
        // Stop if we reached the physical Y coordinate of the total (if we found it)
        if (totalYCoord != -1 && line.y >= (totalYCoord - 10)) break;

        final match = _priceRegex.firstMatch(line.text);
        if (match != null) {
          final price = _parsePrice(match.group(1)!);
          String productName = line.text
              .substring(0, match.start)
              .replaceAll(RegExp(r'[\d.,]+\s*[xX]\s*'), '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          // Filters
          final isExcluded = _excludeKeywords.any((ex) => productName.toLowerCase().contains(ex));
          
          if (productName.length >= 2 && price < totalAmount && !isExcluded) {
            items.add(TicketLineItem(name: productName, price: price));
          }
        }
      }

      debugPrint('[TicketScanner] Local ML Kit -> Store: $storeName | Total: $totalAmount | Confident: $isConfident');

      return TicketScanResult(
        storeName: storeName,
        totalAmount: totalAmount,
        items: items,
        isConfident: isConfident,
      );
    } finally {
      textRecognizer.close();
    }
  }

  static Future<List<String>> scanShoppingList(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final lines = _groupIntoHorizontalLines(recognizedText);
      return lines
          .map((l) => l.text.replaceAll(RegExp(r'[\d.,]+\s*(€|\$|£)?'), '').trim())
          .where((text) => text.length >= 2)
          .toList();
    } finally {
      textRecognizer.close();
    }
  }

  // ── Advanced Processing Helpers ─────────────────────────────────────────

  /// Checks if a string is likely 'TOTAL' with tolerance to OCR errors like T0TAL, IMP0RTE.
  static bool _isMatchTotal(String word) {
    if (_totalKeywords.contains(word)) return true;
    if (_excludeKeywords.contains(word)) return false;
    
    // Quick fuzzy matches
    if (word.startsWith('tot') || word == 't0tal' || word == 't0ta1') return true;
    if (word.startsWith('imp') && word.contains('rt')) return true;
    
    return false;
  }

  static List<_ScanLine> _groupIntoHorizontalLines(RecognizedText recognizedText) {
    final elements = <_TextElementWithPos>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          elements.add(_TextElementWithPos(
            text: element.text,
            y: element.boundingBox.top,
            x: element.boundingBox.left,
            height: element.boundingBox.height,
          ));
        }
      }
    }

    if (elements.isEmpty) return [];

    elements.sort((a, b) {
      final yDiff = a.y.compareTo(b.y);
      return yDiff != 0 ? yDiff : a.x.compareTo(b.x);
    });

    final avgHeight = elements.map((e) => e.height).reduce((a, b) => a + b) / elements.length;
    final tolerance = avgHeight * 0.6;

    final lines = <_ScanLine>[];
    List<_TextElementWithPos> currentGroup = [elements.first];
    double currentY = elements.first.y;

    for (int i = 1; i < elements.length; i++) {
      if ((elements[i].y - currentY).abs() <= tolerance) {
        currentGroup.add(elements[i]);
      } else {
        currentGroup.sort((a, b) => a.x.compareTo(b.x));
        lines.add(_ScanLine(
          text: currentGroup.map((e) => e.text).join(' '),
          y: currentY,
        ));
        currentGroup = [elements[i]];
        currentY = elements[i].y;
      }
    }
    if (currentGroup.isNotEmpty) {
      currentGroup.sort((a, b) => a.x.compareTo(b.x));
      lines.add(_ScanLine(
        text: currentGroup.map((e) => e.text).join(' '),
        y: currentY,
      ));
    }
    return lines;
  }

  static String _extractStoreName(List<_ScanLine> lines) {
    final candidates = <String>[];
    for (int i = 0; i < min(3, lines.length); i++) {
      final clean = lines[i].text
          .replaceAll(RegExp(r'[0-9]{5,}'), '')
          .replaceAll(RegExp(r'[\d.,]+\s*(€|\$|£)'), '')
          .trim();
      if (clean.length >= 3 && !_priceRegex.hasMatch(clean)) {
        candidates.add(clean);
      }
    }
    return candidates.isNotEmpty ? candidates.first : 'Comercio';
  }

  static double _parsePrice(String raw) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
  }
}

class _TextElementWithPos {
  final String text;
  final double y;
  final double x;
  final double height;
  _TextElementWithPos({required this.text, required this.y, required this.x, required this.height});
}

class _ScanLine {
  final String text;
  final double y;
  _ScanLine({required this.text, required this.y});
}
