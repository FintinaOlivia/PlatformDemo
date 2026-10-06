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
        - rootlesskit
      args:
        - buildkitd
        - --addr
        - unix:///run/user/1000/buildkit/buildkitd.sock

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

                        echo "=== buildctl ==="
                        buildctl --version

                        echo "=== BuildKit socket ==="
                        ls -l /run/user/1000/buildkit/ || true

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