# Ubuntu Server jammy
# ---
# Packer Template to create an Ubuntu Server (jammy) on Proxmox

# Variable Definitions
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}



packer {
  required_plugins {
    name = {
      version = "1.1.7"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-server-jammy" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.proxmox_api_url}"
    username = "${var.proxmox_api_token_id}"
    token = "${var.proxmox_api_token_secret}"
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = true
    
    # VM Gene
    node = "pve"
    vm_id = "700"
    vm_name = "ubuntu-server-jammy"
    template_description = "Ubuntu Server jammy Testing Image"

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
    # - or -
    # (Option 2) Download ISO
    #iso_url = "https://releases.ubuntu.com/jammy/ubuntu-22.04.4-live-server-amd64.iso"
    #iso_checksum = "sha256:45f873de9f8cb637345d6e66a583762730bbea30277ef7b32c9c3bd6700a32b2"
    iso_storage_pool = "local"
    unmount_iso = true
    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "20G"
        format = "raw"
        storage_pool = "local-lvm"
        storage_pool_type = "lvm"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "2"
    
    # VM Memory Settings
    memory = "2048" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr1"
        firewall = "false"
        vlan_tag = "150"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"
    


    # PACKER Boot Commands
    boot_command = [
        "c<wait>linux /casper/vmlinuz --- autoinstall ip=172.23.21.218::172.23.21.1:255.255.255.0::::172.23.25.50 ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'<enter><wait5s>initrd /casper/initrd <enter><wait5s>boot <enter><wait5s>"
    ]
    #boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "0.0.0.0"
    http_port_min = 8802
    http_port_max = 8802

    ssh_username = "avish"
    #ssh_handshake_attempts = "50"
    #ssh_port = "2525"
    #ssh_host = "172.23.21.218"
    #ssh_pty = true
    

    # (Option 1) Add your Password here
    ssh_password = "avish@123"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    #ssh_private_key_file = "~/.ssh/id_rsa"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "50m"
    #autoinstall = true
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-server-jammy"
    sources = ["proxmox-iso.ubuntu-server-jammy"]

provisioner "shell" {
    inline = [ "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done" ]
}

provisioner "file" {
        source = "files/700-pve.cfg"
        destination = "/tmp/700-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/700-pve.cfg /etc/cloud/cloud.cfg.d/700-pve.cfg" ]
    }

}