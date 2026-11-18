
module "compute" {
  source = "./modules/compute"

  instance_type = "t3.micro"

  public_subnet_id  = aws_subnet.public.id
  private_subnet_id = aws_subnet.private.id

  web_security_group_id = aws_security_group.web.id
  app_security_group_id = aws_security_group.app.id

  instance_profile_name = module.iam.ec2_instance_profile_name
}
