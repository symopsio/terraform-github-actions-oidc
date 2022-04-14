aws_region = "us-east-1"
namespace  = "sym"

# Keep this off till you are ready to provision
bastion_enabled = false

# Supply a VPC where you can test the bastion
bastion_private_subnet_ids = ["subnet-CHANGEME"]
bastion_vpc_id             = "vpc-CHANGEME"

# We use these tags in our bootstrap policies to constrain IAM actions where we
# can
tags = { "vendor" = "symops.com" }
