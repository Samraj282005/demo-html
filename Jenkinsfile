
pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        IMAGE_NAME     = 'demo-html'
        CONTAINER_NAME = 'demo-html-container'
        HOST_PORT      = '8081'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub'
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Validate HTML Project') {
            steps {
                echo 'Validating project files'

                sh '''
                    test -f Dockerfile
                    test -f anchor.html
                    echo "Project validation successful"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image'

                sh """
                    docker build \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                    -t ${IMAGE_NAME}:latest .
                """
            }
        }

        stage('Verify Docker Image') {
            steps {
                echo 'Checking created Docker image'

                sh """
                    docker images ${IMAGE_NAME}
                    docker image inspect ${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }

        stage('Deploy Docker Container') {
            steps {
                echo 'Deploying application'

                sh """
                    docker rm -f ${CONTAINER_NAME} || true

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    --restart unless-stopped \
                    -p ${HOST_PORT}:80 \
                    ${IMAGE_NAME}:${BUILD_NUMBER}
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Checking website deployment'

                sh """
                    sleep 5
                    docker ps
                    docker port ${CONTAINER_NAME}
                    curl -f http://localhost:${HOST_PORT}/
                """
            }
        }
    }

    post {
        success {
            echo '''
            ==================================
                PIPELINE SUCCESSFUL!
            ==================================
                GitHub Checkout : SUCCESS
                HTML Validation: SUCCESS
                Docker Build    : SUCCESS
                Docker Image    : CREATED
                Docker Deploy   : SUCCESS

                Website Port: 8081
            ==================================
            '''
        }

        failure {
            echo 'PIPELINE FAILED - Check Console Output'
        }

        always {
            echo 'Pipeline execution completed'
        }
    }
}
