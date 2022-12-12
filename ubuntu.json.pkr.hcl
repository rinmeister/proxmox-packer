variable "proxmox_template_name" {
  type    = string
  default = "ubuntu-20.04-3"
}

variable "proxmox_vm_id" {
  type    = string
  default = "304"
}

variable "proxmox_username" {
  type    = string
  default = "terraform-prov@pve"
}

variable "proxmox_password" {
  type    = string
  default = "BattleOfHastings!@"
}

variable "ubuntu_iso_file" {
  type    = string
  default = "ubuntu-20.04.4-live-server-amd64.iso"
}

variable "proxmox_url" {
  type    = string
  default = "https://10.1.0.129:8006/api2/json"
}
variable "ssh_user" {
  type    = string
  default = "rene"
} 
variable "ssh_pass" {
  type    = string
  default = "opgero8t"
} 

source "proxmox" "ubuntu-server-ci" {
  boot_command = ["<esc><wait><esc><wait><f6><wait><esc><wait>", "<bs><bs><bs><bs><bs>", "autoinstall ds=nocloud-net;s=http://10.1.0.129:8000/ ", "--- <enter>"]
  boot_wait    = "6s"
  disks {
    disk_size         = "20G"
    storage_pool      = "local-lvm"
    storage_pool_type = "lvm"
    type              = "scsi"
  }
  http_directory           = "http"
  insecure_skip_tls_verify = true
  iso_file                 = "local:iso/${var.ubuntu_iso_file}"
  memory                   = 1024
  network_adapters {
    bridge   = "vmbr1"
    firewall = true
    model    = "virtio"
    vlan_tag = "220"
  }
  node          = "voldemort"
  password      = "${var.proxmox_password}"
  proxmox_url   = "${var.proxmox_url}"
  ssh_password  = "${var.ssh_pass}"
  ssh_timeout   = "40m"
  ssh_username  = "${var.ssh_user}"
  template_name = "${var.proxmox_template_name}"
  unmount_iso   = true
  username      = "${var.proxmox_username}"
  vm_id         = "${var.proxmox_vm_id}"
# VM System Settings
  qemu_agent = true

# VM Cloud-Init Settings
  cloud_init = true
  cloud_init_storage_pool = "local-lvm"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-server-ci"
    sources = ["source.proxmox.ubuntu-server-ci"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo rm /var/lib/dbus/machine-id",
            "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }
}
