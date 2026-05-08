resource "aws_instance" "k8s_server" {

  ami           = "ami-034a8236c75419857"

  instance_type = "t2.large"

  key_name      = "devops-key.pem.pem"

  security_groups = ["default"]

  tags = {
    Name = "k8s-monitoring-server"
  }
}
