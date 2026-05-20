import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class SmartHighlightScreen extends StatefulWidget {
  final String imagePath;
  const SmartHighlightScreen({super.key, required this.imagePath});

  @override
  State<SmartHighlightScreen> createState() => _SmartHighlightScreenState();
}

class _SmartHighlightScreenState extends State<SmartHighlightScreen> {
  ui.Image? _image;
  List<Offset> _points = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final data = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  Future<void> _processHighlightAndCrop() async {
    if (_points.isEmpty || _image == null) return;
    setState(() => _isProcessing = true);

    try {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final size = renderBox.size;
      final imageW = _image!.width.toDouble();
      final imageH = _image!.height.toDouble();

      // Math to find the scale and offset of BoxFit.contain
      final scaleX = size.width / imageW;
      final scaleY = size.height / imageH;
      final scale = min(scaleX, scaleY);

      final renderW = imageW * scale;
      final renderH = imageH * scale;

      final offsetX = (size.width - renderW) / 2;
      final offsetY = (size.height - renderH) / 2;

      double minX = double.infinity, minY = double.infinity;
      double maxX = 0, maxY = 0;

      for (var p in _points) {
        // Convert screen coordinate to original image coordinate
        final x = (p.dx - offsetX) / scale;
        final y = (p.dy - offsetY) / scale;
        
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }

      // Add some padding to the crop
      final padding = 30.0;
      minX = max(0, minX - padding);
      minY = max(0, minY - padding);
      maxX = min(imageW, maxX + padding);
      maxY = min(imageH, maxY + padding);

      if (maxX <= minX || maxY <= minY) {
        throw Exception('El subrayado no es válido');
      }

      // Perform actual image crop using 'image' package
      final bytes = await File(widget.imagePath).readAsBytes();
      final originalImg = img.decodeImage(bytes);
      if (originalImg == null) throw Exception('No se pudo decodificar');

      final croppedImg = img.copyCrop(
        originalImg, 
        x: minX.toInt(), 
        y: minY.toInt(), 
        width: (maxX - minX).toInt(), 
        height: (maxY - minY).toInt()
      );

      final directory = await getTemporaryDirectory();
      final tempPath = '${directory.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final croppedFile = File(tempPath)..writeAsBytesSync(img.encodeJpg(croppedImg));

      if (mounted) {
        Navigator.pop(context, croppedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al procesar: $e')));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Subraya el Precio', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_points.isNotEmpty && !_isProcessing)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 32),
              onPressed: _processHighlightAndCrop,
            )
        ],
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GestureDetector(
                  onPanStart: (details) => setState(() => _points.add(details.localPosition)),
                  onPanUpdate: (details) => setState(() => _points.add(details.localPosition)),
                  onPanEnd: (details) => setState(() {}), // Trigger paint
                  child: Center(
                    child: CustomPaint(
                      painter: _HighlightPainter(_image!, _points),
                      size: Size.infinite,
                    ),
                  ),
                ),
                if (_points.isEmpty)
                  Positioned(
                    top: 20,
                    left: 20, right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Desliza el dedo sobre la zona del ticket donde está el PRECIO TOTAL como si usaras un subrayador.',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
      floatingActionButton: _points.isNotEmpty && !_isProcessing
          ? FloatingActionButton(
              onPressed: () => setState(() => _points.clear()),
              backgroundColor: Colors.white,
              child: const Icon(Icons.undo, color: Colors.black),
            )
          : null,
    );
  }
}

class _HighlightPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> points;

  _HighlightPainter(this.image, this.points);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Image centered (BoxFit.contain logic)
    final imageW = image.width.toDouble();
    final imageH = image.height.toDouble();
    final scaleX = size.width / imageW;
    final scaleY = size.height / imageH;
    final scale = min(scaleX, scaleY);

    final renderW = imageW * scale;
    final renderH = imageH * scale;

    final offsetX = (size.width - renderW) / 2;
    final offsetY = (size.height - renderH) / 2;

    final destRect = Rect.fromLTWH(offsetX, offsetY, renderW, renderH);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, imageW, imageH), destRect, Paint());

    // 2. Draw Highlight (Translucent Lynx Eye Amber)
    if (points.isNotEmpty) {
      final paint = Paint()
        ..color = const Color(0x88F59E0B) // Amber semi-transparent
        ..strokeWidth = 30.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) => true;
}
