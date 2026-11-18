
# Default provider - infrastructure management
provider "aws" {
  region  = "eu-north-1"
  profile = "terraform-lab"
}

# Administrator provider - IAM management
provider "aws" {
  alias   = "admin"
  region  = "eu-north-1"
  profile = "terraform-admin"
}
