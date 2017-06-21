# ----------------------------------------
# Module for Travis Platform
# ----------------------------------------

terraform { required_version = ">= 0.9.8" }


# ----- Variables

variable "ami_id"        { }
variable "count"         { }
variable "env"           { }
variable "instance_type" { }
variable "key_name"      { }
variable "key_path"      { }
variable "region"        { }
variable "role"          { default = "travis-platform" }
variable "sg_ids"        { type = "list" }
variable "subnet_id"     { }


# ----- Resources

resource "aws_instance" "platform" {
    ami                         = "${var.ami_id}"
    associate_public_ip_address = true
    count                       = "${var.count}"
    ebs_optimized               = true
    instance_type               = "${var.instance_type}"
    key_name                    = "${var.key_name}"
    subnet_id                   = "${var.subnet_id}"
    vpc_security_group_ids      = [ "${var.sg_ids}" ]

    connection {
        user        = "ubuntu"
        private_key = "${file(var.key_path)}"
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
}


# ----- Outputs

output "private_ips" { value = [ "${aws_instance.platform.*.private_ip}" ] }
output "public_ips"  { value = [ "${aws_instance.platform.*.public_ip}" ] }
