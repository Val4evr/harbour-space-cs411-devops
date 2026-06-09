## Two ranked hypotheses

1. The image expired from ttl.sh before the kubelet pulled it. `docker pull` on Jenkins succeeded only because Jenkins built the image locally moments ago and has it cached. The kubelet must fetch it from the registry (where it already expired). Verify with `kubectl describe pod myapp`. Fix by re-running the pipeline.

2. The kubelet can't reach the registry over the network even though
   Jenkins can. Verify with `kubectl describe pod myapp` looking for timeouts / DNS errors. Debug by fixing node networking to the registry.

## Underlying lesson

"I can pull this image" is a statement about *my* host's cache and network;
"the cluster can pull this image" is about a different identity (the kubelet) on
a different host with a different cache and network path — the image must be
reachable from *there*, at pull time, not just from where it was built.
