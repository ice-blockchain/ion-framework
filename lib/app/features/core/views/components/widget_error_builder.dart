// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ion/app/services/logger/logger.dart';

class WidgetErrorBuilder extends StatelessWidget {
  const WidgetErrorBuilder(this.errorDetails, {super.key});

  final FlutterErrorDetails errorDetails;

  @override
  Widget build(BuildContext context) {
    final exception = errorDetails.exceptionAsString();
    final stackTrace = errorDetails.stack?.toString() ?? 'No stack trace available';
    final stackTracePreview = stackTrace.split('\n').take(8).join('\n');
    final fullErrorDetails = 'Exception:\n$exception\n\nStack trace:\n$stackTrace';

    Logger.error(
      errorDetails.exception,
      stackTrace: errorDetails.stack,
      message: 'Widget build error fallback rendered',
    );

    if (kDebugMode) return ErrorWidget(errorDetails);

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                const Text('Error details:'),
                const SizedBox(height: 6),
                SelectableText(
                  exception,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 12),
                const Text('Stack trace (preview):'),
                const SizedBox(height: 6),
                SelectableText(
                  stackTracePreview,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: fullErrorDetails));
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error details copied')),
                    );
                  },
                  child: const Text('Copy error details'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
