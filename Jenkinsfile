// CS411 — docker-build-deploy: containerize the app, treat the IMAGE as the artifact,
// and ship it through a registry (ttl.sh) instead of scp'ing a raw binary.
pipeline {
    agent any

    environment {
        // ttl.sh is an anonymous, transient registry — the ":2h" tag IS the time-to-live
        // (the image is auto-deleted after 2 hours). No registry credentials needed.
        // NOTE: ttl.sh names are global + public; a course-unique name avoids a
        // classmate's push clobbering ours.
        IMAGE = 'ttl.sh/val4evr-cs411:2h'
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

        // NEXT: a 'Deploy on docker VM' stage that pulls $IMAGE and runs it with
        // -p 4444:4444. Added once we confirm the playground's docker-VM topology
        // (separate node vs. ssh) — that's the other half of the core criterion.
    }
}
