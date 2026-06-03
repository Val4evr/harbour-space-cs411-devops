// CS411 — deployment-to-cloud: build the Go binary, then ship it to a real AWS EC2
// instance (outside the playground) and run it under systemd. Same scp + systemd
// shape as first-deployment-pipeline; the only thing that changed is WHERE the
// target lives — a public cloud host reached over the internet.
pipeline {
    agent any

    tools {
        go '1.24.1'
    }

    environment {
        // Public IP of the EC2 instance (Amazon Linux 2023, default login user ec2-user).
        EC2_HOST = '13.51.146.63'
        EC2_USER = 'ec2-user'
    }

    stages {
        stage('Build') {
            steps {
                sh 'go version'
                // CGO_ENABLED=0 -> static linux/amd64 binary that runs on the EC2 box
                // (which has no Go toolchain), exactly like the on-prem target before it.
                sh 'CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main main.go'
            }
        }

        stage('Archive artifact') {
            steps {
                archiveArtifacts artifacts: 'main', fingerprint: true
            }
        }

        stage('Deploy to EC2') {
            steps {
                // EC2 private key lives in Jenkins Credentials (SSH Username with private
                // key, id 'ec2-ssh') — never in the repo, masked in the log. Jenkins
                // writes it to $KEY for the block and shreds it after.
                withCredentials([sshUserPrivateKey(
                        credentialsId: 'ec2-ssh',
                        keyFileVariable: 'KEY',
                        usernameVariable: 'SSH_USER')]) {
                    sh '''
                        set -eu
                        # StrictHostKeyChecking=no: EC2 host key is unknown on each fresh
                        # Jenkins; UserKnownHostsFile=/dev/null keeps it from being recorded.
                        SSH_OPTS="-i $KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

                        # 1. SHIP: copy this run's freshly built binary to the EC2 box.
                        scp $SSH_OPTS main "$EC2_USER@$EC2_HOST:/tmp/main"

                        # 2. INSTALL + SUPERVISE: place the binary, write a systemd unit,
                        #    and hand the process to systemd so it survives the SSH session.
                        ssh $SSH_OPTS "$EC2_USER@$EC2_HOST" 'sudo bash -s' <<'REMOTE'
set -eu
install -m 755 /tmp/main /usr/local/bin/myapp

cat > /etc/systemd/system/myapp.service <<'UNIT'
[Unit]
Description=CS411 hello-world Go service
After=network.target

[Service]
ExecStart=/usr/local/bin/myapp
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable myapp.service
# restart (not just start) so a re-deploy swaps in the new binary cleanly.
systemctl restart myapp.service
REMOTE
                    '''
                }
            }
        }
    }
}
