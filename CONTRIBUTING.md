# Contributing to Langfuse Ruby SDK

Thank you for your interest in contributing to the Langfuse Ruby SDK! This guide will help you get started.

## Getting Started

### Prerequisites

- Ruby 2.7 or higher
- Bundler
- Git

### Setup

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/langfuse-ruby.git
   cd langfuse-ruby
   ```
3. Install dependencies:
   ```bash
   bundle install
   ```
4. Run tests to ensure everything is working:
   ```bash
   bundle exec rspec
   ```

## Development Process

### 1. Create a Branch

Create a feature branch for your changes:
```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

- Write clean, readable code
- Follow Ruby style conventions
- Add tests for new functionality
- Update documentation as needed

### 3. Testing

**Always run tests before committing:**
```bash
bundle exec rspec
```

For coverage report:
```bash
bundle exec rake coverage
```

### 4. Code Style

**Always check code style before committing:**
```bash
# Check for violations
bundle exec rubocop

# Auto-fix correctable issues
bundle exec rubocop -a
```

### 5. Commit Your Changes

Write clear, descriptive commit messages:
```bash
git add .
git commit -m "Add support for X feature

- Detailed description of what changed
- Why the change was needed
- Any breaking changes or migration notes"
```

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub with:
- Clear description of changes
- Link to any related issues
- Test results confirmation
- Screenshots if applicable

## Code Guidelines

### Ruby Style

We use RuboCop for style enforcement. Configuration is in `.rubocop.yml`.

Key conventions:
- 2 spaces for indentation
- No trailing whitespace
- Frozen string literals in all files
- Descriptive variable and method names

### Testing

- Write RSpec tests for all new functionality
- Maintain or improve code coverage
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

Example:
```ruby
RSpec.describe Langfuse::Client do
  describe '#trace' do
    it 'creates a new trace with given attributes' do
      # Arrange
      attributes = { name: 'test-trace', user_id: 'user-123' }
      
      # Act
      trace = subject.trace(attributes)
      
      # Assert
      expect(trace.name).to eq('test-trace')
      expect(trace.user_id).to eq('user-123')
    end
  end
end
```

### Type Annotations

We use Sorbet for type checking. Add type signatures to methods:
```ruby
sig { params(name: String, value: T.nilable(Integer)).returns(T::Boolean) }
def process_data(name, value = nil)
  # implementation
end
```

### Documentation

- Add YARD documentation to public methods
- Update README.md for new features
- Add entries to CHANGELOG.md
- Include examples where helpful

## Testing Different Job Backends

The SDK supports multiple job backends. Test your changes with:

### Synchronous Mode
```ruby
Langfuse.configure do |config|
  config.job_backend = :synchronous
end
```

### With Sidekiq
```ruby
# Add sidekiq to Gemfile
gem 'sidekiq'

Langfuse.configure do |config|
  config.job_backend = :sidekiq
end
```

### With ActiveJob
```ruby
# In a Rails app
Langfuse.configure do |config|
  config.job_backend = :active_job
end
```

## Common Tasks

### Running specific tests
```bash
bundle exec rspec spec/langfuse/client_spec.rb
```

### Generating Sorbet RBI files
```bash
bundle exec rake tapioca
```

### Opening console for testing
```bash
bundle exec rake console
```

### Building the gem locally
```bash
gem build langfuse-ruby.gemspec
```

## Checklist Before Submitting PR

- [ ] Tests pass (`bundle exec rspec`)
- [ ] RuboCop passes (`bundle exec rubocop`)
- [ ] Documentation updated if needed
- [ ] CHANGELOG.md updated
- [ ] Commit messages are clear
- [ ] Branch is up to date with main

## Areas for Contribution

We especially welcome contributions in these areas:

1. **Additional Job Backends** - Support for more queue systems
2. **Performance Improvements** - Optimizing batch processing
3. **Error Handling** - Better retry strategies and error recovery
4. **Documentation** - Examples, guides, and API docs
5. **Test Coverage** - Additional test scenarios
6. **Rails Integration** - Improved Rails generators and helpers

## Questions?

Feel free to:
- Open an issue for discussion
- Ask questions in pull requests
- Check existing issues and PRs for context

## Code of Conduct

Please be respectful and constructive in all interactions. We want this to be a welcoming project for all contributors.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.