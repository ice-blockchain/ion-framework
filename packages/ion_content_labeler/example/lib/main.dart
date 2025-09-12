// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';

void main() {
  runApp(const MyApp());
}

const _initialInput =
    'A mysterious new cryptocurrency called NebulaCoin (NBC) has surged over 400% in just 24 hours after rumors linked it to a partnership with a major gaming company. Analysts claim the coin’s blockchain could revolutionize in-game economies, sparking massive interest on social media. Meanwhile, skeptics warn it might just be another short-lived hype cycle.';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _controller = TextEditingController(text: _initialInput);

  final IONTextLabeler _labeler = IONTextLabeler();

  String? _normalizedInput;

  String? _languages;

  String? _categories;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ION Content Labeler Example'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  minLines: 5,
                  maxLines: 20,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _onButtonPressed,
                  child: const Text('run'),
                ),
                const SizedBox(height: 10),
                if (_normalizedInput != null) ...[
                  Text('Normalized input is:\n$_normalizedInput'),
                  const SizedBox(height: 10),
                ],
                if (_languages != null) ...[
                  Text('Languages are:\n$_languages'),
                  const SizedBox(height: 10),
                ],
                if (_categories != null) ...[
                  Text('Categories are:\n$_categories'),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onButtonPressed() {
    setState(() {
      _normalizedInput = null;
      _languages = null;
      _categories = null;
    });
    final input = _controller.text;

    _labeler.detect(input, model: TextLabelerModel.language).then((result) {
      setState(
        () {
          _languages = result.labels.join('\n');
          _normalizedInput = result.input;
        },
      );
    });
    _labeler.detect(input, model: TextLabelerModel.category).then((result) {
      setState(
        () {
          _categories = result.labels.join('\n');
        },
      );
    });
  }
}
