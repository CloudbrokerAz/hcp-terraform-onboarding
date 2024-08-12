resource "github_repository" "example" {
  name        = "example"
  description = "My awesome codebase"

  visibility = "public"

  template {
    owner                = "hashi-demo-lab"
    repository           = "tf-template"
    include_all_branches = true
  }
}