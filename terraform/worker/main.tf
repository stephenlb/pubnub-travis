# ----------------------------------------
# Module for Travis Worker
# ----------------------------------------

terraform { required_version = ">= 0.9.8" }


# ----- Variables

variable "ami_id"            { }
variable "count"             { }
variable "env"               { }
variable "instance_type"     { }
variable "platform_fqdn"     { }
variable "rabbitmq_password" { }
variable "region"            { }
variable "role"              { default = "travis-worker" }
variable "sg_ids"            { type = "list" }
variable "ssh_key_name"      { }
variable "ssh_key_path"      { }
variable "subnet_id"         { }


# ----- Data Sources

data "template_file" "travis-enterprise" {
    template = "${file("${path.module}/templates/travis-enterprise.tpl")}"

    vars {
        platform_fqdn     = "${var.platform_fqdn}"
        rabbitmq_password = "${var.rabbitmq_password}"
    }
}


# ----- Resources

resource "aws_instance" "worker" {
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

    # Provision Template Files
    provisioner "file" {
        content     = "${data.template_file.travis-enterprise.rendered}"
        destination = "/etc/default/travis-enterprise"
    }

    # Restart the Worker Service
    # TODO: apt-get update && apt-get upgrade
    provisioner "remote-exec" {
        inline = [ "sudo restart travis-worker" ]
    }
}


# ----- Outputs

output "private_ips" { value = [ "${aws_instance.worker.*.private_ip}" ] }
output "public_ips"  { value = [ "${aws_instance.worker.*.public_ip}" ] }
