import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../core/constants.dart';
import '../domain/services/captcha_service_interface.dart';

class CaptchaService implements ICaptchaService {
  Interpreter? _interpreter;
  Interpreter? _interpreterOld;

  @override
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/digit_model.tflite');
      _interpreterOld = await Interpreter.fromAsset(
        'assets/digit_model_old.tflite',
      );
      print("TFLite models loaded successfully (New & Old).");
    } catch (e) {
      print("Error loading models: $e");
    }
  }

  /// Main function to solve captcha
  @override
  Future<String?> solveCaptcha(Uint8List imageBytes) async {
    if (_interpreter == null || _interpreterOld == null) await loadModel();
    if (_interpreter == null || _interpreterOld == null) return null;

    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    // 0. FLATTEN TRANSPARENCY
    img.Image flattened = img.Image(
      width: originalImage.width,
      height: originalImage.height,
    );
    img.fill(flattened, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(flattened, originalImage);

    // 0.1 CROP 70% WIDTH (for New System)
    int newWidth = (flattened.width * 0.70).toInt();
    img.Image fullImage = img.copyCrop(
      flattened,
      x: 0,
      y: 0,
      width: newWidth,
      height: flattened.height,
    );

    // 0.2 MASK MIDDLE STRIP (50-60% of cropped width)
    int maskStart = (newWidth * 0.50).toInt();
    int maskEnd = (newWidth * 0.60).toInt();
    img.fillRect(
      fullImage,
      x1: maskStart,
      y1: 0,
      x2: maskEnd,
      y2: fullImage.height,
      color: img.ColorRgb8(255, 255, 255),
    );

    // 1. Grayscale for Segmentation
    final img.Image grayImage = img.grayscale(fullImage);

    // 2. Find Blobs (Dynamic Segmentation)
    List<List<int>> boxes = _findCharacterRegions(grayImage);

    // --- FALLBACK CHECK ---
    // If not exactly 3 digits found, fallback to OLD SYSTEM
    if (boxes.length != 3) {
      print(
        "⚠️ Dynamic segmentation found ${boxes.length} digits. Switching to OLD MODEL Fallback.",
      );
      return await _solveFallback(fullImage);
    }

    // --- NEW SYSTEM EXECUTION ---
    List<img.Image?> finalImages = List.filled(3, null);

    // Map found dynamic boxes to slots
    for (var box in boxes) {
      int x = box[0];
      int w = box[2];
      int h = box[3];
      int centerX = x + w ~/ 2;

      int slot = -1;
      if (centerX < 35) {
        slot = 0;
      } else if (centerX < 70) {
        slot = 1;
      } else {
        slot = 2;
      }

      if (finalImages[slot] == null) {
        // Prepare crop from PROCESSED COLOR IMAGE (70% cropped + masked)
        int pad = 3;
        int xStart = (x - pad < 0) ? 0 : x - pad;
        int xEnd = (x + w + pad > fullImage.width)
            ? fullImage.width
            : x + w + pad;
        int finalW = xEnd - xStart;

        finalImages[slot] = img.copyCrop(
          fullImage,
          x: xStart,
          y: 0,
          width: finalW,
          height: fullImage.height,
        );
      }
    }

    // Fill missing slots (Hybrid logic within New System - rarely needed if boxes==3 check passes)
    // But if mapping failed (e.g. 2 boxes in same slot), we might still have nulls.
    // If we have nulls even after boxes==3, it implies overlap or bad localization.
    bool hasNull = finalImages.any((element) => element == null);
    if (hasNull) {
      print("⚠️ Slot mapping ambiguity. Switching to OLD MODEL Fallback.");
      return await _solveFallback(fullImage);
    }

    List<int> digits = [];

    // 3. Process the 3 images (NEW MODEL)
    for (int i = 0; i < 3; i++) {
      img.Image? charImg = finalImages[i];
      if (charImg == null) continue;

      var input = _preprocessForModel(charImg);
      var output = List.filled(1, List.filled(10, 0.0));
      _interpreter!.run(input, output);

      double maxVal = -1.0;
      int maxIdx = -1;
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

  // Fallback: Static Slices + Old Model
  Future<String?> _solveFallback(img.Image fullImage) async {
    if (_interpreterOld == null) return null;

    List<int> digits = [];

    for (int i = 0; i < 3; i++) {
      List<int> slice = AppConstants.digitSlices[i];
      int startX = slice[0];
      int endX = slice[1];

      // Safety
      if (startX < 0) startX = 0;
      if (endX > fullImage.width) endX = fullImage.width;
      if (startX >= endX) {
        digits.add(0); // Add a placeholder if slice is invalid
        continue;
      }

      img.Image cropped = img.copyCrop(
        fullImage,
        x: startX,
        y: 0,
        width: endX - startX,
        height: fullImage.height,
      );

      var input = _preprocessForModel(cropped);
      var output = List.filled(1, List.filled(10, 0.0));
      _interpreterOld!.run(input, output);

      double maxVal = -1.0;
      int maxIdx = -1;
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

  String? _calculateResult(List<int> digits) {
    if (digits.length == 3) {
      int num1 = (digits[0] * 10) + digits[1];
      int num2 = digits[2];
      return (num1 + num2).toString();
    } else if (digits.length == 2) {
      return (digits[0] + digits[1]).toString();
    }
    return null;
  }

  /// Preprocesses a single character image for the model
  List<List<List<List<double>>>> _preprocessForModel(img.Image charImg) {
    int w = charImg.width;
    int h = charImg.height;

    // Pad to Square
    int maxSize = (w > h) ? w : h;
    img.Image padded = img.Image(width: maxSize, height: maxSize);
    // Fill with BLACK (0)
    img.fill(padded, color: img.ColorRgb8(0, 0, 0));

    // Center extract
    int dstX = (maxSize - w) ~/ 2;
    int dstY = (maxSize - h) ~/ 2;
    img.compositeImage(padded, charImg, dstX: dstX, dstY: dstY);

    // Resize to 32x32
    img.Image resized = img.copyResize(padded, width: 32, height: 32);

    // Ensure Grayscale (Model expects 1 channel logic, though we feed 3 identical if RGB,
    // but better to convert to single channel brightness for consistency with training)
    // Image package grayscale returns an image where r=g=b=luminance.
    img.Image grayResized = img.grayscale(resized);

    // Create Input Tensor [1, 32, 32, 1]
    var input = List.generate(
      1,
      (i) => List.generate(
        32,
        (j) => List.generate(32, (k) => List.filled(1, 0.0)),
      ),
    );

    for (int y = 0; y < 32; y++) {
      for (int x = 0; x < 32; x++) {
        img.Pixel pixel = grayResized.getPixel(x, y);
        // Normalize 0.0 - 1.0
        // Image pixel: 0=Black, 255=White.
        input[0][y][x][0] = pixel.r / 255.0;
      }
    }
    return input;
  }

  /// Finds bounding boxes of characters using Connected Component Labeling (BFS)
  List<List<int>> _findCharacterRegions(img.Image grayImg) {
    int w = grayImg.width;
    int h = grayImg.height;

    // Visited matrix
    var seen = List.generate(h, (_) => List.filled(w, false));

    List<List<int>> boxes = []; // [x, y, w, h]

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (seen[y][x]) continue;

        img.Pixel p = grayImg.getPixel(x, y);
        // THRESHOLD: Check if pixel is DARK.
        // Assuming OBS Text is Black (<150) and BG is White (>150)
        if (p.r < 150) {
          List<int> box = _bfsBlob(grayImg, seen, x, y);

          int bx = box[0];
          int by = box[1];
          int bw = box[2];
          int bh = box[3];

          // --- FILTERS (Same as Python) ---

          // 1. Noise Filter
          if (bw < 8 || bh < 15) continue; // Too small

          // 2. Plus Sign Filter
          int centerX = w ~/ 2;
          bool isCenter = (bx + bw / 2 - centerX).abs() < 25;
          // Check square-ish aspect ratio for plus sign
          double aspect = bw / bh;
          if (isCenter && bh < 22 && bw < 25 && aspect > 0.7 && aspect < 1.4)
            continue;

          // 3. Wide Blob Splitting
          if (bw > 28) {
            if (bw > 45) {
              // 3 digits
              int div = bw ~/ 3;
              boxes.add([bx, by, div, bh]);
              boxes.add([bx + div, by, div, bh]);
              boxes.add([bx + 2 * div, by, div, bh]);
            } else {
              // 2 digits
              int div = bw ~/ 2;
              boxes.add([bx, by, div, bh]);
              boxes.add([bx + div, by, div, bh]);
            }
          } else {
            boxes.add(box);
          }
        } else {
          seen[y][x] = true; // Mark white pixels as seen
        }
      }
    }

    // Sort left-to-right
    boxes.sort((a, b) => a[0].compareTo(b[0]));

    // Limit to max 3 items
    if (boxes.length > 3) {
      boxes = boxes.sublist(0, 3);
    }

    return boxes;
  }

  /// Breadth-First Search to find connected component
  List<int> _bfsBlob(
    img.Image imgData,
    List<List<bool>> seen,
    int startX,
    int startY,
  ) {
    int minX = startX;
    int maxX = startX;
    int minY = startY;
    int maxY = startY;

    Queue<List<int>> q = Queue();
    q.add([startX, startY]);
    seen[startY][startX] = true;

    int w = imgData.width;
    int h = imgData.height;

    // 4-Connectivity
    var dx = [0, 0, -1, 1];
    var dy = [-1, 1, 0, 0];

    while (q.isNotEmpty) {
      var curr = q.removeFirst();
      int cx = curr[0];
      int cy = curr[1];

      if (cx < minX) minX = cx;
      if (cx > maxX) maxX = cx;
      if (cy < minY) minY = cy;
      if (cy > maxY) maxY = cy;

      for (int i = 0; i < 4; i++) {
        int nx = cx + dx[i];
        int ny = cy + dy[i];

        if (nx >= 0 && nx < w && ny >= 0 && ny < h) {
          if (!seen[ny][nx]) {
            // Check if part of the same blob (Dark < 150)
            img.Pixel p = imgData.getPixel(nx, ny);
            if (p.r < 150) {
              seen[ny][nx] = true;
              q.add([nx, ny]);
            }
          }
        }
      }
    }

    return [minX, minY, maxX - minX + 1, maxY - minY + 1]; // x, y, w, h
  }
}
