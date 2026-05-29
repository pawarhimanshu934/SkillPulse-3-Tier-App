module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "skillpulse-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = true

#   AWS Kubernetes integrations need a way to automatically discover which subnets(Public/Private) to use when creating load balancers. These tags provide that signal.

# Marks subnet as public and k8 will use these subnet for internet facing load balancers (ELB)
# Example:
# When you create a Service of type LoadBalancer exposed to the internet, AWS will place the ELB in these subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

# Marks subnet as private and k8 will use these subnet for internal load balancers (ELB)
# Example:
# Services meant only for internal communication within the VPC, such as a database service, can be exposed using an internal load balancer. AWS will place the ELB in these subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

   map_public_ip_on_launch = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}



# Why this matters

# Without these tags:

# Kubernetes (via the AWS cloud provider or AWS Load Balancer Controller) cannot automatically discover subnets
# You would need to manually specify subnet IDs every time you create a LoadBalancer service, which is error-prone and less scalable
# With these tags:  
# Kubernetes can automatically discover which subnets to use for internet-facing and internal load balancers, simplifying the deployment of services and improving scalability.