# DEBUG.md — deploy-to-kubernetes

Scenario: the pipeline pushes the image to ttl.sh and applies the Pod, but
`kubectl get pods` shows `ImagePullBackOff`. The `image:` in the manifest matches
the pushed tag, and `docker pull <image>` on the Jenkins machine succeeds.

## Two ranked hypotheses

1. The image expired from ttl.sh before the kubelet pulled it. ttl.sh tags are
   transient (`:2h` IS the time-to-live), and `docker pull` on Jenkins succeeded
   only because Jenkins built the image locally moments ago and has it cached —
   the *kubelet*, a different host with no cache, must fetch it fresh from a
   registry whose copy may already be gone. Verify with
   `kubectl describe pod myapp` and read the Events — `manifest unknown` / `not
   found` (a 404) confirms the registry no longer has it. Fix by re-running the
   pipeline so a fresh image is pushed right before the apply (and/or widen the
   tag, e.g. `:24h`).

2. The kubelet can't reach the registry over the network (egress/DNS) even though
   Jenkins can. The pull happens from the cluster node, whose network path to
   ttl.sh differs from the Jenkins box's. Verify with `kubectl describe pod myapp`
   — a `dial tcp ... timeout` / DNS error (rather than a 404) points here, and
   `crictl pull <image>` run on the node reproduces it directly. Fix by giving
   the node egress to the registry (or pre-loading the image onto the node with
   `ctr images import`).

## Underlying lesson

"I can pull this image" is a statement about *my* host's cache and network;
"the cluster can pull this image" is about a different identity (the kubelet) on
a different host with a different cache and network path — the image must be
reachable from *there*, at pull time, not just from where it was built.
