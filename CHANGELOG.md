# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-26

### Added
- Fork of the original `langfuse` gem to provide open-source maintenance
- Complete test suite with RSpec
- RuboCop integration for code quality
- Configuration validation with helpful error messages
- `.gitignore` file for proper version control
- `Gemfile` and `Rakefile` for standard Ruby gem development
- This CHANGELOG file

### Changed
- **BREAKING**: Renamed gem from `langfuse` to `langfuse-ruby` to avoid conflicts
- Bumped version to 1.0.0 for the fork
- Updated author information (Finbarr Taylor)

### Fixed
- **Security**: Fixed credential logging issue - sensitive data (secret keys and auth tokens) are now properly masked in debug logs
- Added frozen string literal comments to all Ruby files
- Fixed various RuboCop style violations
- Improved code organization and style consistency

### Security
- Credentials are no longer logged in plain text when debug mode is enabled
- Auth tokens and secret keys are masked with partial visibility for debugging

## [0.1.1] - Original Version

- Original `langfuse` gem implementation
- Basic functionality for Langfuse observability platform
- Trace, span, generation, event, and score creation
- Batch processing with optional Sidekiq support
- Configurable flush intervals and batch sizes