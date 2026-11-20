
package main

import rego.v1

deny contains msg if {
    some resource in input.resource_changes
    resource.type == "aws_security_group"

    some rule in resource.change.after.ingress
    rule.from_port <= 22
    rule.to_port >= 22

    some cidr in rule.cidr_blocks
    cidr == "0.0.0.0/0"

    msg := sprintf(
        "CRITICAL: Security Group %s allows SSH (port 22) from the public internet.",
        [resource.address]
    )
}
