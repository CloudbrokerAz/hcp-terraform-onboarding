# Test Setup Resources and Helpers
#
# This directory contains reusable test fixtures, mock data, and helper
# configurations used across unit and integration tests.

## Directory Structure

```
setup/
├── README.md                    # This file
├── mock-data/                   # Mock YAML configurations
│   ├── tenant-config/           # Platform team test data
│   │   ├── minimal-bu.yaml     # Minimal BU config
│   │   ├── complete-bu.yaml    # Full-featured BU config
│   │   └── invalid-bu.yaml     # Invalid config for error testing
│   └── bu-control/              # BU team test data
│       ├── minimal-workspace.yaml
│       ├── complete-workspace.yaml
│       └── invalid-workspace.yaml
└── test-helpers.tf              # Reusable test resources (future)
```

## Mock Data Files

### tenant-config Mock Data

**minimal-bu.yaml** - Minimal valid business unit configuration
- Single project
- Basic team access
- No SSO integration
- Simple variable sets

**complete-bu.yaml** - Full-featured business unit configuration
- Multiple projects (dev, staging, prod)
- SSO team integration
- Custom RBAC configurations
- Complex variable sets with multiple variables
- Tags and descriptions

**invalid-bu.yaml** - Invalid configuration for error testing
- Missing required fields
- Invalid YAML syntax
- Unsupported data types
- Used to verify error handling

### bu-control Mock Data

**minimal-workspace.yaml** - Minimal workspace configuration
- Basic workspace settings
- No GitHub repo creation
- Simple variables
- No VCS integration

**complete-workspace.yaml** - Full-featured workspace configuration
- GitHub repository creation
- VCS integration
- Variable sets
- Remote state sharing
- Agent pool configuration
- RBAC settings

**invalid-workspace.yaml** - Invalid workspace configuration
- Missing required fields
- Invalid values
- Used for validation testing

## Using Mock Data in Tests

### In Unit Tests

```hcl
# Reference mock data in test assertions
run "test_yaml_parsing" {
  command = plan

  # Copy mock file to config directory before test
  # (Handled by test setup in actual implementation)
  
  assert {
    condition     = can(local.workspaceConfig)
    error_message = "Should parse mock YAML successfully"
  }
}
```

### In Integration Tests

```hcl
# Use mock data to create test resources
variables {
  # Variables that point to mock data location
  test_config_dir = "./tests/setup/mock-data"
}

run "test_with_mock_data" {
  command = apply
  
  # Test uses mock YAML files from setup directory
}
```

## Test Helpers (Future)

The `test-helpers.tf` file will contain reusable Terraform configurations:

- **Mock TFE Provider Resources** - Stub resources for testing
- **Test Data Generators** - Functions to create test data
- **Assertion Helpers** - Custom validation logic
- **Cleanup Utilities** - Resource cleanup functions

## Creating New Mock Data

### Guidelines

1. **Keep it realistic** - Use patterns that match real-world usage
2. **Document purpose** - Add comments explaining test scenarios
3. **Maintain validity** - Ensure YAML is valid unless testing errors
4. **Version control** - Commit mock data with tests
5. **Update regularly** - Keep in sync with schema changes

### Template for New Mock YAML

```yaml
# Purpose: [Describe what this mock tests]
# Test scenario: [Explain the use case]
# Expected outcome: [What should happen]

# Actual YAML content
key: value
nested:
  property: value
```

## Integration with CI/CD

Mock data is used in automated testing:

1. **Pre-commit hooks** - Validate mock YAML syntax
2. **GitHub Actions** - Run tests with mock data
3. **Terraform validate** - Check module compatibility
4. **Security scans** - Ensure no credentials in mocks

## Best Practices

### DO:
- ✅ Use descriptive filenames
- ✅ Include comments in YAML
- ✅ Keep mock data minimal but complete
- ✅ Test both success and failure scenarios
- ✅ Update mocks when schema changes

### DON'T:
- ❌ Include real credentials or tokens
- ❌ Use production organization names
- ❌ Create unnecessarily complex mocks
- ❌ Duplicate mock data across tests
- ❌ Leave outdated mocks in repository

## Mock Data Maintenance

### When to Update:
- Module variables change
- YAML schema evolves
- New features are added
- Bug fixes require new test cases
- Security requirements change

### Update Checklist:
1. Review schema changes
2. Update relevant mock files
3. Run unit tests to verify
4. Update integration tests if needed
5. Document changes in commit message

## Contributing

When adding new tests that need mock data:

1. Create descriptive mock YAML file
2. Place in appropriate directory
3. Document purpose in file comments
4. Reference in test file
5. Update this README if adding new categories

## Related Documentation

- [Test README](../README.md) - Overall testing guide
- [Unit Tests](../tenant-config-project/unit-tests.tftest.hcl) - Platform team tests
- [Integration Tests](../bu-control-workspace/integration-tests.tftest.hcl) - BU team tests
