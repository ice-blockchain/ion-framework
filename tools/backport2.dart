import 'dart:io';

/// Simple logger abstraction that avoids direct print() calls.
class Logger {
  void info(String message) => stdout.writeln(message);
  void error(String message) => stderr.writeln(message);
  void command(String message) => stdout.writeln('\n> $message');
}

final _log = Logger();

Future<void> main() async {
  await _ensureGitAvailable();

  await _fetchAll();
  await _updateMaster();

  final sha = await _selectCommit();
  final branchName = await _promptBranchName();

  await _prepareReleaseCandidate();
  await _createBranch(branchName);

  await _cherryPick(sha);

  _log
    ..info("\nBranch '$branchName' is ready.")
    ..info('Push it manually when ready:')
    ..info('  git push --set-upstream origin $branchName');
}

/// Ensures `git` is installed and available.
Future<void> _ensureGitAvailable() async {
  final result = await _runResult('git --version');
  if (!result.startsWith('git version')) {
    throw Exception('Git is not installed or not available in PATH.');
  }
}

/// Fetches all remote refs.
Future<void> _fetchAll() async {
  _log.command('git fetch --all');
  await _run('git fetch --all');
}

/// Updates master branch.
Future<void> _updateMaster() async {
  _log.command('git checkout master');
  await _run('git checkout master');

  _log.command('git pull origin master');
  await _run('git pull origin master');
}

/// Lets the user select a commit SHA from the last 20 master commits.
Future<String> _selectCommit() async {
  final logResult = await _runResult(
    'git log master --pretty=format:"%h %s" -n 100',
  );

  final lines = logResult.trim().split('\n');

  _log.info('\nLast master commits:');
  for (var i = 0; i < lines.length; i++) {
    _log.info('${i + 1}. ${lines[i]}');
  }

  stdout.write(
    '\nEnter commit number (1-${lines.length}) or SHA manually: ',
  );

  final input = stdin.readLineSync()?.trim();
  if (input == null || input.isEmpty) {
    throw Exception('No commit input provided.');
  }

  final isSha = RegExp(r'^[0-9a-fA-F]{7,}$').hasMatch(input);

  if (isSha) {
    return input;
  }

  final index = int.tryParse(input);
  if (index == null || index < 1 || index > lines.length) {
    throw Exception('Invalid commit selection.');
  }

  return lines[index - 1].split(' ').first;
}

/// Reads desired branch name from user and applies backport/ prefix.
Future<String> _promptBranchName() async {
  stdout.write(
    "\nEnter new branch name (with or without prefix 'backport/'): ",
  );
  final input = stdin.readLineSync()?.trim();

  if (input == null || input.isEmpty) {
    throw Exception('Branch name cannot be empty.');
  }

  return input.startsWith('backport/') ? input : 'backport/$input';
}

/// Ensures release_candidate is up to date.
Future<void> _prepareReleaseCandidate() async {
  _log.command('git checkout release_candidate');
  await _run('git checkout release_candidate');

  _log.command('git pull origin release_candidate');
  await _run('git pull origin release_candidate');
}

/// Creates a new branch from release_candidate.
Future<void> _createBranch(String branchName) async {
  _log.command('git checkout -b $branchName');
  await _run('git checkout -b $branchName');
}

/// Executes the cherry-pick logic.
Future<void> _cherryPick(String sha) async {
  _log.command('git cherry-pick $sha');

  final result = await Process.run(
    'bash',
    ['-c', 'git cherry-pick $sha'],
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    _log
      ..error('\nCherry-pick completed with conflicts.')
      ..error('Resolve conflicts manually, then continue.');

    // Create a commit marking conflict state for consistency.
    await _run('git add -A');
    await _run('git commit -m "Cherry-pick with conflicts: $sha"');
  } else {
    _log.info('\nCherry-pick completed successfully.');
  }
}

/// Executes a command, streaming output directly.
Future<void> _run(String cmd) async {
  final result = await Process.run('bash', ['-c', cmd]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode != 0) {
    throw Exception('Command failed: $cmd');
  }
}

/// Executes a command and returns stdout as string.
Future<String> _runResult(String cmd) async {
  final result = await Process.run('bash', ['-c', cmd]);
  if (result.exitCode != 0) {
    throw Exception('Command failed: $cmd');
  }
  return result.stdout.toString();
}
