resource "digitalocean_project" "terraform" {
  name        = "terraform"
  environment = "Development"
  resources   = digitalocean_droplet.server[*].urn
}

data "digitalocean_ssh_key" "terraformkey" {
  name = "terraformkey"
}

# data "digitalocean_droplet" "server" {
#   name = "server"
# }

output "droplet_ids" {
  value = digitalocean_droplet.server[*].id
}


resource "digitalocean_droplet" "server" {
    count = 3
    name    = "server-droplet-${count.index+1}"
    image   = "ubuntu-20-04-x64"
    size    = "s-2vcpu-2gb"
    region  = "nyc1"
    ssh_keys = [
      data.digitalocean_ssh_key.terraformkey.id
    ]

    tags = ["server-droplet-${count.index+1}"]

}

    # connection {
    #   type        = "ssh"
    #   user        = "root"
    #   private_key = file("/ssh_key/${var.ssh_key}")
    #   host        = self.ipv4_address
    # }

  resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = "nyc1"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = digitalocean_droplet.server[*].id
}

resource "digitalocean_firewall" "server" {
  name = "only-22-80-and-443"

  droplet_ids = digitalocean_droplet.server.*.id

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["192.168.1.0/24", "2002:1:2::/48"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

}
