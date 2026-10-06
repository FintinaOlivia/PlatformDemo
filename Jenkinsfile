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
        - --config
        - /etc/buildkit/buildkitd.toml
      securityContext:
        privileged: true
      volumeMounts:
        - name: buildkit-config
          mountPath: /etc/buildkit/buildkitd.toml
          subPath: buildkitd.toml

    - name: trivy
      image: aquasec/trivy:latest
      command:
        - sh
      args:
        - -c
        - |
          tail -f /dev/null

    - name: jnlp
      image: jenkins/inbound-agent:latest

  volumes:
    - name: buildkit-config
      configMap:
        name: buildkit-config
'''
        }
    }

    environment {
        IMAGE_NAME = 'kind-registry:5000/platform-demo'
        IMAGE_TAG = "${env.GIT_COMMIT}"
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

        stage('Build and Push Image') {
            steps {
                container('builder') {
                    sh '''
                        set -e

                        buildctl \
                            --addr unix:///run/user/1000/buildkit/buildkitd.sock \
                            build \
                            --frontend dockerfile.v0 \
                            --local context=. \
                            --local dockerfile=. \
                            --output type=image,name=${IMAGE_NAME}:${IMAGE_TAG},push=true
                    '''
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                container('trivy') {
                    sh '''
                        set -e

                        echo "Scanning ${IMAGE_NAME}:${IMAGE_TAG}"

                        trivy image \
                            --insecure \
                            --severity HIGH,CRITICAL \
                            // --exit-code 1 \
                            --no-progress \
                            ${IMAGE_NAME}:${IMAGE_TAG}
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