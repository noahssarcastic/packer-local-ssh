packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# Using al1 for demonstration purposes.
source "amazon-ebs" "al1" {
  ami_name      = "packer-ssh-test"
  instance_type = "t2.micro"
  region        = "us-east-2"
  source_ami_filter {
    filters = {
      name                = "amzn-ami-hvm-*-x86_64-gp2"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"
}

build {
  name = "packer-ssh"
  sources = [
    "source.amazon-ebs.al1"
  ]

  # Control test.
  provisioner "shell" {
    inline = [
      "touch test.txt",
    ]
  }

  # The ansible provisioner uses the in-memory ssh key by out of the box.
  # If using ansible roles, a playbook can be created which runs the roles, 
  # or the ansible cli can be used in a similar fashion to below with inspec.
  provisioner "ansible" {
    playbook_file = "playbook.yml"
  }

  # Build variables contain connection information and instance state for a builder.
  # https://www.packer.io/docs/templates/hcl_templates/contextual-variables#build-variables
  provisioner "shell-local" {
    inline = [
      "echo '${build.SSHPrivateKey}' > ./packer-session.pem",
      "inspec exec ./profile --target ssh://${build.User}@${build.Host} --key-files ./packer-session.pem",
    ]
  }
}
