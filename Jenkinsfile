pipeline {
    agent {
        kubernetes {
            defaultContainer 'builder'

            yaml '''
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: builder
      image: moby/buildkit:rootless
      command:
        - sh
      args:
        - -c
        - |
          buildkitd \
            --addr unix:///run/user/1000/buildkit/buildkitd.sock &
          sleep 5
          tail -f /dev/null

    - name: jnlp
      image: jenkins/inbound-agent:latest
'''
        }
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('BuildKit Diagnostics') {
            steps {
                container('builder') {
                    sh '''
                        set -e

                        echo "=== Container ==="
                        cat /etc/os-release || true

                        echo "=== PATH ==="
                        echo "$PATH"

                        echo "=== buildctl location ==="
                        command -v buildctl || true
                        ls -l /usr/bin/buildctl 2>/dev/null || true
                        ls -l /usr/local/bin/buildctl 2>/dev/null || true

                        echo "=== buildctl version ==="
                        buildctl --version

                        echo "=== BuildKit workers ==="
                        buildctl \
                            --addr unix:///run/user/1000/buildkit/buildkitd.sock \
                            debug workers
                    '''
                }
            }
        }

        stage('Test') {
            steps {
                container('builder') {
                    sh '''
                        echo "Running application tests..."

                        if [ -f requirements.txt ]; then
                            echo "requirements.txt found"
                        fi

                        if [ -d tests ]; then
                            echo "Tests directory found"
                        fi
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
    }
}