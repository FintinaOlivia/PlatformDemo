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
                    sleep 99d
            '''
        }
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {

        REGISTRY = "localhost:5001"
        IMAGE = "localhost:5001/platform-demo"
        CACHE_IMAGE = "localhost:5001/platform-demo:build-cache"

        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {

        stage('Environment') {
            steps {
                sh '''
                    docker --version
                    docker buildx version
                    kubectl version --client
                    trivy --version
                '''
            }
        }

        stage('Test') {
            steps {

                sh '''
                    python3 -m venv .venv

                    . .venv/bin/activate

                    pip install -q -r requirements.txt

                    pytest
                '''
            }
        }

        stage('Build') {

            steps {

                script {

                    def start = System.currentTimeMillis()

                    sh """
                        docker buildx build \
                            --cache-from \
                              type=registry,ref=${CACHE_IMAGE} \
                            --cache-to \
                              type=registry,ref=${CACHE_IMAGE},mode=max \
                            --tag ${IMAGE}:${IMAGE_TAG} \
                            --load \
                            .
                    """

                    def end = System.currentTimeMillis()

                    env.BUILD_TIME_MS =
                        (end - start).toString()

                    echo "BUILD_TIME_MS=${env.BUILD_TIME_MS}"
                }
            }
        }

        stage('Security Scan') {

            steps {

                script {

                    def start = System.currentTimeMillis()

                    sh """
                        trivy image \
                            --severity HIGH,CRITICAL \
                            --exit-code 1 \
                            ${IMAGE}:${IMAGE_TAG}
                    """

                    def end = System.currentTimeMillis()

                    env.SCAN_TIME_MS =
                        (end - start).toString()

                    echo "SCAN_TIME_MS=${env.SCAN_TIME_MS}"
                }
            }
        }

        stage('Push') {

            steps {

                script {

                    def start = System.currentTimeMillis()

                    sh """
                        docker push ${IMAGE}:${IMAGE_TAG}
                    """

                    def end = System.currentTimeMillis()

                    env.PUSH_TIME_MS =
                        (end - start).toString()

                    echo "PUSH_TIME_MS=${env.PUSH_TIME_MS}"
                }
            }
        }

        stage('Deploy') {

            steps {

                script {

                    def start = System.currentTimeMillis()

                    sh """
                        kubectl apply -f k8s/

                        kubectl set image \
                          deployment/platform-demo \
                          platform-demo=${IMAGE}:${IMAGE_TAG}

                        kubectl rollout status \
                          deployment/platform-demo \
                          --timeout=120s
                    """

                    def end = System.currentTimeMillis()

                    env.DEPLOY_TIME_MS =
                        (end - start).toString()

                    echo "DEPLOY_TIME_MS=${env.DEPLOY_TIME_MS}"
                }
            }
        }
    }

    post {

        always {
            echo "BUILD       : ${env.BUILD_TIME_MS} ms"
            echo "SCAN        : ${env.SCAN_TIME_MS} ms"
            echo "PUSH        : ${env.PUSH_TIME_MS} ms"
            echo "DEPLOY      : ${env.DEPLOY_TIME_MS} ms"
        }
    }
}