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
        - sleep 99d
'''
        }
    }

    stages {
        stage('Test Agent') {
            steps {
                sh '''
                    echo "Running on Kubernetes agent"
                    echo "Hostname: $(hostname)"
                    uname -a
                    buildctl --version
                '''
            }
        }
    }

    post {
        always {
            echo "BUILD       : ${env.BUILD_TIME} ms"
            echo "SCAN        : ${env.SCAN_TIME} ms"
            echo "PUSH        : ${env.PUSH_TIME} ms"
            echo "DEPLOY      : ${env.DEPLOY_TIME} ms"
        }
    }
}