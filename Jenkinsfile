// CS411 — build half of the deployment pipeline.
// Compiles the Go service (main.go) into a binary named `main` and promotes it
// to a Jenkins artifact. The deploy stage (scp to target + systemd) is added on
// top of this in the first-deployment-pipeline challenge.
pipeline {
    agent any

    // Pulls in the Go toolchain declared in JCasC (jenkins.yaml -> tool.go.installations).
    // The name must match exactly; the golang plugin auto-installs it on first use
    // and prepends its bin/ to PATH.
    tools {
        go '1.24.1'
    }

    stages {
        stage('Build') {
            steps {
                sh 'go version'
                // CGO_ENABLED=0 -> a self-contained, pure-Go binary that runs on `target`
                // even though target has no Go (and possibly a different libc).
                sh 'CGO_ENABLED=0 go build -o main main.go'
            }
        }

        stage('Archive artifact') {
            steps {
                // The build artifact: a thing that outlives the build and gets shipped.
                archiveArtifacts artifacts: 'main', fingerprint: true
            }
        }
    }
}
