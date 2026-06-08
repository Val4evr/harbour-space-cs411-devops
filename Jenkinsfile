// CS411 — deploy-to-kubernetes: build the image, push it to ttl.sh, then have the
// Jenkins job authenticate to the cluster API and apply a Pod manifest. The image
// is the artifact (challenge 3); the new piece is talking to the k8s API with a
// ServiceAccount bearer token stored in Jenkins Credentials.
pipeline {
    agent any

    environment {
        IMAGE   = 'ttl.sh/val4evr-cs411:2h'
        // The cluster API. The k3s server cert is not trusted by the Jenkins box,
        // so the kubectl calls below pass --insecure-skip-tls-verify (lab-only).
        K8S_API = 'https://kubernetes:6443'
    }

    stages {
        stage('Build image') {
            steps {
                sh 'docker build -t "$IMAGE" .'
            }
        }

        stage('Push image') {
            steps {
                // Anonymous transient registry — no docker login needed.
                sh 'docker push "$IMAGE"'
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Bearer token for the jenkins-robot ServiceAccount (cluster-admin),
                // stored as a Jenkins "Secret text" credential. Never in the repo;
                // masked in the build log.
                withCredentials([string(credentialsId: 'k8s-token', variable: 'K8S_TOKEN')]) {
                    sh '''
                        set -eu
                        KC="kubectl --server=$K8S_API --token=$K8S_TOKEN --insecure-skip-tls-verify=true"

                        # Apply the Pod manifest. delete-first keeps the deploy idempotent:
                        # a Pod's image/spec is largely immutable, so re-applying a changed
                        # manifest would otherwise be rejected.
                        $KC delete pod myapp --ignore-not-found
                        $KC apply -f k8s/pod.yaml

                        # Block until the kubelet reports the Pod Ready (readiness probe
                        # passing) — a green pipeline must mean it actually serves.
                        $KC wait --for=condition=Ready pod/myapp --timeout=120s
                        $KC get pod myapp -o wide
                    '''
                }
            }
        }
    }
}
