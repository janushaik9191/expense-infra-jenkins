resource "aws_key_pair" "eks" {
  key_name   = "eks"
  # you can paste the public key directly or refer like this
  
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC650Rs7YAb4RjJeFAXC9vvDpw/Sx9db1JZlgrKuVMCt4BXqQ/hGb1++Jnfv6Tmd8qRFnVrcKqAXvemkcC1l8rFpJzpOZIdpkrFy8rrSIQIlgBVf7yx/JXDKQ8qkoPIciU/nNBzFQ+mRFXoPVY4B2ocah+73l66RSPi1e6uLdKBz8SrWGr1E94bfV8dClLQPFvcOGA10AogJG80iByN1xGQT1qLe5rNN1OvgjI0GjAHXKRgxAI3i9smHOyLLqSIgKWRBoGVlY32vVLNc5X/U7piXYHIUdeNay0Z+A7BnSj/ZH1naLWPbt9yayrzaCQMXvMY0KXpkRfYGBJ+k3ajBOFVJwfS3sJvxPEtijnubfbUyylv7ceN0f51KTNXEj5NuXpQ+PCG5u3mcMjdOAMG0BOFxDOVs+IwUh7Ot3pcr8s/IycRL04ieycnWkyY/l7gIjroM42IprNqystk+NzdUiQQVjMjMxPFfcpXnAOMkDl8zJ4ZdDMJ1n3hJOwiVsP7wQmbHbq1y8G/ou8YTaPhVRcjoE/2sXBXS5OwxdU9l5K3bDy2CMjiGRH9moHQij7f+FRrFiGPFNBvEKRdqrY1FuUAdQkV+tXwsPgf+/znR9Aoq5GZ/QNeQGrPXY83oOUbQEdAv3nknm45vby5KaaTaFXAGYq29BoriYzVnwGhcCuoCw== KONDA BABU@DESKTOP-5LLIV0L"

  # public_key =file("~/.ssh/eks.pub")
  # ~ means windows home directory
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"


  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = "1.31"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  create_cluster_security_group = false
  cluster_security_group_id     = local.eks_control_plane_sg_id

  create_node_security_group = false
  node_security_group_id     = local.node_sg_id

  # the user which you used to create cluster will get admin access

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    # blue = {
    #   min_size      = 3
    #   max_size      = 10
    #   desired_size  = 3
    #   capacity_type = "SPOT"
    #   iam_role_additional_policies = {
    #     AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #     AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
    #     ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    #   }
    #   # EKS takes AWS Linux 2 as it's OS to the nodes
    #   key_name = aws_key_pair.eks.key_name
    # }
    green = {
      min_size      = 3
      max_size      = 10
      desired_size  = 3
      capacity_type = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      key_name = aws_key_pair.eks.key_name
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = var.common_tags
}