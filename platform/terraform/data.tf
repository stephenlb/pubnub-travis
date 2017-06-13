# Travis Platform Terraform Data Sources

# Travis Platform Amazon AMI
data "aws_ami" "travis-platform" {
    most_recent = true
    owners = [ "self" ]

    filter {
        name = "state"
        values = [ "available" ]
    }

    filter {
        name = "tag:Role"
        values = [ "${var.role}" ]
    }

    # Only stable AMIs are allowed in production
    filter {
        name = "tag:Stable"
        values = "${lower(var.env) == "production" ? list("true") : list("true", "false")}"
    }
}

# Subnet
data "aws_subnet" "travis-platform" {
    state = "available"
}
