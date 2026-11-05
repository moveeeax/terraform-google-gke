# NOTE: the test suite under tests/ uses mock_provider, which needs Terraform
# >= 1.7. required_version stays at >= 1.5 so consumers are not forced to
# upgrade just to use the module.
terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 9.0"
    }
  }
}
