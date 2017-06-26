# ----------------------------------------
# Module for Travis Platform
# ----------------------------------------

terraform { required_version = "= 0.9.6" }


# ----- Variables

variable "ami_id"        { }
variable "count"         { }
variable "env"           { }
variable "instance_type" { }
variable "region"        { }
variable "role"          { default = "travis-platform" }
variable "sg_ids"        { type = "list" }
variable "ssh_key_name"  { }
variable "ssh_key_path"  { }
variable "ssl_key_path"  { }
variable "ssl_cert_path" { }
variable "sub_domain"    { }
variable "subnet_id"     { }

# Template Variables
variable "admin_password"       { }
variable "fqdn"                 { }
variable "github_client_id"     { }
variable "github_client_secret" { }
variable "librato_enabled"      { default = "false" }
variable "librato_email"        { default = "" }
variable "librato_token"        { default = "" }
variable "rabbitmq_password"    { }
variable "replicated_log_level" { default = "debug" }


# ----- Data Sources

data "template_file" "replicated" {
    template = "${file("${path.module}/templates/replicated.conf.tpl")}"

    vars {
        platform_admin_password = "${var.admin_password}"
        platform_fqdn           = "${var.fqdn}"
        replicated_log_level    = "${var.replicated_log_level}"
    }
}

data "template_file" "settings" {
    template = "${file("${path.module}/templates/settings.json.tpl")}"

    vars {
        github_client_id     = "${var.github_client_id}"
        github_client_secret = "${var.github_client_secret}"
        librato_enabled      = "${var.librato_enabled}"
        librato_email        = "${var.librato_email}"
        librato_token        = "${var.librato_token}"
        rabbitmq_password    = "${var.rabbitmq_password}"
    }
}


# ----- Resources

resource "aws_instance" "platform" {
    ami                         = "${var.ami_id}"
    associate_public_ip_address = true
    count                       = "${var.count}"
    ebs_optimized               = true
    instance_type               = "${var.instance_type}"
    key_name                    = "${var.ssh_key_name}"
    subnet_id                   = "${var.subnet_id}"
    vpc_security_group_ids      = [ "${var.sg_ids}" ]

    connection {
        user        = "ubuntu"
        private_key = "${file(var.ssh_key_path)}"
    }

    tags {
        Name        = "${format("%s%02d.%s", var.role, count.index + 1, var.env)}"
        Role        = "${var.role}"
        CostCenter  = "COGS"
        Department  = "Engineering"
        Environment = "${title(var.env)}"
        Service     = "CICD"
        Component   = "Build"
        Region      = "${var.region}"
    }

    volume_tags { Role = "${var.role}" }

    provisioner "file" {
        content = "${format("%s%d.%s.%s", var.role, count.index + 1, var.region, var.sub_domain)}"
        destination = "/tmp/hostname"
    }

    # Provision SSL Key/Cert Files
    provisioner "file" {
        source      = "${var.ssl_key_path}"
        destination = "/opt/pubnub/certs/${var.fqdn}.key"
    }

    provisioner "file" {
        source      = "${var.ssl_cert_path}"
        destination = "/opt/pubnub/certs/${var.fqdn}.crt"
    }

    # Provision Template Files
    provisioner "file" {
        content     = "${data.template_file.replicated.rendered}"
        destination = "/etc/replicated.conf"
    }

    provisioner "file" {
        content     = "${data.template_file.settings.rendered}"
        destination = "/opt/pubnub/travis-platform/settings.json"
    }

    # TODO: apt-get update && apt-get upgrade
    provisioner "remote-exec" {
        inline = [
            "sudo mv /tmp/hostname /etc/hostname",
            "/opt/pubnub/travis-platform/installer.sh",
            "sudo shutdown -r now"
        ]
    }
}


# ----- Outputs

output "private_ips" { value = [ "${aws_instance.platform.*.private_ip}" ] }
output "public_ips"  { value = [ "${aws_instance.platform.*.public_ip}" ] }
