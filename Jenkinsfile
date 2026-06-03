// CS411 — docker-build-deploy: containerize the app, treat the IMAGE as the artifact,
// and ship it through a registry (ttl.sh) instead of scp'ing a raw binary.
//
// Topology: the built-in Jenkins agent has Docker, so build + push run locally.
// Only the final `docker run` has to happen on the separate `docker` VM (172.16.0.3),
// which is where the dashboard checks :4444 — we reach it over SSH.
pipeline {
    agent any

    environment {
        // ttl.sh is an anonymous, transient registry — the ":2h" tag IS the time-to-live
        // (the image is auto-deleted after 2 hours). No registry credentials needed.
        // NOTE: ttl.sh names are global + public; a course-unique name avoids a
        // classmate's push clobbering ours.
        IMAGE = 'ttl.sh/val4evr-cs411:2h'
        // The container name on the docker VM — fixed so re-deploys replace it cleanly.
        APP   = 'myapp'
    }

    stages {
        stage('Build image') {
            steps {
                // Build context is the repo root (Dockerfile + main.go live there).
                sh 'docker build -t "$IMAGE" .'
            }
        }

        stage('Push image') {
            steps {
                // Anonymous push — ttl.sh accepts it without `docker login`.
                sh 'docker push "$IMAGE"'
            }
        }

        stage('Deploy on docker VM') {
            steps {
                // SSH key pulled from Jenkins Credentials by ID (never in the repo,
                // masked in the log). laborant is in the docker group on the VM, so
                // no sudo is needed for docker commands.
                withCredentials([sshUserPrivateKey(
                        credentialsId: 'docker-ssh',
                        keyFileVariable: 'KEY',
                        usernameVariable: 'SSH_USER')]) {
                    sh '''
                        set -eu
                        SSH_OPTS="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

                        # Pull our just-pushed image, then (re)run it. rm -f first makes the
                        # deploy idempotent: a second run won't fail on a name/port clash.
                        ssh $SSH_OPTS "$SSH_USER@docker" "
                            docker pull '$IMAGE'
                            docker rm -f '$APP' 2>/dev/null || true
                            docker run -d --name '$APP' -p 4444:4444 '$IMAGE'
                        "
                    '''
                }
            }
        }
    }
}
