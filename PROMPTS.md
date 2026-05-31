# PROMPTS.md — Challenge 3: Build and Deploy as a Docker Image (docker-build-deploy)

- **Student:** Val4evr (Valeriy Proklov)
- **Coding agent:** Claude Code (Opus 4.8)
- **Repo:** https://github.com/Val4evr/harbour-space-cs411-devops
- **Branch:** `challenge/deploying-using-docker`
- **How the lab was driven:** I skipped the optional tutorials and went to the challenge.
  The agent drove the iximiuz playground over `labctl ssh` (base64'd scripts to dodge
  quoting) and did git ops in a local clone.

## Honest summary

I used the agent for the mechanical work — writing the Dockerfile and Jenkinsfile, the SSH
key bootstrap, the credential, and the verification runs. The decisions I actually owned and
can defend: starting with a simple single-stage image for the core, choosing how the pipeline
reaches the docker VM, and picking the digest-pin stretch (with its tradeoff) over the others.

## Prompt-by-prompt log

1. **"Add a simple Dockerfile and the Jenkins stage to build and push."**
   The agent wrote a single-stage `golang:1.24` Dockerfile (`go build -o main main.go`,
   `EXPOSE 4444`, `CMD ["./main"]`) and a Jenkinsfile with Build + Push stages tagging the
   image `ttl.sh/val4evr-cs411:2h`. It flagged that ttl.sh names are global/public and chose
   a course-unique name so a classmate's push can't clobber mine.

2. **"Does the pipeline push to ttl.sh?"**
   Confirmed — a dedicated Push stage runs `docker push "$IMAGE"`. The agent also pointed out
   the deploy half (pull + run on the docker VM) was still missing for the core green check.

3. **"Can we set up docker as a Jenkins node?"**
   The agent probed the playground first: `slaveAgentPort` is disabled, there's no ssh-slaves
   plugin, and the docker VM has no Java — so a real agent node would mean undoing three
   disabled lab settings and reinstalling on every reboot. Docker *is* on the Jenkins box and
   laborant is in the docker group on the VM. **My decision:** go with SSH-from-pipeline
   instead of a node — build+push run locally, only the final `docker run` crosses to the VM
   over SSH. The agent had written a wrong fact into its notes (claimed docker wasn't on the
   Jenkins box); the probe corrected it before it mattered.

4. *(agent)* Added the Deploy stage: `withCredentials` pulls the `docker-ssh` key, then
   `ssh laborant@docker` does `docker pull` → `docker rm -f myapp` (idempotent) →
   `docker run -d -p 4444:4444`. It bootstrapped the key + credential, ran the pipeline green,
   and confirmed `curl docker:4444` returns the expected JSON — verifying the image really
   travels through the registry (the deploy log shows a fresh layer pull on the VM).

5. **"Pin the base image by digest as the stretch instead."**
   My reasoning: tags aren't immutable — the same tag can later point at different bytes — so
   pinning the digest makes the dependency reproducible; the downside is having to update the
   hash whenever I bump the version. The agent resolved the real digest from the registry
   (`docker buildx imagetools inspect golang:1.24`) and pinned the **multi-arch manifest-index**
   digest so Docker still auto-selects the right architecture, then committed it.

## What worked / what didn't

- **Worked:** delegating the pipeline + bootstrap work, and having the agent probe the actual
  topology before committing to node-vs-SSH — that caught and corrected a wrong assumption.
- **Didn't:** the `labctl` SSH tunnel got flaky near the end, so the final digest-pin rebuild
  wasn't re-confirmed live before submission (the earlier full pipeline run was green).
