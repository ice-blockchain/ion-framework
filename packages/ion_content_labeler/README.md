# Ion Content Labeler

A plugin for analyzing input text and generating corresponding labels, including:
- Detected language
- Content categories

## Rebuilding FastText Library

This project uses [fastText lib](https://github.com/ice-blockchain/fastText)

### Source Files

The core implementation with visible symbols is located in:
[`fasttext_predict.cpp`](https://github.com/ice-blockchain/fastText/blob/main/fasttext_predict.cpp)

### Compilation

Platform-specific build scripts are provided:

* [Android](https://github.com/ice-blockchain/fastText/blob/main/compile_android.sh)
* [iOS](https://github.com/ice-blockchain/fastText/blob/main/compile_ios.sh)