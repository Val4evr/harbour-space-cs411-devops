What I did:
1. Added go dependency to jenkinsfile to build the binary
2. Compiled the go code into a binary
3. Used scp to copy the binary to the target machine
4. Configured a systemd service to run the binary 

What was most surprising:
1. No surprises, everything went as expected.

What's still unclear:

The challenge mentions a auto check hook for the systemd stretch, but I didn't figure out how it runs or where to see that it succeeded.