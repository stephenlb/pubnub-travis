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
variable "platform_sg_ids"        { type = "list" }

variable "worker_count"         { }
variable "worker_instance_type" { }
variable "worker_sg_ids"        { type = "list" }


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
        values = [ "travis-platform" ]
    }

    # Only allow AMIs tagged for this environment
    filter {
        name = "tag:${title(var.env)}"
        values = [ "true" ]
    }
}

data "aws_ami" "worker" {
    most_recent = true
    owners      = [ "self" ]

    filter {
        name   = "state"
        values = [ "available" ]
    }

    filter {
        name   = "tag:Role"
        values = [ "travis-worker" ]
    }

    # Only allow AMIs tagged for this environment
    filter {
        name = "tag:${title(var.env)}"
        values = [ "true" ]
    }
}


# ----- Resources

resource "aws_security_group" "allow_travis_workers" {
    name        = "allow_travis_workers"
    description = "Allow Travis Workers"

    tags {
        Name = "allow_travis_workers"
    }
}

resource "aws_security_group_rule" "allow_travis_workers" {
    cidr_blocks       = [ "${module.worker.private_ips}" ]
    from_port         = 0
    protocol          = "-1"
    security_group_id = "${aws_security_group.allow_travis_workers.id}"
    to_port           = 0
    type              = "ingress"
}


# ----- Modules

module "platform" {
    source = "./platform"

    ami_id        = "${data.aws_ami.platform.id}"
    count         = "${var.platform_count}"
    env           = "${var.env}"
    instance_type = "${var.platform_instance_type}"
    key_name      = "${var.key_name}"
    key_path      = "${var.key_path}"
    region        = "${data.aws_region.current.name}"
    sg_ids        = [ "${distinct(concat(var.platform_sg_ids, list(aws_security_group.allow_travis_workers.id)))}" ]
    subnet_id     = "${var.subnet_id}"
}

module "worker" {
    source = "./worker"

    ami_id        = "${data.aws_ami.worker.id}"
    count         = "${var.worker_count}"
    env           = "${var.env}"
    instance_type = "${var.worker_instance_type}"
    key_name      = "${var.key_name}"
    key_path      = "${var.key_path}"
    region        = "${data.aws_region.current.name}"
    sg_ids        = [ "${var.worker_sg_ids}" ]
    subnet_id     = "${var.subnet_id}"
}


# ----- Outputs

output "allow_travis_workers" { value = "${aws_security_group.allow_travis_workers.id}" }

output "platform_private_ips" { value = [ "${module.platform.private_ips}" ] }
output "platform_public_ips"  { value = [ "${module.platform.public_ips}" ] }

output "worker_private_ips" { value = [ "${module.worker.private_ips}" ] }
output "worker_public_ips"  { value = [ "${module.worker.public_ips}" ] }
