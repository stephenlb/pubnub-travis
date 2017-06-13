
# Travis Platform Amazon Security Group
# resource "aws_security_group" "travis-platform" {
#    name = "${var.role}"
#    description = "Travis Platform Security Group"
#    vpc_id = "${data.aws_subnet.travis-platform.vpc_id}"
#
#    ingress {
#        cidr_blocks = [ "${data.aws_subnet.travis-platform.cidr_block}" ]
#        protocol = "tcp"
#        from_port =
#        to_port =
#    }
#
#    egress {
#
#    }
#
#    tags {
#        Name = "${var.role}"
#    }
#}

# Travis Platform Amazon EC2 Instance
resource "aws_instance" "travis-platform" {

    # Required Configuration
    ami = "${data.aws_ami.travis-platform.id}"
    instance_type = "c3.2xlarge"

    # Optional Configuration
    associate_public_ip_address = true
    ebs_optimized = true
    vpc_security_group_ids = [ "TODO" ]
    subnet_id = "TODO"

    # Lifecycle
    lifecycle { create_before_destroy = true }

    # Tagging
    tags {
        Name = "${format(var.role%dlower(var.env), count.index + 1)}"
        Role = "${var.role}"
        CostCenter = "COGS"
        Department = "Engineering"
        Environment = "${title(var.env)}"
        Service = "CICD"
        Component = "Build"
        Region = "TODO"
    }

    volume_tags {
        TODO
    }
}
