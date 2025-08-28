# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2024-12-28

### Added
- **Tool Observations** - New `Tool` model and methods for tracking tool/function calls in LLM applications
  - `Langfuse.tool()` - Create a tool observation to track tool invocations
  - `Langfuse.update_tool()` - Update tool observations with results after execution
  - Includes fields for `tool_name`, `tool_call_id`, and `arguments` to properly track tool usage
- Comprehensive test coverage for tool observations

## [2.0.0] - 2024-12-27

### Breaking Changes
- **Removed Sorbet** - All Sorbet type checking has been removed from the codebase
- **Explicit backend loading** - Job backends now require explicit requires:
  - ActiveJob: `require 'langfuse-ruby/active_job'`
  - Sidekiq: `require 'langfuse-ruby/sidekiq'`
- **No more auto-detection** - Removed automatic backend detection

### Added
- **Configurable queue name** - The queue name for background jobs is now configurable via `config.queue_name` or the `LANGFUSE_QUEUE_NAME` environment variable
- Support for custom queue names in both ActiveJob (including Solid Queue) and Sidekiq backends
- Simplified architecture for better Rails/Solid Queue compatibility

### Fixed
- Fixed "uninitialized constant Langfuse::Jobs" error in Rails/Solid Queue
- Improved constant loading for background job frameworks

### Removed
- Removed all Sorbet runtime dependencies and type annotations
- Removed complex conditional class loading
- Removed automatic job backend detection

## [1.0.0] - 2024-12-26

### Added
- Fork of the original `langfuse` gem to provide open-source maintenance
- Complete test suite with RSpec
- RuboCop integration for code quality
- Configuration validation with helpful error messages
- `.gitignore` file for proper version control
- `Gemfile` and `Rakefile` for standard Ruby gem development
- This CHANGELOG file
- **ActiveJob support** - Modern Rails applications can now use ActiveJob with any backend (Solid Queue, GoodJob, etc.)
- **Job adapter system** - Flexible backend selection for job processing
- Auto-detection of available job backends
- Environment variable support for job backend configuration (`LANGFUSE_JOB_BACKEND`)

### Changed
- **BREAKING**: Renamed gem from `langfuse` to `langfuse-ruby` to avoid conflicts
- Bumped version to 1.0.0 for the fork
- Updated author information (Finbarr Taylor)
- Refactored job processing to support multiple backends (ActiveJob, Sidekiq, synchronous)

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