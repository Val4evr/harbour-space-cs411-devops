## Prompt-by-prompt log

1. **"Start challenge 5. EC2 is up, PEM in Downloads, IP 13.51.146.63. Verify the connection first; stretch = SG lockdown."**
   The agent fixed the .pem perms (chmod 600), found the login user by trying candidates
   (it's `ec2-user` on Amazon Linux 2023, not `ubuntu`), and confirmed passwordless sudo +
   x86_64 + systemd 252. It flagged that `:4444` was closed from outside until both the app
   runs AND the SG allows it.

2. *(agent)* Wrote the Jenkinsfile Deploy-to-EC2 stage — same shape as challenge 2
   (`withCredentials` → `scp` → `ssh 'sudo bash -s'` heredoc → systemd unit with
   `Restart=on-failure`), only the host (`13.51.146.63`) and user (`ec2-user`) changed. Built
   a static `CGO_ENABLED=0 GOOS=linux GOARCH=amd64` binary.

3. *(agent)* Proved the deploy path by hand first: hit flaky SSH that turned out to be sshd
   `MaxStartups` randomly dropping rapid connections (mis-shows as "Permission denied"); fixed
   by cooling down + doing it in ONE connection. Result: service active/enabled, and
   `curl <public-ip>:4444` returns the JSON **from outside AWS**.

4. **"Run it through the playground Jenkins; do the :22 stretch via console clicks."**
   The agent created the `ec2-ssh` credential in Jenkins (SSH private key, user ec2-user),
   pushed the branch, seeded + ran the pipeline → build SUCCESS with the key masked as `****`
   in the log. Added a `.gitignore` so the binary / .pem never get committed.

5. **"Port 22 locked down."** (I edited the SG inbound rule in the console: SSH source
   0.0.0.0/0 → my IP /32; left 4444 open to 0.0.0.0/0.)
   The agent verified from the playground network: `:4444` → HTTP 200 (open), `:22` → blocked
   (hangs/times out) — exactly the two probes the dashboard auto-check runs.


## One failure mode that blanket :22 from 0.0.0.0/0 enables:
Although the SSH is protected by the PEM requirement, the whole internet can still reach it, so the VM is continuously hit by automated credential-stuffing / brute-force bots which is less secure than restricting the access to only my IP.

## One inconvenience your narrower /32 rule introduces:
My home IP is dynamic so if it changes I'll be locked out of SSHing into the VM. 