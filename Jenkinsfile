// CS411 — full deployment pipeline: build main on the Jenkins box, ship the
// binary to a different machine (target), and run it there under systemd so it
// survives the SSH session that started it.
pipeline {
    agent any

    // Pulls in the Go toolchain declared in JCasC (jenkins.yaml -> tool.go.installations).
    // The name must match exactly; the golang plugin auto-installs it on first use
    // and prepends its bin/ to PATH.
    tools {
        go '1.24.1'
    }

    environment {
        // The other machine in the playground (see /etc/hosts: 172.16.0.3).
        TARGET = 'target'
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

        stage('Deploy to target') {
            steps {
                // Pull the SSH private key out of Jenkins Credentials by ID. Jenkins
                // writes it to a temp file ($KEY), supplies the stored username
                // ($SSH_USER), and shreds the file when this block ends. The key is
                // never in the repo and is masked in the build log.
                withCredentials([sshUserPrivateKey(
                        credentialsId: 'target-ssh',
                        keyFileVariable: 'KEY',
                        usernameVariable: 'SSH_USER')]) {
                    sh '''
                        set -eu
                        SSH_OPTS="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

                        # 1. SHIP: copy this run's freshly built binary to target.
                        #    Same bytes we just built + archived — no rebuild on target.
                        scp $SSH_OPTS main "$SSH_USER@$TARGET:/tmp/main"

                        # 2. INSTALL + SUPERVISE: place the binary, write a systemd unit,
                        #    and hand the process to systemd so it outlives this SSH session.
                        #    The quoted heredoc (<<'REMOTE') is sent literally — no Jenkins-side
                        #    expansion — so the unit file lands intact.
                        ssh $SSH_OPTS "$SSH_USER@$TARGET" 'sudo bash -s' <<'REMOTE'
set -eu

# Dedicated, unprivileged service account. --system = no aging/login, no home,
# /usr/sbin/nologin so it can never be logged into. Idempotent: skip if present.
id myapp >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin myapp

install -m 755 /tmp/main /usr/local/bin/myapp

cat > /etc/systemd/system/myapp.service <<'UNIT'
[Unit]
Description=CS411 hello-world Go service
After=network.target

[Service]
ExecStart=/usr/local/bin/myapp
# Run unprivileged — :4444 is > 1024 so no special capability is needed to bind it.
User=myapp
Group=myapp
Restart=on-failure
# Defense-in-depth hardening (cheap wins for a service that needs nothing special).
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable myapp.service
# restart (not just start) so a re-deploy swaps in the new binary on an
# already-running unit instead of silently keeping the old process.
systemctl restart myapp.service
REMOTE
                    '''
                }
            }
        }
    }
}
