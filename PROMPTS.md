1. **"Open challenge 2 with labctl. I skipped the tutorials — what do I need to pre-prepare?"**
   The agent inspected the playground and found the only missing prerequisite was a
   build-only `Jenkinsfile` (challenge 1 only produced `main.go`; the *build* was done in
   an optional tutorial). It wrote one, pushed to `main`, and verified `myapp` goes green —
   catching that `options { timestamps() }` doesn't compile in this Jenkins (Timestamper
   option not registered) before I ever hit it.

2. **"Add the Jenkinsfile so I can start."**
   Pushed the build-only Jenkinsfile; verified build → `SUCCESS` with the `main` binary
   archived as an artifact.

3. **Questions: "You put the Go install step in the Jenkinsfile? Is it cached?"**
   Clarified that `tools { go '1.24.1' }` references the toolchain declared in JCasC and the
   golang plugin caches it under `$JENKINS_HOME/tools` after the first build (and that a
   fresh playground re-downloads it once).

4. **"Where's the artifact to run it?" / "I can't see it in the app tab."**
   Found I had run `./main` on the *jenkins* box, but the app tab checks *target*. The agent
   explained the deploy-vs-build gap; a manual `scp` + run on target lit up the app tab.

5. **"Generate the key, give me the public key and where it goes on target."**
   Generated a dedicated `ed25519` deploy keypair kept outside the repo
   (`jenkins_deploy_ed25519`); told me to put the public half in
   `target:/home/laborant/.ssh/authorized_keys`.

6. **"Explain the Jenkinsfile change before deployment."**
   The agent walked through the Deploy stage (withCredentials → scp → ssh heredoc → systemd).
   I chose **minimal-core** systemd first and asked it to **script** the credential.

7. *(agent bootstrap)* It installed the pubkey on target — hitting two real gotchas: the
   `authorized_keys` file is mode 400 (needs `chmod u+w` first) and the platform's
   `(managed)` key line has no trailing newline, so a blind `>>` glued my key onto it. It
   created the `target-ssh` credential via the Jenkins script console, pushed the Deploy
   stage to the challenge branch, ran the pipeline green, confirmed `curl target:4444`
   returns the JSON, and proved supervision by killing the process and showing systemd
   respawn it in `journalctl`.

8. **"Add the non-root myapp stretch."**
   Added a dedicated `myapp` system user + `User=myapp` and hardening to the unit; rebuilt
   and confirmed the stretch criteria (enabled, non-root, `Restart=on-failure`) all pass.

9. **"Run the auto verification and give me skeletons for DEBUG.md and REFLECTION.md."**
   There's no `labctl` command to trigger the dashboard check, so the agent reproduced every
   assertion `verify_stretch_systemd` makes directly on target (all pass) and handed me
   skeletons. I wrote the prose myself.

10. **VM restart → progress lost.** I rebooted the VM, which wiped all in-VM state (Jenkins
    job, credential, target's authorized_keys, the running service). The agent re-bootstrapped
    everything in ~30s from the durable inputs (the keypair on my Mac + the Jenkinsfile in
    git). This is the lesson that stuck: runtime state is disposable, declarative inputs are not.

11. **"Add PROMPTS.md and let me review before the PR."**
    This file.

