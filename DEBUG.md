## Two ranked hypotheses

1. The Security Group has no inbound rule allowing tcp/4444, so the SG silently drops the inbound packets. If there is no response from the host, the packet got dropped. Otherwise there would at least be a SYN-ACK response (part of TCP handshake). Verify with `aws ec2 describe-security-groups --group-ids <sg-id> --query "SecurityGroups[].IpPermissions"` (apparently). Fix by adding one inbound SG rule allowing tcp/4444 from 0.0.0.0/0.

2. The subnet's NACL is denying tcp/4444. The NACL is a second, independent filter that can block return traffic even if inbound 4444 looks allowed. Verify with `aws ec2 describe-network-acls`. Fix by removing the NACL deny so 4444 and the ephemeral return ports pass.

## Underlying lesson

A dropped packet (firewall) produces silence and the client hangs, while a packet that reaches a closed port gets a "connection refused" response.
