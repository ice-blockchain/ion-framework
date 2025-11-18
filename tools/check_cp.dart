import 'dart:io';

/// Simple logger abstraction that avoids direct print() calls.
class Logger {
  void info(String message) => stdout.writeln(message);
  void error(String message) => stderr.writeln(message);
  void command(String message) => stdout.writeln('\n> $message');
}

final _log = Logger();

Future<void> main(List<String> arguments) async {
  try {
    await _ensureGitAvailable();

    if (arguments.isEmpty) {
      _log.error('Usage: dart tools/check_cp.dart <commit-sha>');
      exitCode = 1;
      return;
    }

    final sha = arguments.first.trim();
    if (!_isValidSha(sha)) {
      _log.error('Invalid SHA: "$sha". Expected at least 7 hex characters.');
      exitCode = 1;
      return;
    }

    await _ensureCommitExists(sha);

    final containsReleaseCandidate = await _isDirectlyOnReleaseCandidate(sha);
    if (containsReleaseCandidate) {
      _log.info(
        "Commit $sha is directly contained in 'release_candidate' branch.",
      );
      exitCode = 0;
      return;
    }

    final cherryStatus = await _cherryStatusRelativeToReleaseCandidate(sha);

    switch (cherryStatus) {
      case _CherryStatus.patchPresent:
        _log.info(
          "Patch from commit $sha is already present in 'release_candidate' "
          'via a different commit (cherry-pick or rebase).',
        );
        exitCode = 0;
        return;
      case _CherryStatus.patchMissing:
        _log.info(
          "Patch from commit $sha is NOT present in 'release_candidate' when "
          "compared against 'master'.",
        );
        exitCode = 2;
        return;
      case _CherryStatus.notComparable:
        _log.info(
          'Commit $sha was not found in the comparison set of '
          "'git cherry release_candidate master'. "
          'It may not be reachable from master or comparison is not applicable.',
        );
        exitCode = 3;
        return;
    }
  } catch (error, stackTrace) {
    _log
      ..error('Error: $error')
      ..error(stackTrace.toString());
    exitCode = 1;
  }
}

bool _isValidSha(String sha) => RegExp(r'^[0-9a-fA-F]{7,40}$').hasMatch(sha.trim());

/// Ensures `git` is installed and available.
Future<void> _ensureGitAvailable() async {
  final result = await _runResult('git --version');
  if (!result.startsWith('git version')) {
    throw Exception('Git is not installed or not available in PATH.');
  }
}

/// Ensures the given commit exists in the local repository.
Future<void> _ensureCommitExists(String sha) async {
  final result = await Process.run(
    'bash',
    ['-c', 'git cat-file -e $sha^{commit}'],
  );

  if (result.exitCode != 0) {
    throw Exception('Commit $sha does not exist in this repository.');
  }
}

/// Returns true if the commit SHA is directly contained in release_candidate.
Future<bool> _isDirectlyOnReleaseCandidate(String sha) async {
  final output = await _runResult(
    'git branch --contains $sha || true',
  );

  final branches = output
      .split('\n')
      .map((line) => line.replaceFirst('*', '').trim())
      .where((line) => line.isNotEmpty)
      .toSet();

  return branches.contains('release_candidate');
}

enum _CherryStatus {
  patchPresent,
  patchMissing,
  notComparable,
}

/// Determines whether the patch from [sha] is present on release_candidate
/// when comparing `release_candidate` with `master` using `git cherry`.
Future<_CherryStatus> _cherryStatusRelativeToReleaseCandidate(
  String sha,
) async {
  // git cherry lists commits that are in the second branch (master) but
  // not in the first (release_candidate), with:
  //   + <sha> for commits missing from release_candidate
  //   - <sha> for commits whose patch is already present on release_candidate
  final output = await _runResult('git cherry release_candidate master');

  final line = output.split('\n').map((line) => line.trim()).firstWhere(
        (line) => line.endsWith(sha),
        orElse: () => '',
      );

  if (line.isEmpty) {
    return _CherryStatus.notComparable;
  }

  if (line.startsWith('-')) {
    return _CherryStatus.patchPresent;
  }
  if (line.startsWith('+')) {
    return _CherryStatus.patchMissing;
  }

  return _CherryStatus.notComparable;
}

/// Executes a command and returns stdout as string.
Future<String> _runResult(String cmd) async {
  final result = await Process.run('bash', ['-c', cmd]);
  if (result.exitCode != 0) {
    throw Exception('Command failed: $cmd');
  }
  return result.stdout.toString();
}
