
pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    environment {
        PROJECT_NAME   = 'demo-html'
        IMAGE_NAME     = 'demo-html'
        CONTAINER_NAME = 'demo-html-container'
        HOST_PORT      = '8081'

        // Must exactly match the SonarQube server Name
        // configured in Manage Jenkins > System.
        SONAR_SERVER = 'SonarQube-Docker'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub'
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Build HTML Project') {
            steps {
                echo 'Validating HTML project'

                sh '''
                    test -f Dockerfile
                    test -f anchor.html
                    echo "HTML project validation successful"
                '''
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv("${SONAR_SERVER}") {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=demo-html \
                            -Dsonar.projectName='Demo HTML' \
                            -Dsonar.projectVersion=${BUILD_NUMBER} \
                            -Dsonar.sources=. \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.exclusions=.git/**,**/*.jpg,**/*.jpeg,**/*.png,**/*.webp
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qualityGate = waitForQualityGate(
                            abortPipeline: true
                        )

                        echo "Quality Gate Status: ${qualityGate.status}"
                    }
                }
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
                sh 'docker images demo-html'
            }
        }

        stage('Deploy Docker Container') {
            steps {
                echo 'Deploying Docker container on AWS EC2'

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
            ====================================
                PIPELINE SUCCESSFUL
            ====================================
                GitHub Checkout : SUCCESS
                HTML Validation: SUCCESS
                SonarQube       : SUCCESS
                Quality Gate    : PASSED
                Docker Build    : SUCCESS
                Docker Deploy   : SUCCESS
                Website Port    : 8081
            ====================================
            '''
        }

        failure {
            echo 'Pipeline failed. Check Jenkins Console Output.'
        }

        always {
            echo 'Pipeline execution completed.'
        }
    }
}
