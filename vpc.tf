# Setup mozreview vpc
resource "aws_vpc" "mozreview_vpc" {

    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags {
        Name = "${var.env}-mozreview-vpc"
    }
}

module "vpc_bastion_peer" {
    source = "../tf_vpc_peer"

    name = "${var.env}-bastion_peer"
    requester_vpc_id = "${aws_vpc.mozreview_vpc.id}"
    requester_route_table_id = "${aws_route_table.mozreview_public-rt.id}"
    requester_cidr_block = "${var.vpc_cidr}"
    peer_vpc_id = "${var.peer_vpc_id}"
    peer_route_table_id = "${var.peer_route_table_id}"
    peer_cidr_block = "${var.peer_cidr_block}"
    peer_account_id = "${var.peer_account_id}"

}

# Setup internet gateway for vpc
resource "aws_internet_gateway" "mozreview_igw" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"

    tags {
        Name = "${var.env}-mozreview-igw"
    }
}

# Setup route table for public subnets
resource "aws_route_table" "mozreview_public-rt" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"

    tags {
        Name = "${var.env}-mozreview-public-rt"
    }
}

# Setup route table for private subnets
resource "aws_route_table" "mozreview_private-rt" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"

    tags {
        Name = "${var.env}-mozreview-private-rt"
    }
}

# Add default route to internet bound route table
resource "aws_route" "mozreview_public_igw-rtr" {
    route_table_id = "${aws_route_table.mozreview_public-rt.id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.mozreview_igw.id}"
}

# Setup public subnets for elb
resource "aws_subnet" "elb_subnet" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"
    cidr_block = "${element(split(",", var.elb_subnets), count.index)}"
    availability_zone = "${element(split(",", var.elb_azs), count.index)}"
    count = "${length(compact(split(",", var.elb_subnets)))}"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.env}-mozreview-elb-subnet-${count.index}"
    }
}

resource "aws_route_table_association" "elb" {
    count = "${length(compact(split(",", var.elb_subnets)))}"
    subnet_id = "${element(aws_subnet.elb_subnet.*.id, count.index)}"
    route_table_id = "${aws_route_table.mozreview_public-rt.id}"
}

# Setup public subnets for webheads
resource "aws_subnet" "web_subnet" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"
    cidr_block = "${element(split(",", var.web_subnets), count.index)}"
    availability_zone = "${element(split(",", var.web_azs), count.index)}"
    count = "${length(compact(split(",", var.web_subnets)))}"
    map_public_ip_on_launch = true

    tags {
        Name = "${var.env}-mozreview-web-subnet-${count.index}"
    }
}

resource "aws_route_table_association" "web" {
  count = "${length(compact(split(",", var.web_subnets)))}"
  subnet_id = "${element(aws_subnet.web_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.mozreview_public-rt.id}"
}

# Setup private subnets for rds
resource "aws_subnet" "rds_subnet" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"
    cidr_block = "${element(split(",", var.rds_subnets), count.index)}"
    availability_zone = "${element(split(",", var.rds_azs), count.index)}"
    count = "${length(compact(split(",", var.rds_subnets)))}"

    tags {
        Name = "${var.env}-mozreview-rds-subnet-${count.index}"
    }
}

resource "aws_route_table_association" "rds" {
    count = "${length(compact(split(",", var.rds_subnets)))}"
    subnet_id = "${element(aws_subnet.rds_subnet.*.id, count.index)}"
    route_table_id = "${aws_route_table.mozreview_private-rt.id}"
}

# Setup private subnets for elasticache
resource "aws_subnet" "elc_subnet" {
    vpc_id = "${aws_vpc.mozreview_vpc.id}"
    cidr_block = "${element(split(",", var.elc_subnets), count.index)}"
    availability_zone = "${element(split(",", var.elc_azs), count.index)}"
    count = "${length(compact(split(",", var.elc_subnets)))}"

    tags {
        Name = "${var.env}-mozreview-elc-subnet-${count.index}"
    }
}

resource "aws_route_table_association" "elc" {
    count = "${length(compact(split(",", var.elc_subnets)))}"
    subnet_id = "${element(aws_subnet.elc_subnet.*.id, count.index)}"
    route_table_id = "${aws_route_table.mozreview_private-rt.id}"
}

