variable "do_token" {}
variable "private_ssh_key_path" {}

provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "web" {
  name = "dog-list-key"
}

resource "digitalocean_droplet" "web" {
  image  = "ubuntu-18-04-x64"
  name   = "web-1"
  region = "nyc1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [data.digitalocean_ssh_key.web.id]

  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file("${var.private_ssh_key_path}")
  }

  # install clojure/java/dependencies
  provisioner "remote-exec" {
    script = "./provision.sh"
  }

  # systemd service definition
  provisioner "file" {
    source      = "./dog-bot.service"
    destination = "/lib/systemd/system/dog-bot.service"
  }

  # make folder and upload code
  provisioner "remote-exec" {
    inline = ["mkdir /opt/dog-bot"]
  }

  provisioner "file" {
    source      = "../"
    destination = "/opt/dog-bot"
  }

  # launch new systemd service
  provisioner "remote-exec" {
    inline = ["systemctl daemon-reload", "systemctl start dog-bot"]
  }
}
