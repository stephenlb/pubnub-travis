# ----------------------------------------
# Module for Travis Enterprise
# ----------------------------------------

terraform { required_version = ">= 0.9.8" }


# ----- Variables

variable "env"       { }
variable "key_name"  { }
variable "key_path"  { }
variable "subnet_id" { }

variable "platform_count"         { }
variable "platform_instance_type" { }
variable "platform_sg_ids"        { }

# TODO: Worker varaibles


# ----- Data Sources

data "aws_region" "current" {
    current = true
}

data "aws_ami" "platform" {
    most_recent = true
    owners      = [ "self" ]

    filter {
        name   = "state"
        values = [ "available" ]
    }

    filter {
        name   = "tag:Role"
        values = [ "${var.role}" ]
    }

    # Only stable AMIs are allowed in production
    filter {
        name   = "tag:Stable"
        values = "${var.env == "production" ? list("true") : list("true", "false")}"
    }
}

# TODO: Worker AMI data source


# ----- Resources

resource "aws_security_group" "allow_travis_workers" {
    name        = "allow_travis_workers"
    description = "Allow Travis Workers"

    tags {
        Name = "allow_travis_workers"
    }
}

resource "aws_security_group_rule" "allow_travis_workers" {
    type              = "ingress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [ "${module.worker.private_ips}" ]
    security_group_id = "${aws_security_group.allow_travis_workers.id}"
}


# ----- Modules

module "platform" {
    source = "${path.module}/platform"

    ami_id        = "${data.aws_ami.platform.id}"
    count         = "${var.platform_count}"
    env           = "${var.env}"
    instance_type = "${var.platform_instance_type}"
    key_name      = "${var.key_name}"
    key_path      = "${var.key_path}"
    region        = "${data.aws_region.name}"
    sg_ids        = [ "${var.platform_sg_ids}" ]
    subnet_id     = "${var.subnet_id}"
}

# TODO: Worker module


# ----- Outputs

output "allow_travis_workers" { value = "${aws_security_group.allow_travis_workers.id}" }

output "platform_public_ips"  { value = [ "${module.platform.public_ips}" ] }
output "platform_private_ips" { value = [ "${moudle.platform.private_ips}" ] }

# TODO: Worker outputs
