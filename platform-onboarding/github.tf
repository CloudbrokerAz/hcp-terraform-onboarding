# ============================================================================
# GitHub Repositories for BU Stacks
# ============================================================================

resource "github_repository" "bu_stack" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  name        = "${var.bu_stack_repo_prefix}-${each.key}-${var.bu_stack_repo_suffix}"
  description = "${title(each.key)} Business Unit Stack for workspace management in HCP Terraform"
  
  visibility = "private"
  
  # Use template repository if specified
  dynamic "template" {
    for_each = var.bu_stack_template_repo != "" ? [1] : []
    content {
      owner                = split("/", var.bu_stack_template_repo)[0]
      repository           = split("/", var.bu_stack_template_repo)[1]
      include_all_branches = false
    }
  }
  
  has_issues    = true
  has_wiki      = false
  has_projects  = false
  has_downloads = false
  
  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = false
  delete_branch_on_merge = true
  
  auto_init = var.bu_stack_template_repo == "" ? true : false
  
  vulnerability_alerts = true
}

# ============================================================================
# GitHub Teams for BU Admins
# ============================================================================

resource "github_team" "bu_admin" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  name        = "${each.key}-admins"
  description = "${title(each.key)} BU administrators with access to Stack repository"
  privacy     = var.github_team_privacy
}

# ============================================================================
# Grant BU Admin Team Access to Repository
# ============================================================================

resource "github_team_repository" "bu_admin_access" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  team_id    = github_team.bu_admin[each.key].id
  repository = github_repository.bu_stack[each.key].name
  permission = "admin"
}

# ============================================================================
# Branch Protection (Main Branch)
# ============================================================================

resource "github_branch_protection" "bu_stack_main" {
  for_each = var.create_bu_repositories && var.enable_branch_protection ? local.tenant : {}

  repository_id = github_repository.bu_stack[each.key].node_id
  pattern       = "main"
  
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
  }
  
  required_status_checks {
    strict   = true
    contexts = ["terraform-stacks-validate"]
  }
  
  enforce_admins          = false
  require_signed_commits  = false
  required_linear_history = true
}

# ============================================================================
# Seed Initial Stack Configuration Files
# ============================================================================

# README.md
resource "github_repository_file" "readme" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "README.md"
  content             = templatefile("${path.module}/templates/bu-stack-readme.md.tpl", {
    bu_name           = each.key
    bu_display_name   = title(each.key)
    organization      = var.tfc_organization_name
    platform_project  = var.platform_stack_project
    github_org        = var.github_organization
    repo_name         = github_repository.bu_stack[each.key].name
  })
  commit_message      = "Initialize ${each.key} BU Stack"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# variables.tfcomponent.hcl
resource "github_repository_file" "variables" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "variables.tfcomponent.hcl"
  content             = templatefile("${path.module}/templates/variables.tfcomponent.hcl.tpl", {
    bu_name = each.key
  })
  commit_message      = "Add Stack variables configuration"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# providers.tfcomponent.hcl
resource "github_repository_file" "providers" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "providers.tfcomponent.hcl"
  content             = templatefile("${path.module}/templates/providers.tfcomponent.hcl.tpl", {
    bu_name       = each.key
    oidc_audience = "${each.key}-team-*"
  })
  commit_message      = "Add Stack providers configuration"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# components.tfcomponent.hcl
resource "github_repository_file" "components" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "components.tfcomponent.hcl"
  content             = templatefile("${path.module}/templates/components.tfcomponent.hcl.tpl", {
    bu_name      = each.key
    organization = var.tfc_organization_name
  })
  commit_message      = "Add Stack components configuration"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# outputs.tfcomponent.hcl
resource "github_repository_file" "outputs" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "outputs.tfcomponent.hcl"
  content             = file("${path.module}/templates/outputs.tfcomponent.hcl")
  commit_message      = "Add Stack outputs configuration"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# deployments.tfdeploy.hcl
resource "github_repository_file" "deployments" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "deployments.tfdeploy.hcl"
  content             = templatefile("${path.module}/templates/deployments.tfdeploy.hcl.tpl", {
    bu_name          = each.key
    organization     = var.tfc_organization_name
    platform_project = var.platform_stack_project
    oidc_audience    = "${each.key}-team-*"
  })
  commit_message      = "Add Stack deployments configuration"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# Example YAML configuration
resource "github_repository_file" "yaml_config" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = "configs/${each.key}.yaml"
  content             = templatefile("${path.module}/templates/bu-config.yaml.tpl", {
    bu_name = each.key
  })
  commit_message      = "Add example workspace configuration"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}

# GitHub Actions workflow
resource "github_repository_file" "github_actions" {
  for_each = var.create_bu_repositories ? local.tenant : {}

  repository          = github_repository.bu_stack[each.key].name
  branch              = "main"
  file                = ".github/workflows/terraform-stacks.yml"
  content             = templatefile("${path.module}/templates/github-actions.yml.tpl", {
    bu_name = each.key
  })
  commit_message      = "Add CI/CD workflow"
  commit_author       = var.commit_author_name
  commit_email        = var.commit_author_email
  overwrite_on_create = true
}
