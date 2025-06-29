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
  iso_url          = "https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2025-05-13/2025-05-13-raspios-bookworm-arm64-lite.img.xz"
  iso_checksum     = "sha256:62d025b9bc7ca0e1facfec74ae56ac13978b6745c58177f081d39fbb8041ed45"
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

  # install adguard home.
  # https://github.com/AdguardTeam/AdGuardHome?tab=readme-ov-file#automated-install-linuxunixmacosfreebsdopenbsd
  provisioner "shell" {
    inline = [
      "curl -s -S -L https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh -s -- -v"
    ]
  }

  # enable automatic upgrades.
  # https://wiki.debian.org/UnattendedUpgrades
  provisioner "shell" {
    inline = [
      "apt-get install -y unattended-upgrades",
      "echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections",
      "sudo dpkg-reconfigure -f noninteractive unattended-upgrades",
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
