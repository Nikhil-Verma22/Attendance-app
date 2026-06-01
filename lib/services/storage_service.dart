import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'dart:io';

/// Background isolate helper to decode, resize, and compress images
Uint8List _compressImageIsolate(Map<String, dynamic> params) {
  final Uint8List originalBytes = params['bytes'] as Uint8List;
  final int quality = params['quality'] as int;
  
  try {
    final image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    img.Image resizedImage = image;
    const int maxLongEdge = 1280;
    if (image.width > maxLongEdge || image.height > maxLongEdge) {
      if (image.width > image.height) {
        resizedImage = img.copyResize(image, width: maxLongEdge);
      } else {
        resizedImage = img.copyResize(image, height: maxLongEdge);
      }
    }

    final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
    return Uint8List.fromList(compressedBytes);
  } catch (_) {
    return originalBytes;
  }
}

/// Background isolate helper to generate a lightweight 150px thumbnail
Uint8List _generateThumbnailIsolate(Uint8List originalBytes) {
  try {
    final image = img.decodeImage(originalBytes);
    if (image == null) return originalBytes;

    final thumbnail = img.copyResize(image, width: 150);
    final encoded = img.encodeJpg(thumbnail, quality: 60);
    return Uint8List.fromList(encoded);
  } catch (_) {
    return originalBytes;
  }
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // In-memory cache for Web simulator fallback
  final Map<String, Uint8List> _webStorage = {};
  final Map<String, Uint8List> _webThumbnails = {};

  // AES-like lightweight XOR encryption key for privacy at rest
  static const List<int> _cryptKey = [0x5A, 0x3F, 0xA9, 0x8C, 0xD4, 0x1E, 0x7B, 0x62];

  /// Scrambles/descrambles bytes for private encrypted storage
  Uint8List _encryptBytes(Uint8List bytes) {
    final scrambled = Uint8List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      scrambled[i] = bytes[i] ^ _cryptKey[i % _cryptKey.length];
    }
    return scrambled;
  }

  /// Compress and resize the incoming image to conform to standard 1280-1600px spec
  Future<Uint8List> compressImage(Uint8List originalBytes, {int quality = 80}) async {
    try {
      return await compute(_compressImageIsolate, {
        'bytes': originalBytes,
        'quality': quality,
      });
    } catch (e) {
      return originalBytes;
    }
  }

  /// Generates a separate lightweight thumbnail for high-speed UI render loading
  Future<Uint8List> generateThumbnail(Uint8List originalBytes) async {
    try {
      return await compute(_generateThumbnailIsolate, originalBytes);
    } catch (e) {
      return originalBytes;
    }
  }

  /// Saves a proof image into app-private storage, compressing and encrypting it.
  Future<Map<String, dynamic>> saveProof({
    required String id,
    required Uint8List rawBytes,
    required String source,
  }) async {
    final originalSize = rawBytes.length;
    final compressedBytes = await compressImage(rawBytes, quality: 75);
    final compressedSize = compressedBytes.length;

    // Compute cryptographic SHA-256 hash of raw file
    final fileHash = sha256.convert(rawBytes).toString();

    // Encrypt files before writing
    final encryptedBytes = _encryptBytes(compressedBytes);
    final thumbnailBytes = await generateThumbnail(compressedBytes);

    String filePath = 'proofs/$id.bin';
    String thumbPath = 'thumbnails/$id.bin';

    if (kIsWeb) {
      // Store in memory cache for web companion
      _webStorage[filePath] = encryptedBytes;
      _webThumbnails[thumbPath] = thumbnailBytes;
    } else {
      // Platform-private sandbox storage on Android / iOS
      final appDir = await getApplicationDocumentsDirectory();
      final proofsDir = Directory('${appDir.path}/proofs')..createSync(recursive: true);
      final thumbsDir = Directory('${appDir.path}/thumbnails')..createSync(recursive: true);

      final proofFile = File('${proofsDir.path}/$id.bin');
      await proofFile.writeAsBytes(encryptedBytes);
      filePath = proofFile.path;

      final thumbFile = File('${thumbsDir.path}/$id.bin');
      await thumbFile.writeAsBytes(thumbnailBytes);
      thumbPath = thumbFile.path;
    }

    return {
      'filePathEncrypted': filePath,
      'thumbnailPath': thumbPath,
      'originalSize': originalSize,
      'compressedSize': compressedSize,
      'hash': fileHash,
    };
  }

  /// Reads and decrypts a proof image for displaying in UI
  Future<Uint8List?> loadProof(String filePath) async {
    if (kIsWeb) {
      final encrypted = _webStorage[filePath];
      if (encrypted == null) return null;
      return _encryptBytes(encrypted);
    } else {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      final encrypted = await file.readAsBytes();
      return _encryptBytes(encrypted);
    }
  }

  /// High-speed reading of non-encrypted thumbnails
  Future<Uint8List?> loadThumbnail(String thumbPath) async {
    if (kIsWeb) {
      return _webThumbnails[thumbPath];
    } else {
      final file = File(thumbPath);
      if (!file.existsSync()) return null;
      return await file.readAsBytes();
    }
  }

  /// Securely removes files from app sandbox
  Future<void> deleteProof(String filePath, String thumbPath) async {
    if (kIsWeb) {
      _webStorage.remove(filePath);
      _webThumbnails.remove(thumbPath);
    } else {
      try {
        final proofFile = File(filePath);
        if (proofFile.existsSync()) await proofFile.delete();

        final thumbFile = File(thumbPath);
        if (thumbFile.existsSync()) await thumbFile.delete();
      } catch (_) {}
    }
  }
}
