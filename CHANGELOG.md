# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README with architecture overview and usage examples
- Pre-commit configuration for code quality automation
- Trivy security scanning configuration
- Enhanced .gitignore covering IDE files, OS files, and tool caches

## [1.0.0] - 2025-11-13

### Added

#### Platform Team Layer (tenant-config-project)
- Business unit admin team creation and management
- BU control project provisioning with RBAC
- Team token generation and distribution via variable sets
- Custom project access controls (read, write, admin, custom)
- Project-level variable set creation and management
- Support for SSO team integration
- Automated project-to-team access assignments

#### Business Unit Layer (bu-control-workspace)
- YAML-driven workspace configuration and provisioning
- GitHub repository creation from templates
- Automated VCS-to-workspace connections
- Workspace variable management (Terraform and environment variables)
- Variable set-to-workspace associations
- Team-based workspace access control (read, plan, write)
- Remote state sharing configuration
- Agent pool support for self-hosted runners
- Assessment mode for drift detection
- File-triggered runs with configurable working directory

#### Features
- Multi-tenant platform team pattern implementation
- Declarative infrastructure-as-code for onboarding workflows
- Separation of concerns between platform and BU teams
- Scalable architecture supporting multiple business units
- YAML configuration validation and error handling
- Support for both public and private GitHub repositories
- Branch protection and template repository integration
- Flexible RBAC with email-based team assignments

### Configuration
- YAML configuration format for business units
- YAML configuration format for workspaces
- Support for workspace tags and metadata
- Configurable Terraform versions per workspace
- VCS branch and directory path configuration
- Auto-apply and queue behavior configuration

### Documentation
- Initial repository structure
- Example YAML configurations
- Basic README with project overview

## [0.1.0] - Initial Development

### Added
- Initial project structure
- Basic Terraform configuration
- Proof of concept implementation

---

## Release Notes

### [1.0.0] - Production Ready Release

This is the first production-ready release of the HCP Terraform Platform Team Onboarding Module. It provides a complete, enterprise-grade solution for implementing multi-tenant platform team patterns in HCP Terraform.

**Key Capabilities:**
- ✅ **Platform Team Delegation** - Platform teams create BU infrastructure, BU teams self-service workspaces
- ✅ **YAML-Driven IaC** - Declarative workspace provisioning via version-controlled configuration
- ✅ **GitHub Integration** - Automated repository creation and VCS connections
- ✅ **Enterprise RBAC** - Fine-grained access control at organization, project, and workspace levels
- ✅ **Variable Management** - Centralized and workspace-specific variable handling
- ✅ **State Isolation** - Secure state management with optional remote state sharing

**Migration Guide:**
- If upgrading from pre-1.0 versions, review YAML configuration structure
- Ensure OAuth token is configured for GitHub VCS integration
- Update variable references to match new output names
- Review team access email lists for accuracy

**Breaking Changes:**
- YAML configuration format changes may require updates to existing configs
- Module outputs renamed for consistency
- Variable validation added (may reject previously accepted invalid values)

**Upgrade Path:**
1. Backup existing Terraform state
2. Review CHANGELOG for breaking changes
3. Update YAML configurations to match new format
4. Run `terraform plan` to validate changes
5. Apply changes in non-production environment first
6. Validate workspace creation and access controls
7. Roll out to production

[Unreleased]: https://github.com/your-org/hcp-terraform-onboarding/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/your-org/hcp-terraform-onboarding/releases/tag/v1.0.0
[0.1.0]: https://github.com/your-org/hcp-terraform-onboarding/releases/tag/v0.1.0
