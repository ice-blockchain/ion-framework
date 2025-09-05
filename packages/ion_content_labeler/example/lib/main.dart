// SPDX-License-Identifier: ice License 1.0

import 'package:flutter/material.dart';
import 'package:ion_content_labeler/ion_content_labeler.dart';

void main() {
  runApp(const MyApp());
}

final _initialInput =
    '''Trump is trying to deport a Columbia Univ. student who has been a permanent resident in the U.S. since she was 7.
Her "crime"?
Attending a protest against the war in Gaza.
No, Mr. President. This is a democracy. You can't exile political dissidents. Not in the United States.''';

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
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _onButtonPressed,
                  child: Text('run'),
                ),
                SizedBox(height: 10),
                if (_normalizedInput != null) ...[
                  Text('Normalized input is:\n$_normalizedInput'),
                  SizedBox(height: 10)
                ],
                if (_languages != null) ...[
                  Text('Languages are:\n$_languages'),
                  SizedBox(height: 10)
                ],
                if (_categories != null) ...[
                  Text('Categories are:\n$_categories'),
                  SizedBox(height: 10)
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
