# Claude Development Guidelines

This document contains important information and best practices learned while developing the `langfuse-ruby` gem. Please follow these guidelines when working on this project.

## Essential Commands to Run

### Before Making Changes
```bash
# Install dependencies
bundle install

# Run tests to ensure everything is working
bundle exec rspec

# Check code style
bundle exec rubocop
```

### After Making Changes
**ALWAYS run these commands before committing:**

```bash
# 1. Run tests to ensure nothing broke
bundle exec rspec

# 2. Run RuboCop to check for style violations
bundle exec rubocop

# 3. Auto-fix correctable violations
bundle exec rubocop -a

# 4. If complex violations remain, you may need manual fixes
bundle exec rubocop
```

## Key Learnings and Best Practices

### 1. Security - Credential Masking
- **NEVER log sensitive data in plain text**
- Always mask credentials, API keys, and tokens when logging
- Example from `lib/langfuse/api_client.rb`:
  ```ruby
  masked_auth = "#{auth[0..5]}...#{auth[-4..]}"
  masked_secret = @config.secret_key ? "#{@config.secret_key[0..7]}..." : 'nil'
  ```

### 2. Configuration Validation
- Always validate required configuration on initialization
- Provide helpful error messages listing all missing/invalid config
- See `validate_configuration!` method in `lib/langfuse/client.rb`

### 3. Job Backend Flexibility
- The gem supports multiple job backends (ActiveJob, Sidekiq, synchronous)
- Use the JobAdapter pattern for abstraction
- Auto-detect available backends when not explicitly configured
- Environment variable support: `LANGFUSE_JOB_BACKEND`

### 4. Testing with Mocks
- Disable Sorbet runtime checks in tests: `T::Configuration.default_checked_level = :never`
- Use `hash_including` for flexible hash matching in specs
- Be careful with constant stubbing - can cause conflicts between tests

### 5. Gem Structure
Critical files that must exist:
- `langfuse-ruby.gemspec` - Gem specification
- `Gemfile` - Development dependencies
- `Rakefile` - Build and test tasks
- `.gitignore` - Exclude build artifacts
- `.rubocop.yml` - Style configuration
- `CHANGELOG.md` - Document all changes
- Complete test coverage in `spec/`

### 6. Ruby Style Guide Compliance
The project uses RuboCop with some exceptions:
- Module length increased for helper modules
- Method length relaxed for complex operations
- Documentation cop disabled (we use YARD)
- Some RSpec cops disabled for flexibility

### 7. Sorbet Type Checking
- All files use Sorbet type annotations
- Use `T.unsafe` when interfacing with external libraries
- Keep type signatures up to date

### 8. Version Management
- Update version in `lib/langfuse/version.rb`
- Document changes in `CHANGELOG.md`
- Follow semantic versioning

## Common Issues and Solutions

### Issue: Tests failing due to constant already defined
**Solution:** Use proper test isolation and avoid loading files multiple times in tests.

### Issue: RuboCop violations after adding new code
**Solution:** Run `bundle exec rubocop -a` first, then fix remaining issues manually.

### Issue: Sorbet type errors in tests
**Solution:** Disable runtime checking in spec_helper.rb with `T::Configuration.default_checked_level = :never`

### Issue: Job backend not working as expected
**Solution:** Check the JobAdapter and ensure proper backend detection. Set `config.job_backend` explicitly if needed.

## Development Workflow

1. Create a todo list for complex tasks using `TodoWrite`
2. Make changes incrementally
3. Run tests after each significant change
4. Fix RuboCop violations before committing
5. Update CHANGELOG.md for user-facing changes
6. Write clear commit messages

## File Naming Conventions

- Snake_case for file names: `job_adapter.rb`
- Match class names to file names: `JobAdapter` → `job_adapter.rb`
- Place jobs in `lib/langfuse/jobs/`
- Place models in `lib/langfuse/models/`
- Mirror structure in specs: `spec/langfuse/jobs/`

## Testing Philosophy

- Test public interfaces, not implementation details
- Use doubles/mocks sparingly and prefer real objects when possible
- Write integration tests for critical paths
- Aim for high test coverage but focus on meaningful tests

## Remember

- **Always run tests and RuboCop before committing**
- **Never commit credentials or sensitive data**
- **Update documentation when changing public APIs**
- **Follow existing patterns in the codebase**
- **Ask for clarification rather than making assumptions**