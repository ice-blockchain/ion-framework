# ION Framework

The ION Framework, built using Flutter, which allows anyone to create and deploy cross-platform DApps easily.

# Getting started

## Set up environment

All environment-related files and keys are stored separately in the [secrets repository](https://github.com/ice-blockchain/flutter-app-secrets).

Clone the [secrets repository](https://github.com/ice-blockchain/flutter-app-secrets) and place it at the same directory level as the main project repository.
Example directory structure:
```
    ~/projects/flutter-app
    ~/projects/flutter-app-secrets
```
To switch or set up an environment, run the `./scripts/configure_env.sh` script from the root of the main app project passing it a desired environment (`staging` / `production` / `testnet`).
Example:

```
./scripts/configure_env.sh staging
```

## Install asdf

To ensure that everyone uses the exact same Flutter version we use asdf. To install it there is a script. It will also create a VSCode settings file with the Flutter SDK path
```
./scripts/asdf.sh
```

## Set up git hooks

```
./scripts/install_hooks.sh
```

We use Git hooks to ensure that commits adhere to the rules set by our code analyzer.

To set up the hooks, run the script once from the root of the main project. All the precommit hooks are defined in `pre_commit.sh` script, if the content of this files changes, the hooks should be updated using the same `install_hooks.sh` script.

## Set up Melos

```
./scripts/bootstrap.sh
```

We maintain additional packages alongside the main app package (currently, only `packages/ion_identity_client` at the time of writing the README). To simplify the organization of this process, we use Melos. To set it up, simply run the script once. 

## Generate code / locales

```
./scripts/generate_code.sh && ./scripts/generate_locales.sh
```

We use dart code generation in conjunction with libraries like `freezed`, `widgetbook`, `riverpod` and many other third-party libs. The code generation for locales is handled by a separate script, allowing you to trigger this process when, for instance, an `*.arb` file is saved.

## Get dependencies

```
melos run pub_get
```
Since we use monorepo with several packages, we need to download dependencies for each package. To simplify this process, we use Melos, which allows us to define commands that run across all packages. For a list of available commands, check `melos.yaml`.

# Run the project

You should pass environment variables to Flutter compiler:
```
asdf exec flutter run --dart-define-from-file=.merged.app.env
```


> [!IMPORTANT]
> To run the project on Android with staging environment, we need to specify the `flavor`:
> ```flutter run --flavor=staging```
