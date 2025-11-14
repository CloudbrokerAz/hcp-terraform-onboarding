name: Terraform Stacks - Validate & Plan

on:
  pull_request:
    branches: [main]
    paths:
      - '**.hcl'
      - 'configs/**'
  push:
    branches: [main]
    paths:
      - '**.hcl'
      - 'configs/**'
  workflow_dispatch:

env:
  TF_VERSION: '1.13.5'

jobs:
  validate:
    name: Validate Stack Configuration
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: $${{ env.TF_VERSION }}
      
      - name: Validate Stack syntax
        run: terraform stacks validate
      
      - name: Check HCL formatting
        run: |
          terraform fmt -check -recursive
          if [ $$? -ne 0 ]; then
            echo "::error::HCL files are not formatted. Run 'terraform fmt -recursive' locally."
            exit 1
          fi
      
      - name: Validate YAML configuration
        run: |
          for file in configs/*.yaml; do
            echo "Validating $$file"
            python3 -c "import yaml; yaml.safe_load(open('$$file'))"
          done
  
  plan:
    name: Plan Stack Deployments
    runs-on: ubuntu-latest
    needs: validate
    if: github.event_name == 'pull_request'
    
    strategy:
      matrix:
        deployment: [dev, staging, production]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: $${{ env.TF_VERSION }}
      
      - name: Configure HCP Terraform credentials
        run: |
          cat > ~/.terraformrc <<EOF
          credentials "app.terraform.io" {
            token = "$${{ secrets.TFC_TOKEN }}"
          }
          EOF
      
      - name: Generate provider lock file
        run: terraform stacks providers-lock
      
      - name: Plan $${{ matrix.deployment }} deployment
        run: terraform stacks plan --deployment=$${{ matrix.deployment }}
        env:
          TFE_TOKEN: $${{ secrets.TFC_TOKEN }}
      
      - name: Comment PR with plan summary
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const deployment = '$${{ matrix.deployment }}';
            const body = `### Terraform Stack Plan: \`$${deployment}\`
            
            ✅ Stack validation passed
            📋 Plan generated successfully
            
            **Review the plan in HCP Terraform:**
            https://app.terraform.io/app/cloudbrokeraz
            
            **Deployment:** \`$${deployment}\`
            **Stack:** \`${bu_name}-bu-stack\`
            `;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: body
            });
  
  notify:
    name: Notify on Stack Changes
    runs-on: ubuntu-latest
    needs: [validate, plan]
    if: always()
    
    steps:
      - name: Send notification
        run: |
          echo "Stack validation and planning completed"
          echo "Status: $${{ job.status }}"
          # Add Slack/Teams notification here if needed
