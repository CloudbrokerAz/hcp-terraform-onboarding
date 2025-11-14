business_unit: ${bu_name}

projects:
  - name: example-application
    description: Example application project
    
    # Project-level variable set (optional)
    var_sets:
      variables:
        - key: environment
          value: development
          category: terraform
          description: Environment identifier
        
        - key: region
          value: us-east-1
          category: terraform
          description: AWS region
    
    workspaces:
      # Frontend workspace
      - name: ${bu_name}-example-frontend
        description: Frontend infrastructure for example application
        terraform_version: "1.9.0"
        working_directory: "terraform/frontend"
        execution_mode: remote
        auto_apply: false
        
        # Trigger configuration
        trigger_prefixes:
          - "terraform/frontend/"
        
        # VCS integration
        vcs_repo:
          identifier: "CloudbrokerAz/example-frontend"
          branch: "main"
        
        # Workspace-specific variables
        variables:
          - key: app_name
            value: example-frontend
            category: terraform
          
          - key: instance_count
            value: "3"
            category: terraform
      
      # Backend workspace
      - name: ${bu_name}-example-backend
        description: Backend API infrastructure
        terraform_version: "1.9.0"
        working_directory: "terraform/backend"
        execution_mode: remote
        auto_apply: false
        
        trigger_prefixes:
          - "terraform/backend/"
        
        vcs_repo:
          identifier: "CloudbrokerAz/example-backend"
          branch: "main"
        
        variables:
          - key: app_name
            value: example-backend
            category: terraform
          
          - key: database_enabled
            value: "true"
            category: terraform
      
      # Database workspace
      - name: ${bu_name}-example-database
        description: Database infrastructure (RDS, Aurora, etc.)
        terraform_version: "1.9.0"
        working_directory: "terraform/database"
        execution_mode: remote
        auto_apply: false
        
        trigger_prefixes:
          - "terraform/database/"
        
        vcs_repo:
          identifier: "CloudbrokerAz/example-backend"
          branch: "main"
        
        variables:
          - key: db_engine
            value: postgres
            category: terraform
          
          - key: db_version
            value: "15.3"
            category: terraform
          
          - key: db_instance_class
            value: db.t3.medium
            category: terraform

# ============================================================================
# YAML Configuration Guide
# ============================================================================
#
# business_unit: (string, required)
#   - Must match BU name in platform stack
#   - Used for filtering and scoping
#
# projects: (list, required)
#   - name: (string, required) Project name (will be prefixed with BU_{bu}__)
#   - description: (string, optional) Project description
#   - var_sets: (object, optional) Project-level variable set
#     - variables: (list) Variables to create in project variable set
#       - key: Variable name
#       - value: Variable value
#       - category: "terraform" or "env"
#       - description: (optional) Variable description
#       - sensitive: (optional, bool) Mark as sensitive
#   
#   - workspaces: (list, required) Workspaces within project
#     - name: (string, required) Workspace name
#     - description: (string, optional) Workspace description
#     - terraform_version: (string, required) Terraform version
#     - working_directory: (string, optional) Working directory in VCS
#     - execution_mode: (string, optional) "remote" or "local", default: "remote"
#     - auto_apply: (bool, optional) Auto-apply on successful plan, default: false
#     - trigger_prefixes: (list, optional) File paths that trigger runs
#     - vcs_repo: (object, optional) VCS repository configuration
#       - identifier: "org/repo" GitHub repository
#       - branch: Branch name, default: "main"
#     - variables: (list, optional) Workspace-specific variables
#       - key: Variable name
#       - value: Variable value
#       - category: "terraform" or "env"
#       - description: (optional)
#       - sensitive: (optional, bool)
#
# ============================================================================
