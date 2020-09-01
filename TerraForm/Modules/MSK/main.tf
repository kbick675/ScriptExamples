provider "aws" {
  version = "~> 2.70.0"
  region  = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "vpc_id" {
  id = var.vpc_id
}

data "aws_acmpca_certificate_authority" "rootca" {
  arn = var.rootca_arn
}

data "aws_acmpca_certificate_authority" "issuingca" {
  arn = var.issuingca_arn
}

data "aws_cloudwatch_log_group" "msk_log_group" {
  name = "/aws/msk/logs"
}

data "aws_subnet" "ec2_subnet" {
  id = var.ec2_subnet_id
}

data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ec2_ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = [var.ec2_ami_filter.virtualization_type]
  }

  owners = [var.ec2_ami_filter.owners]
}

resource "aws_security_group" "msk_client_sg" {
  name        = "vca-msk-client-${var.cluster_settings.environment}-sg"
  description = "Allows TLS inbound traffic"
  vpc_id      = data.aws_vpc.vpc_id.id

  ingress {
    description = "port 8081"
    from_port   = "8081"
    to_port     = "8081"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "port 8083"
    from_port   = "8083"
    to_port     = "8083"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "port 9000"
    from_port   = "9000"
    to_port     = "9000"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "port 9102"
    from_port   = "9102"
    to_port     = "9102"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "port 9991"
    from_port   = "9991"
    to_port     = "9991"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "JMX port"
    from_port   = "9584"
    to_port     = "9584"
    protocol    = "tcp"
    cidr_blocks  = ["10.0.0.0/8"]
  }

  ingress {
    description = "ssh"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
    description = "ICMP"
    from_port   = "0"
    to_port     = "0"
    protocol    = "ICMP"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vca-msk-client-${var.cluster_settings.environment}-sg"
  }
}

resource "aws_instance" "msk_client" {
  count = var.ec2_instance_count

  ami           = data.aws_ami.amazonlinux.id
  instance_type = var.ec2_instance_size
  key_name      = var.ec2_keypair_name
  subnet_id     = data.aws_subnet.ec2_subnet.id

  security_groups             = [aws_security_group.msk_client_sg.id]
  associate_public_ip_address = true

  root_block_device {
    volume_type = var.ec2_ebs_vol_type
    volume_size = var.ec2_ebs_vol_size
  }
  tags = {
    Name = "vca-msk-client-${var.cluster_settings.environment}-${count.index + 1}"
  }
}

resource "aws_subnet" "vpc_subnets" {
  count = var.cluster_settings.private_subnet_count

  vpc_id            = data.aws_vpc.vpc_id.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.private_cidr_blocks[count.index]

  tags = {
    Name = "vca_msk_${data.aws_availability_zones.available.names[count.index]}_subnet"
  }
}

resource "aws_security_group" "msk_sg" {
  name        = "vca-msk-cluster-${var.cluster_settings.environment}-sg"
  description = "Allows TLS inbound traffic"
  vpc_id      = data.aws_vpc.vpc_id.id

  ingress {
    description = "TLS from VPC"
    from_port   = "9094"
    to_port     = "9094"
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc_id.cidr_block]
  }

  ingress {
    description = "Zookeeper Access"
    from_port   = "2181"
    to_port     = "2181"
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc_id.cidr_block]
  }

  ingress {
    description = "JMX and Node Ports"
    from_port   = "11001"
    to_port     = "11002"
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc_id.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vca-msk-cluster-${var.cluster_settings.environment}-sg"
  }
}

resource "aws_msk_cluster" "msk_cluster" {
  cluster_name           = var.cluster_settings.cluster_name
  kafka_version          = var.cluster_settings.cluster_version
  number_of_broker_nodes = var.cluster_settings.instances_per_subnet * var.cluster_settings.private_subnet_count

  broker_node_group_info {
    instance_type   = var.cluster_settings.instance_type
    ebs_volume_size = var.cluster_settings.ebs_vol_size
    client_subnets  = aws_subnet.vpc_subnets.*.id
    security_groups = [aws_security_group.msk_sg.id]
  }

  client_authentication {
    tls {
      certificate_authority_arns = [data.aws_acmpca_certificate_authority.rootca.arn, data.aws_acmpca_certificate_authority.issuingca.arn]
    }
  }
  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
    }
  }

  enhanced_monitoring = var.cluster_settings.monitoring_type

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = data.aws_cloudwatch_log_group.msk_log_group.name
      }
    }
  }
  tags = {
    env = var.cluster_settings.environment
  }
}
