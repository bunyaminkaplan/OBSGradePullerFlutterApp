/// TFLite Captcha Solver - Data Layer
/// Bu dosya CaptchaSolver interface'ini implement eder
library;

import 'dart:collection';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import '../../domain/services/captcha_solver.dart';
import '../../../../core/constants.dart';
import '../../../../core/utils/logger.dart';

/// TensorFlow Lite tabanlı captcha çözücü
/// OBS captcha görsellerini AI ile çözer
class TFLiteCaptchaSolver implements CaptchaSolver {
  Interpreter? _interpreter;
  Interpreter? _interpreterOld;
  final Logger _logger;

  TFLiteCaptchaSolver([Logger? logger])
    : _logger = logger ?? const Logger(tag: 'Captcha');

  @override
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(CaptchaConstants.modelPath);
      _interpreterOld = await Interpreter.fromAsset(
        CaptchaConstants.modelOldPath,
      );
      _logger.info('TFLite modelleri yüklendi');
    } catch (e) {
      _logger.error('Model yükleme hatası: $e', error: e);
    }
  }

  @override
  Future<String?> solve(Uint8List imageBytes) async {
    if (_interpreter == null || _interpreterOld == null) {
      await loadModel();
    }
    if (_interpreter == null || _interpreterOld == null) return null;

    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    // Şeffaflığı düzleştir
    final flattened = img.Image(
      width: originalImage.width,
      height: originalImage.height,
    );
    img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(flattened, originalImage);

    // %70 genişlik kırp
    final newWidth = (flattened.width * 0.70).toInt();
    final fullImage = img.copyCrop(
      flattened,
      x: 0,
      y: 0,
      width: newWidth,
      height: flattened.height,
    );

    // Orta şeridi maskele
    final maskStart = (newWidth * 0.50).toInt();
    final maskEnd = (newWidth * 0.60).toInt();
    img.fillRect(
      fullImage,
      x1: maskStart,
      y1: 0,
      x2: maskEnd,
      y2: fullImage.height,
      color: img.ColorRgb8(255, 255, 255),
    );

    // Grayscale
    final grayImage = img.grayscale(fullImage);

    // Blob tespiti
    final boxes = _findCharacterRegions(grayImage);

    // Tam 3 rakam bulunamadıysa eski modele geç
    if (boxes.length != 3) {
      _logger.warning(
        'Dinamik segmentasyon ${boxes.length} rakam buldu. Eski modele geçiliyor.',
      );
      return _solveFallback(fullImage);
    }

    // Yeni model ile çöz
    final digits = <int>[];
    final List<img.Image?> finalImages = List.filled(3, null);

    for (final box in boxes) {
      final x = box[0];
      final w = box[2];
      final centerX = x + w ~/ 2;

      int slot = -1;
      if (centerX < 35) {
        slot = 0;
      } else if (centerX < 70) {
        slot = 1;
      } else {
        slot = 2;
      }

      if (finalImages[slot] == null) {
        const pad = 3;
        final xStart = (x - pad < 0) ? 0 : x - pad;
        final xEnd = (x + w + pad > fullImage.width)
            ? fullImage.width
            : x + w + pad;
        final finalW = xEnd - xStart;

        finalImages[slot] = img.copyCrop(
          fullImage,
          x: xStart,
          y: 0,
          width: finalW,
          height: fullImage.height,
        );
      }
    }

    // Null kontrolü
    if (finalImages.any((e) => e == null)) {
      _logger.warning('Slot eşleme belirsizliği. Eski modele geçiliyor.');
      return _solveFallback(fullImage);
    }

    for (int i = 0; i < 3; i++) {
      final charImg = finalImages[i]!;
      final input = _preprocessForModel(charImg);
      final output = List.filled(1, List.filled(10, 0.0));
      _interpreter!.run(input, output);

      var maxVal = -1.0;
      var maxIdx = -1;
      for (int k = 0; k < 10; k++) {
        if (output[0][k] > maxVal) {
          maxVal = output[0][k];
          maxIdx = k;
        }
      }
      digits.add(maxIdx);
    }

    return _calculateResult(digits);
  }

  /// Eski model ile fallback çözüm
  Future<String?> _solveFallback(img.Image fullImage) async {
    if (_interpreterOld == null) return null;

    final digits = <int>[];

    for (int i = 0; i < 3; i++) {
      final slice = CaptchaConstants.digitSlices[i];
      var startX = slice[0];
      var endX = slice[1];

      if (startX < 0) startX = 0;
      if (endX > fullImage.width) endX = fullImage.width;
      if (startX >= endX) {
        digits.add(0);
        continue;
      }

      final cropped = img.copyCrop(
        fullImage,
        x: startX,
        y: 0,
        width: endX - startX,
        height: fullImage.height,
      );

      final input = _preprocessForModel(cropped);
      final output = List.filled(1, List.filled(10, 0.0));
      _interpreterOld!.run(input, output);

      var maxVal = -1.0;
      var maxIdx = -1;
      for (int k = 0; k < 10; k++) {
        if (output[0][k] > maxVal) {
          maxVal = output[0][k];
          maxIdx = k;
        }
      }
      digits.add(maxIdx);
    }

    return _calculateResult(digits);
  }

  /// Sonucu hesapla (XX + Y formatı)
  String? _calculateResult(List<int> digits) {
    if (digits.length == 3) {
      final num1 = (digits[0] * 10) + digits[1];
      final num2 = digits[2];
      return (num1 + num2).toString();
    } else if (digits.length == 2) {
      return (digits[0] + digits[1]).toString();
    }
    return null;
  }

  /// Model için görüntü ön işleme
  List<List<List<List<double>>>> _preprocessForModel(img.Image charImg) {
    final w = charImg.width;
    final h = charImg.height;

    // Kareye tamamla
    final maxSize = (w > h) ? w : h;
    final padded = img.Image(width: maxSize, height: maxSize);
    img.fill(padded, color: img.ColorRgb8(0, 0, 0));

    final dstX = (maxSize - w) ~/ 2;
    final dstY = (maxSize - h) ~/ 2;
    img.compositeImage(padded, charImg, dstX: dstX, dstY: dstY);

    // 32x32'ye boyutlandır
    final resized = img.copyResize(padded, width: 32, height: 32);
    final grayResized = img.grayscale(resized);

    // Tensor'a çevir [1, 32, 32, 1]
    final input = List.generate(
      1,
      (i) => List.generate(
        32,
        (j) => List.generate(32, (k) => List.filled(1, 0.0)),
      ),
    );

    for (int y = 0; y < 32; y++) {
      for (int x = 0; x < 32; x++) {
        final pixel = grayResized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
      }
    }

    return input;
  }

  /// Karakter bölgelerini bul (Connected Component)
  List<List<int>> _findCharacterRegions(img.Image grayImg) {
    final w = grayImg.width;
    final h = grayImg.height;
    final seen = List.generate(h, (_) => List.filled(w, false));
    final boxes = <List<int>>[];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (seen[y][x]) continue;

        final p = grayImg.getPixel(x, y);
        if (p.r < 150) {
          final box = _bfsBlob(grayImg, seen, x, y);
          final bx = box[0];
          final bw = box[2];
          final bh = box[3];

          // Gürültü filtresi
          if (bw < 8 || bh < 15) continue;

          // Artı işareti filtresi
          final centerX = w ~/ 2;
          final isCenter = (bx + bw / 2 - centerX).abs() < 25;
          final aspect = bw / bh;
          if (isCenter && bh < 22 && bw < 25 && aspect > 0.7 && aspect < 1.4) {
            continue;
          }

          // Geniş blob bölme
          if (bw > 28) {
            if (bw > 45) {
              final div = bw ~/ 3;
              boxes.add([bx, box[1], div, bh]);
              boxes.add([bx + div, box[1], div, bh]);
              boxes.add([bx + 2 * div, box[1], div, bh]);
            } else {
              final div = bw ~/ 2;
              boxes.add([bx, box[1], div, bh]);
              boxes.add([bx + div, box[1], div, bh]);
            }
          } else {
            boxes.add(box);
          }
        } else {
          seen[y][x] = true;
        }
      }
    }

    // Soldan sağa sırala
    boxes.sort((a, b) => a[0].compareTo(b[0]));

    // Maksimum 3 ile sınırla
    if (boxes.length > 3) {
      return boxes.sublist(0, 3);
    }

    return boxes;
  }

  /// BFS ile bağlı bileşen tespiti
  List<int> _bfsBlob(
    img.Image imgData,
    List<List<bool>> seen,
    int startX,
    int startY,
  ) {
    var minX = startX;
    var maxX = startX;
    var minY = startY;
    var maxY = startY;

    final q = Queue<List<int>>();
    q.add([startX, startY]);
    seen[startY][startX] = true;

    final w = imgData.width;
    final h = imgData.height;
    const dx = [0, 0, -1, 1];
    const dy = [-1, 1, 0, 0];

    while (q.isNotEmpty) {
      final curr = q.removeFirst();
      final cx = curr[0];
      final cy = curr[1];

      if (cx < minX) minX = cx;
      if (cx > maxX) maxX = cx;
      if (cy < minY) minY = cy;
      if (cy > maxY) maxY = cy;

      for (int i = 0; i < 4; i++) {
        final nx = cx + dx[i];
        final ny = cy + dy[i];

        if (nx >= 0 && nx < w && ny >= 0 && ny < h && !seen[ny][nx]) {
          final p = imgData.getPixel(nx, ny);
          if (p.r < 150) {
            seen[ny][nx] = true;
            q.add([nx, ny]);
          }
        }
      }
    }

    return [minX, minY, maxX - minX + 1, maxY - minY + 1];
  }
}
