packer {
  required_plugins {
    arm-image = {
      version = ">= 0.2.7"

      # NOTE: The source specified here omits the "packer-plugin-" prefix.
      # https://github.com/solo-io/packer-plugin-arm-image
      source = "github.com/solo-io/arm-image"
    }
  }
}

data "http" "github-keys" {
  url = "https://github.com/t-richards.keys"
}

# "Raspberry Pi OS Lite" 64-bit.
# https://www.raspberrypi.com/software/operating-systems/#raspberry-pi-os-64-bit
# https://downloads.raspberrypi.com/raspios_lite_arm64/images/
source "arm-image" "raspios" {
  iso_url          = "https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz"
  iso_checksum     = "sha256:58a3ec57402c86332e67789a6b8f149aeeb4e7bb0a16c9388a66ea6e07012e45"
  output_filename  = "tailscale-raspios.img"
  qemu_binary      = "/usr/bin/qemu-aarch64-static"
  disable_embedded = true
}

build {
  name = "tailscale-raspios"

  sources = [
    "source.arm-image.raspios"
  ]

  # update packages.
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
    ]
  }

  # install tailscale.
  # https://tailscale.com/kb/1174/install-debian-bookworm
  provisioner "shell" {
    inline = [
      "apt-get install -y apt-transport-https",
      "curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null",
      "curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list",
      "apt-get update",
      "apt-get install -y tailscale",
    ]
  }

  # TODO(tom): Install prometheus-node-exporter?
  # https://packages.debian.org/bookworm/prometheus-node-exporter

  # enable automatic upgrades.
  # https://wiki.debian.org/UnattendedUpgrades
  provisioner "shell" {
    inline = [
      "apt-get install -y unattended-upgrades",
      "echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections",
      "sudo dpkg-reconfigure -f noninteractive unattended-upgrades",
    ]
  }

  # enable ip forwarding for tailscale subnet routing.
  # https://tailscale.com/kb/1019/subnets#enable-ip-forwarding
  provisioner "shell" {
    inline = [
      "echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf",
      "echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf",
      "sudo sysctl -p /etc/sysctl.d/99-tailscale.conf",
    ]
  }

  # disable raspberry pi os configuration screen.
  # https://forums.raspberrypi.com/viewtopic.php?t=339340
  provisioner "shell" {
    inline = [
      "systemctl disable userconfig",
      "systemctl enable getty@tty1",
    ]
  }

  # enable ssh.
  provisioner "shell" {
    inline = [
      "mkdir /home/pi/.ssh",
      "touch /boot/ssh"
    ]
  }

  # add public keys.
  provisioner "file" {
    content     = data.http.github-keys.body
    destination = "/home/pi/.ssh/authorized_keys"
  }

  # set permissions for the authorized keys;
  # disable password authentication.
  provisioner "shell" {
    inline = [
      "chown pi:pi /home/pi/.ssh/authorized_keys",
      "sed '/PasswordAuthentication/d' -i /etc/ssh/sshd_config",
      "echo >> /etc/ssh/sshd_config",
      "echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config",
    ]
  }
}
