module "iam" {
  source = "./modules/iam"

  providers = {
    aws = aws.admin
  }
}