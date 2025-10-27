// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/utils/url.dart';

void main() {
  group('isIonMediaUrl', () {
    test('returns true for valid ION media URLs', () {
      const validUrls = [
        'https://media.online.io/ion-connect/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp',
        'https://154.145.21.11/files/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp',
        'https://51.89.69.218:4443/files/80bd35d5b6704e41b73bcdc89a4f80dea3acf8ee6fec2cdfb2ebd8aadabf4af5:ad98f49cb1daa368883e377a8d2d711b7c53df551d5faeaedfa4e616e39b2f54.enc',
      ];

      for (final url in validUrls) {
        expect(isIonMediaUrl(url), isTrue);
      }
    });

    test('returns false for invalid ION media URLs', () {
      const invalidUrls = [
        // Non-network URLs
        'file:///local/path/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp',
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',

        // Invalid hash length (too short)
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece784418:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp',
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca7.webp',

        // Invalid hash length (too long)
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188g1:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp',
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca751.webp',

        // Missing colon separator
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp',

        // Missing file extension
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75',

        // Regular URLs without ION media pattern
        'https://example.com/image.jpg',
        'https://cdn.example.com/uploads/photo.png',
        'https://media.example.org/video.mp4',

        // Empty and malformed URLs
        '',
        'not-a-url',
        'https://',
        'http://example.com',
        'https://example.com/',

        // Multiple colons
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75:extra.webp',

        // Hash at beginning or middle of path
        'https://example.com/171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.webp/extra',
        'https://171d12ae12100e0a9b9be38b56008f17fc8341f3bfcab5e2347029ece7844188:e5f9ca33dd68bc4f79e7bf25e338a253921c3006dbb7b807a93f6959aecdca75.example.com/file.webp',
      ];

      for (final url in invalidUrls) {
        expect(isIonMediaUrl(url), isFalse);
      }
    });
  });
  group('fileUriToPath', () {
    test('returns path as-is when it does not start with file://', () {
      const path = '/storage/emulated/0/video.mp4';

      final result = fileUriToPath(path);

      expect(result, path);
    });

    test('handles file:// URI with special characters', () {
      const fileUri = 'file:///storage/emulated/0/My%20Video%20File.mp4';
      const expectedPath = '/storage/emulated/0/My Video File.mp4';

      final result = fileUriToPath(fileUri);

      expect(result, expectedPath);
    });

    test('handles file:// URI with spaces (already decoded)', () {
      const fileUri = 'file:///storage/emulated/0/My Video File.mp4';
      const expectedPath = '/storage/emulated/0/My Video File.mp4';

      final result = fileUriToPath(fileUri);

      expect(result, expectedPath);
    });

    test('handles relative path without file:// prefix', () {
      const relativePath = 'videos/export.mp4';

      final result = fileUriToPath(relativePath);

      expect(result, relativePath);
    });

    test('handles empty string', () {
      const emptyPath = '';

      final result = fileUriToPath(emptyPath);

      expect(result, emptyPath);
    });

    test('handles path with Unicode characters', () {
      const path = '/storage/emulated/0/视频.mp4';

      final result = fileUriToPath(path);

      expect(result, path);
    });

    test('handles file:// URI with Unicode characters', () {
      const fileUri = 'file:///storage/emulated/0/%E8%A7%86%E9%A2%91.mp4';
      const expectedPath = '/storage/emulated/0/视频.mp4';

      final result = fileUriToPath(fileUri);

      expect(result, expectedPath);
    });

    test('does not modify https:// URLs', () {
      const httpsUrl = 'https://example.com/video.mp4';

      final result = fileUriToPath(httpsUrl);

      expect(result, httpsUrl);
    });

    test('does not modify content:// URIs', () {
      const contentUri = 'content://media/external/images/media/1000025399';

      final result = fileUriToPath(contentUri);

      expect(result, contentUri);
    });

    test('handles thumbnail preview path format', () {
      // Real-world example from the bug fix
      const fileUri =
          'file:///storage/emulated/0/Android/data/io.ion.app/files/export/export_preview-2025-10-17T20-58-36.526.png';
      const expectedPath =
          '/storage/emulated/0/Android/data/io.ion.app/files/export/export_preview-2025-10-17T20-58-36.526.png';

      final result = fileUriToPath(fileUri);

      expect(result, expectedPath);
    });
  });

  group('isNetworkUrl', () {
    test('returns true for http URLs', () {
      expect(isNetworkUrl('http://example.com'), isTrue);
    });

    test('returns true for https URLs', () {
      expect(isNetworkUrl('https://example.com'), isTrue);
    });

    test('returns false for file:// URIs', () {
      expect(isNetworkUrl('file:///storage/video.mp4'), isFalse);
    });

    test('returns false for content:// URIs', () {
      expect(isNetworkUrl('content://media/external/images/media/123'), isFalse);
    });

    test('returns false for local file paths', () {
      expect(isNetworkUrl('/storage/emulated/0/video.mp4'), isFalse);
    });

    test('returns false for empty string', () {
      expect(isNetworkUrl(''), isFalse);
    });

    test('returns false for relative paths', () {
      expect(isNetworkUrl('videos/example.mp4'), isFalse);
    });
  });
}
