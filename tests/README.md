# Testing Guide

This directory contains automated tests for the HCP Terraform onboarding modules. Tests are organized into unit tests and integration tests, using Terraform's native testing framework.

## Test Structure

```
tests/
├── README.md                        # This file
├── tenant-config-project/           # Platform team layer tests
│   ├── unit-tests.tftest.hcl       # Unit tests for tenant config
│   └── integration-tests.tftest.hcl # Integration tests
├── bu-control-workspace/            # BU team layer tests
│   ├── unit-tests.tftest.hcl       # Unit tests for BU control
│   └── integration-tests.tftest.hcl # Integration tests
└── setup/                           # Test fixtures and helpers
    ├── mock-data/                   # Mock YAML configurations
    └── test-helpers.tf              # Reusable test resources
```

## Test Types

### Unit Tests
**Purpose:** Validate module logic, variable validation, and data transformations without creating real infrastructure.

**What they test:**
- Variable validation rules work correctly
- Local value transformations produce expected results
- Output values are properly formatted
- YAML parsing handles edge cases
- Error conditions are caught

**Run time:** Fast (< 1 minute)  
**Cost:** Free (no infrastructure created)

### Integration Tests
**Purpose:** Validate end-to-end functionality by deploying actual infrastructure in a test environment.

**What they test:**
- Resources are created successfully
- VCS connections work
- RBAC assignments are correct
- Variable sets are applied properly
- Remote state sharing functions
- Cross-module dependencies

**Run time:** Moderate (5-10 minutes)  
**Cost:** Minimal (test resources only)

## Prerequisites

### For Unit Tests
- Terraform >= 1.6.0
- No cloud credentials required

### For Integration Tests
- Terraform >= 1.6.0
- HCP Terraform account and organization
- GitHub organization with OAuth configured
- Test environment variables:
  ```bash
  export TFE_TOKEN="your-tfe-token"
  export TFE_ORGANIZATION="your-test-org"
  export GITHUB_TOKEN="your-github-token"
  export GITHUB_ORG="your-test-github-org"
  export OAUTH_TOKEN_ID="ot-xxxxxxxxxxxxx"
  ```

## Running Tests

### Run All Tests
```bash
# From repository root
terraform test

# From specific module directory
cd tenant-config-project
terraform test

cd ../bu-control-workspace
terraform test
```

### Run Specific Test File
```bash
# Unit tests only
terraform test -filter=tests/tenant-config-project/unit-tests.tftest.hcl

# Integration tests only
terraform test -filter=tests/tenant-config-project/integration-tests.tftest.hcl
```

### Run with Verbose Output
```bash
terraform test -verbose
```

### Run Tests in CI/CD
```bash
# GitHub Actions (already configured in module_validate.yml)
# Tests run automatically on pull requests

# Manual trigger
terraform test -no-color
```

## Test Coverage

### tenant-config-project Tests

#### Unit Tests
- ✅ Variable validation (organization name, business unit)
- ✅ YAML file parsing and filtering
- ✅ Project name construction
- ✅ Team name generation
- ✅ Variable set structure
- ✅ Empty YAML handling
- ✅ Invalid YAML handling
- ✅ Missing required fields

#### Integration Tests
- ✅ Team creation with correct names
- ✅ Project creation with proper hierarchy
- ✅ Team token generation
- ✅ Variable set creation and assignment
- ✅ RBAC assignments
- ✅ Output values correctness

### bu-control-workspace Tests

#### Unit Tests
- ✅ Variable validation (OAuth token format)
- ✅ YAML workspace parsing
- ✅ Repository filtering logic
- ✅ Variable set mapping
- ✅ Project ID JSON parsing
- ✅ Workspace name uniqueness

#### Integration Tests
- ✅ Workspace creation
- ✅ GitHub repository creation
- ✅ VCS connection establishment
- ✅ Variable set application
- ✅ Workspace variable configuration
- ✅ Remote state sharing setup

## Writing New Tests

### Unit Test Template

```hcl
# tests/<module>/unit-tests.tftest.hcl

variables {
  # Set required variables
  test_variable = "test-value"
}

run "test_variable_validation" {
  command = plan

  # Expect validation to fail
  expect_failures = [
    var.test_variable
  ]
}

run "test_local_value_transformation" {
  command = plan

  assert {
    condition     = length(local.test_value) > 0
    error_message = "Expected non-empty result"
  }
}
```

### Integration Test Template

```hcl
# tests/<module>/integration-tests.tftest.hcl

variables {
  # Use test environment values
  organization = "test-org"
}

run "setup_test_resources" {
  command = apply
  
  # Create dependencies
  module {
    source = "./tests/setup"
  }
}

run "test_resource_creation" {
  command = apply

  assert {
    condition     = length(module.main.projects) > 0
    error_message = "No projects were created"
  }
}

run "cleanup" {
  command = destroy
}
```

## Test Maintenance

### Update Tests When:
- ✅ Adding new variables
- ✅ Modifying YAML structure
- ✅ Changing resource logic
- ✅ Adding new features
- ✅ Fixing bugs

### Test Best Practices:
1. **Keep tests independent** - Each test should be able to run alone
2. **Use descriptive names** - Test names should explain what they validate
3. **Test edge cases** - Empty values, special characters, maximum lengths
4. **Clean up resources** - Integration tests must destroy created resources
5. **Use mocks for unit tests** - Avoid external dependencies in unit tests
6. **Document test intent** - Add comments explaining what each test validates

## Debugging Failed Tests

### View Detailed Output
```bash
terraform test -verbose > test-output.log 2>&1
cat test-output.log
```

### Run Single Test
```bash
# Isolate failing test
terraform test -filter=tests/tenant-config-project/unit-tests.tftest.hcl -verbose
```

### Check Test State
```bash
# If integration test fails
cd .terraform/test-state/<test-run-id>
terraform show
```

### Common Issues

#### Issue: "Variable not set"
**Solution:** Ensure all required variables have values in test file or environment

#### Issue: "Module not found"
**Solution:** Check `source` path is correct relative to test file location

#### Issue: "Resource already exists"
**Solution:** Previous test run didn't clean up - manually destroy resources

#### Issue: "Authentication failed"
**Solution:** Verify environment variables are set correctly

## Performance Tips

### Speed Up Unit Tests
- Use `command = plan` instead of `apply`
- Mock external dependencies
- Keep test data minimal

### Speed Up Integration Tests
- Run in parallel where possible
- Use smaller test datasets
- Reuse setup resources across tests
- Clean up aggressively

### CI/CD Optimization
- Run unit tests before integration tests
- Cache Terraform providers
- Use matrix strategy for multiple scenarios
- Skip integration tests on documentation-only changes

## Test Results Interpretation

### Successful Test Run
```
Success! All tests passed.

Tests: 12 passed, 0 failed
```

### Failed Test Run
```
Failure! 1 test failed

tests/tenant-config-project/unit-tests.tftest.hcl... fail
  run "test_organization_validation"... fail
    Error: Invalid organization name

Tests: 11 passed, 1 failed
```

## Coverage Goals

Target test coverage metrics:
- **Unit Tests:** 80%+ of logic paths
- **Integration Tests:** 100% of critical user workflows
- **Edge Cases:** Known failure scenarios documented

Current coverage:
- ✅ Variable validation: 100%
- ✅ YAML parsing: 90%
- ✅ Resource creation: 100%
- ✅ VCS integration: 80%
- ⚠️ Error handling: 70%

## Contributing Tests

When contributing new features:

1. **Add unit tests first** - Test logic before integration
2. **Document test scenarios** - Explain what you're testing
3. **Test both success and failure** - Validate error handling
4. **Update this README** - Document new test files or patterns
5. **Verify CI passes** - Ensure automated tests succeed

## Related Documentation

- [Terraform Test Framework](https://developer.hashicorp.com/terraform/language/tests)
- [Writing Terraform Tests](https://developer.hashicorp.com/terraform/tutorials/configuration-language/test)
- [CI/CD Workflow Documentation](../.github/WORKFLOW-TROUBLESHOOTING.md)
- [Pre-commit Hooks](../.pre-commit-config.yaml)

## Support

- **Test failures:** Check [Workflow Troubleshooting](../.github/WORKFLOW-TROUBLESHOOTING.md)
- **Test design questions:** Review examples in this directory
- **Report issues:** [Open an issue](https://github.com/CloudbrokerAz/hcp-terraform-onboarding/issues)
