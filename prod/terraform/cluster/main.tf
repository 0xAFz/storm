resource "openstack_compute_keypair_v2" "keypair" {
  name       = var.keypair_name
  public_key = file(var.pubkey_path)
}

resource "openstack_compute_instance_v2" "instance" {
  name        = "${var.instance_name}${count.index}"
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = openstack_compute_keypair_v2.keypair.name

  security_groups = var.security_groups

  network {
    name = var.network_name
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
              echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
              sysctl -p
              EOF

  count = var.instance_count
}
