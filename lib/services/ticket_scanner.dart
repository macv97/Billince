import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of a ticket scan with locally extracted data.
class TicketScanResult {
  final String storeName;
  final double totalAmount;
  final List<TicketLineItem> items;
  final bool isConfident; // true if TOTAL keyword was found

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

/// 100% local ticket scanner using Google ML Kit OCR + post-processing algorithm.
/// No cloud API calls, no tokens, no cost.
class TicketScanner {
  static final _priceRegex = RegExp(r'(\d+[\.,]\d{2})');
  static final _totalKeywords = [
    'total', 'importe', 'suma', 'a pagar', 'total eur',
    'total €', 'import', 'amount', 'subtotal', 'neto',
  ];

  /// Scans a ticket image and extracts store name, total amount, and line items.
  static Future<TicketScanResult> scanTicket(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final lines = _groupIntoHorizontalLines(recognizedText);

      debugPrint('[TicketScanner] Detected ${lines.length} horizontal lines');

      // Step 1: Extract store name (first 1-2 non-empty, non-price lines)
      final storeName = _extractStoreName(lines);

      // Step 2: Find TOTAL anchor line
      int totalLineIndex = -1;
      double totalAmount = 0.0;
      bool isConfident = false;

      for (int i = lines.length - 1; i >= 0; i--) {
        final lineText = lines[i].text.toLowerCase();
        for (final keyword in _totalKeywords) {
          if (lineText.contains(keyword)) {
            // Look for price in the same line first
            final priceMatch = _priceRegex.firstMatch(lines[i].text);
            if (priceMatch != null) {
              totalAmount = _parsePrice(priceMatch.group(1)!);
              totalLineIndex = i;
              isConfident = true;
              break;
            }
            // Try the next line if price not on the same line
            if (i + 1 < lines.length) {
              final nextMatch = _priceRegex.firstMatch(lines[i + 1].text);
              if (nextMatch != null) {
                totalAmount = _parsePrice(nextMatch.group(1)!);
                totalLineIndex = i + 1;
                isConfident = true;
                break;
              }
            }
          }
        }
        if (isConfident) break;
      }

      // Step 3: If no TOTAL keyword found, take the largest price as a fallback
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
        totalLineIndex = lines.length; // all lines are "before total"
      }

      // Step 4: Extract product items (lines above TOTAL with a price pattern)
      final items = <TicketLineItem>[];
      final endIndex = totalLineIndex >= 0 ? totalLineIndex : lines.length;
      for (int i = 2; i < endIndex; i++) { // skip first 2 lines (store name area)
        final line = lines[i];
        final match = _priceRegex.firstMatch(line.text);
        if (match != null) {
          final price = _parsePrice(match.group(1)!);
          // Extract the product name: text before the price
          String productName = line.text
              .substring(0, match.start)
              .replaceAll(RegExp(r'[\d.,]+\s*[xX]\s*'), '') // remove qty patterns
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (productName.length >= 2 && price < totalAmount) {
            items.add(TicketLineItem(name: productName, price: price));
          }
        }
      }

      debugPrint('[TicketScanner] Store: $storeName | Total: $totalAmount | Items: ${items.length} | Confident: $isConfident');

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

  /// Scans a shopping list image and extracts product names only (no prices).
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

  // ── Private Helpers ─────────────────────────────────────────

  /// Groups text elements by similar Y coordinate to reconstruct horizontal lines.
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

    // Sort by Y first, then X
    elements.sort((a, b) {
      final yDiff = a.y.compareTo(b.y);
      return yDiff != 0 ? yDiff : a.x.compareTo(b.x);
    });

    // Group by similar Y (tolerance = average element height * 0.6)
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
    // Last group
    if (currentGroup.isNotEmpty) {
      currentGroup.sort((a, b) => a.x.compareTo(b.x));
      lines.add(_ScanLine(
        text: currentGroup.map((e) => e.text).join(' '),
        y: currentY,
      ));
    }

    return lines;
  }

  /// Extracts store name from first valid text lines.
  static String _extractStoreName(List<_ScanLine> lines) {
    final candidates = <String>[];
    for (int i = 0; i < min(3, lines.length); i++) {
      final clean = lines[i].text
          .replaceAll(RegExp(r'[0-9]{5,}'), '') // remove long numbers (CIF, phone)
          .replaceAll(RegExp(r'[\d.,]+\s*(€|\$|£)'), '') // remove prices
          .trim();
      if (clean.length >= 3 && !_priceRegex.hasMatch(clean)) {
        candidates.add(clean);
      }
    }
    return candidates.isNotEmpty ? candidates.first : 'Comercio';
  }

  /// Parses a price string like "12,50" or "12.50" to double.
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
