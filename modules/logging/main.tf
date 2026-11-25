
terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "web_cpu" {
  alarm_name          = "terraform-lab-web-high-cpu"
  alarm_description   = "WEB EC2 CPU utilization exceeds 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = var.web_instance_id
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "app_cpu" {
  alarm_name          = "terraform-lab-app-high-cpu"
  alarm_description   = "APP EC2 CPU utilization exceeds 80%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    InstanceId = var.app_instance_id
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "web_status_check" {
  alarm_name          = "terraform-lab-web-status-check"
  alarm_description   = "WEB EC2 instance status check failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1

  dimensions = {
    InstanceId = var.web_instance_id
  }

  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "app_status_check" {
  alarm_name          = "terraform-lab-app-status-check"
  alarm_description   = "APP EC2 instance status check failed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1

  dimensions = {
    InstanceId = var.app_instance_id
  }

  treat_missing_data = "notBreaching"
}
