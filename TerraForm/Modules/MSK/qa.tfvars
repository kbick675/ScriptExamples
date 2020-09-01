ec2_ebs_vol_size    = 30
private_cidr_blocks = ["10.245.10.64/27", "10.245.10.96/27"]
cluster_settings = {
  private_subnet_count = 2
  public_subnet_count  = 2
  instances_per_subnet = 1
  instance_type        = "kafka.t3.small"
  environment          = "qa"
  cluster_name         = "pcm-kafka-cluster-qa"
  cluster_version      = "2.4.1"
  ebs_vol_size         = 30
  monitoring_type      = "PER_TOPIC_PER_BROKER"
}