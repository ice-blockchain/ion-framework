// SPDX-License-Identifier: ice License 1.0

import 'package:flutter_test/flutter_test.dart';
import 'package:ion/app/utils/url.dart';

import '../test_utils.dart';

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

  parameterizedGroup('fileUriToPath', [
    (
      description: 'returns path as-is when it does not start with file://',
      input: '/storage/emulated/0/video.mp4',
      expected: '/storage/emulated/0/video.mp4',
    ),
    (
      description: 'handles file:// URI with special characters',
      input: 'file:///storage/emulated/0/My%20Video%20File.mp4',
      expected: '/storage/emulated/0/My Video File.mp4',
    ),
    (
      description: 'handles file:// URI with spaces (already decoded)',
      input: 'file:///storage/emulated/0/My Video File.mp4',
      expected: '/storage/emulated/0/My Video File.mp4',
    ),
    (
      description: 'handles relative path without file:// prefix',
      input: 'videos/export.mp4',
      expected: 'videos/export.mp4',
    ),
    (
      description: 'handles empty string',
      input: '',
      expected: '',
    ),
    (
      description: 'handles path with Unicode characters',
      input: '/storage/emulated/0/视频.mp4',
      expected: '/storage/emulated/0/视频.mp4',
    ),
    (
      description: 'handles file:// URI with Unicode characters',
      input: 'file:///storage/emulated/0/%E8%A7%86%E9%A2%91.mp4',
      expected: '/storage/emulated/0/视频.mp4',
    ),
    (
      description: 'does not modify https:// URLs',
      input: 'https://example.com/video.mp4',
      expected: 'https://example.com/video.mp4',
    ),
    (
      description: 'does not modify content:// URIs',
      input: 'content://media/external/images/media/1000025399',
      expected: 'content://media/external/images/media/1000025399',
    ),
    (
      description: 'handles thumbnail preview path format',
      input:
          'file:///storage/emulated/0/Android/data/io.ion.app/files/export/export_preview-2025-10-17T20-58-36.526.png',
      expected:
          '/storage/emulated/0/Android/data/io.ion.app/files/export/export_preview-2025-10-17T20-58-36.526.png',
    ),
  ], (t) {
    test(t.description, () {
      final result = fileUriToPath(t.input);
      expect(result, t.expected);
    });
  });

  parameterizedGroup('isNetworkUrl', [
    (
      description: 'returns true for http URLs',
      input: 'http://example.com',
      expected: true,
    ),
    (
      description: 'returns true for https URLs',
      input: 'https://example.com',
      expected: true,
    ),
    (
      description: 'returns false for file:// URIs',
      input: 'file:///storage/video.mp4',
      expected: false,
    ),
    (
      description: 'returns false for content:// URIs',
      input: 'content://media/external/images/media/123',
      expected: false,
    ),
    (
      description: 'returns false for local file paths',
      input: '/storage/emulated/0/video.mp4',
      expected: false,
    ),
    (
      description: 'returns false for empty string',
      input: '',
      expected: false,
    ),
    (
      description: 'returns false for relative paths',
      input: 'videos/example.mp4',
      expected: false,
    ),
  ], (t) {
    test(t.description, () {
      final result = isNetworkUrl(t.input);
      expect(result, t.expected);
    });
  });
}
