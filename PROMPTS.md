<!--
DRAFT — rewrite in your own voice before submitting. PROMPTS.md is read inside the
Stretch and Debug dimensions, so keep the probe reasoning and the friction moment.
Required: one specific prompt, one friction moment, one verification step. All facts
below are accurate to the session.
-->

# PROMPTS.md — deploy-to-kubernetes

- **Student:** Val4evr (Valeriy Proklov)
- **Agent:** Claude Code (Opus 4.8)
- **Branch:** `challenge/deploy-to-kubernetes`
- **Stretch chosen:** liveness + readiness probes (httpGet on 4444).

## Prompt-by-prompt log

1. **"Do challenge 4 (deploy to Kubernetes); liveness + readiness probes as the
   stretch. The verifier probably needs the pod literally named `myapp`."**
   The agent probed the examiner on the kubernetes box first and confirmed the
   exact check is `kubectl get pod myapp -o jsonpath={.status.podIP}` — so a bare
   Pod named `myapp` (not a Deployment, whose pods get hash suffixes). It branched
   from `main`, brought the digest-pinned Dockerfile over from the docker
   challenge, and wrote a Pod manifest + a Jenkinsfile that builds, pushes to
   ttl.sh, then authenticates to `https://kubernetes:6443` with a ServiceAccount
   bearer token from Jenkins Credentials.

2. *(agent bootstrap)* Created the `jenkins-robot` ServiceAccount, bound it to
   cluster-admin, minted a token, and stored it as the `k8s-token` Jenkins
   credential. Ran the pipeline.

## Friction moment

The first pipeline run failed at the deploy step with *"You must be logged in to
the server (the server has asked for the client to provide credentials)"* — even
though the same token worked when I tested it directly on the kubernetes box. The
token authenticated from the cluster, so why not from Jenkins? The agent dumped
the *stored* credential's last characters and found `tail=EN_END`: the token
extraction had swept up the literal `TOKEN_END` sentinel I'd printed around it and
glued it onto the JWT. A JWT is `header.payload.signature` — exactly two dots,
base64url — so the corrupted one was easy to spot once inspected. Re-minted a
clean token (954 chars, 2 dots), re-stored it, and the run went green. Lesson:
"the token works" and "the token Jenkins is sending works" are different claims —
verify the stored secret, not just the generated one.

## On the probes (why they're not redundant)

- **readinessProbe** controls *traffic*: when it fails, the Pod is pulled from
  Service endpoints so clients stop hitting it — but the container is left
  running (it might just be warming up or briefly busy).
- **livenessProbe** controls *lifecycle*: when it fails, the kubelet *restarts*
  the container — for a process that's wedged/deadlocked but still "up".
  One sheds traffic without killing; the other kills to recover. Using only
  readiness would never recover a hung container; only liveness would send
  traffic to a Pod that isn't ready yet.

## Verification step

Beyond the pipeline's own `kubectl wait --for=condition=Ready`, I reproduced the
examiner's exact probes from the kubernetes box: `kubectl get pod myapp -o
jsonpath={.status.podIP}` returned an IP, `curl <podIP>:4444` returned the JSON,
both probe ports read `4444`, and the examiner journal logged `verify_k8s` and
`verify_stretch_probes` both `completed successfully`.
