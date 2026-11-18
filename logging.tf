
module "logging" {
  source = "./modules/logging"

  web_instance_id = module.compute.web_instance_id
  app_instance_id = module.compute.app_instance_id
}
