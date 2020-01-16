/**
* # aws-terraform-iam_resources/modules/ssm_service_roles
*
*This submodule creates an IAM Role for the SSM Services
*
*## Basic Usage
*
*```
*module "ssm_service_roles" {
*  source = "git@github.com:rackspace-infrastructure-automation/aws-terraform-iam_resources//modules/ssm_service_roles?ref=v0.0.1"
*
*  # Optional parameters
*  #
*  # create_automation_role         = true
*  # create_maintenance_window_role = true
*}
*```
*
* Full working references are available at [examples](examples)
*/

terraform {
  required_version = ">= 0.12"
}

module "maintenance_window_role" {
  source = "../role"

  name        = "MaintenanceWindowServiceRole"
  build_state = var.create_maintenance_window_role
  aws_service = ["ec2.amazonaws.com", "ssm.amazonaws.com", "sns.amazonaws.com"]

  policy_arns       = ["arn:aws:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"]
  policy_arns_count = 1
}

# Since this policy references the IAM role itself, it must be created and attached after the role is created.
data "aws_iam_policy_document" "maintenance_window_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [module.maintenance_window_role.arn]
  }
}

resource "aws_iam_role_policy" "maintenance_window_policy" {
  count = var.create_maintenance_window_role ? 1 : 0

  name   = "MaintenanceWindowServiceRoleInlinePolicy"
  role   = module.maintenance_window_role.id
  policy = data.aws_iam_policy_document.maintenance_window_policy.json
}

module "automation_role" {
  source = "../role"

  name        = "AutomationServiceRole"
  build_state = var.create_automation_role
  aws_service = ["ec2.amazonaws.com", "ssm.amazonaws.com"]

  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
  ]

  policy_arns_count = 2
}

# Since this policy references the IAM role itself, it must be created and attached after the role is created.
data "aws_iam_policy_document" "automation_policy" {
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [module.automation_role.arn]
  }
}

resource "aws_iam_role_policy" "automation_policy" {
  count = var.create_automation_role ? 1 : 0

  name = "AutomationServiceRoleInlinePolicy"
  role = module.automation_role.id

  policy = data.aws_iam_policy_document.automation_policy.json
}

