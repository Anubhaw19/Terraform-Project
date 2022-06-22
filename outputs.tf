output "EC2-server-public-IP" {
  value=module.my-server.instance.public_ip
}