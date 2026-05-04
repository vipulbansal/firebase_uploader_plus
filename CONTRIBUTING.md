# Contributing to firebase_uploader_plus

Thank you for your interest in contributing to firebase_uploader_plus! We welcome contributions from the community.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/vipulbansal/firebase_uploader_plus.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes: `git commit -m "Add your feature"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Setup

1. Use **Flutter 3.41.7+** and **Dart 3.11+** (see `pubspec.yaml`). With [FVM](https://fvm.app): `fvm use 3.41.7` then `fvm flutter pub get`.
2. Run `flutter pub get` (or `fvm flutter pub get`) to install dependencies
3. Set up Firebase project for testing:
   - Create a new Firebase project
   - Enable Firebase Storage and Firestore
   - Add your configuration files
4. Run the example app: `cd example && flutter run`

## Code Guidelines

### Code Style
- Follow the official Dart style guide
- Use `dart format` to format your code
- Run `dart analyze` to check for issues
- Ensure all tests pass: `flutter test`

### Documentation
- Add documentation for all public APIs
- Include usage examples for new features
- Update README.md if needed
- Add entries to CHANGELOG.md for new versions

### Testing
- Write unit tests for new functionality
- Test on multiple platforms when possible
- Ensure example app works with your changes
- Test with different Firebase configurations

## Pull Request Process

1. Ensure your code follows the style guidelines
2. Add tests for new functionality
3. Update documentation as needed
4. Ensure all existing tests pass
5. Add a clear description of your changes
6. Reference any related issues

## Reporting Issues

When reporting issues, please include:
- Flutter version
- Platform (iOS, Android, Web, etc.)
- Firebase SDK versions
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs

## Feature Requests

For feature requests:
- Check if the feature already exists
- Describe the use case clearly
- Explain why it would be beneficial
- Consider contributing the implementation

## Publishing to pub.dev

1. Commit a clean tree (`git status` should show no unexpected changes).
2. Use Flutter **3.41.7+** (for example `fvm flutter pub publish`).
3. Log in once: `dart pub token add https://pub.dev`.
4. Dry run: `flutter pub publish --dry-run` — fix any validation errors.
5. Publish: `flutter pub publish` and confirm when prompted.

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Follow community guidelines

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Check existing issues and discussions
- Review the documentation

Thank you for contributing!