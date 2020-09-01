output "zookeeper_connect_string" {
  value = aws_msk_cluster.msk_cluster.zookeeper_connect_string
}

output "bootstrap_brokers_tls" {
  description = "TLS connection host:port pairs"
  value       = aws_msk_cluster.msk_cluster.bootstrap_brokers_tls
}

output "client_instance_private_ip" {
  description = "private IP of ec2 instance"
  value       = aws_instance.msk_client.*.private_ip
}