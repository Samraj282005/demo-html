
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
    }

    stages {

        // 1. Checkout source code from GitHub
        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub'

                checkout scm

                sh 'ls -la'
            }
        }

        // 2. Validate HTML project
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

        // 3. SonarQube code analysis
        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube-Docker') {
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

        // 4. Wait for SonarQube Quality Gate
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

        // 5. Build Docker image
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image'

                sh """
                    docker build \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                    -t ${IMAGE_NAME}:latest .
                """

                echo 'Docker image created successfully'
            }
        }

        // 6. Check Docker image
        stage('Verify Docker Image') {
            steps {
                sh """
                    docker images ${IMAGE_NAME}
                """
            }
        }

        // 7. Deploy container on AWS EC2
        stage('Deploy Docker Container') {
            steps {
                echo 'Deploying website on AWS EC2'

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

        // 8. Verify deployment
        stage('Verify Deployment') {
            steps {
                sh """
                    sleep 5

                    docker ps

                    docker port ${CONTAINER_NAME}

                    docker exec ${CONTAINER_NAME} \
                    wget -qO- http://127.0.0.1/
                """

                echo 'Website deployment verified successfully'
            }
        }
    }

    post {
        success {
            echo '''
            ==========================================
              PIPELINE COMPLETED SUCCESSFULLY
              SonarQube Analysis: Passed
              Docker Image: Created
              Container: Deployed
              Website Port: 8081
            ==========================================
            '''
        }

        failure {
            echo 'Pipeline failed. Check the Jenkins console output.'
        }

        always {
            echo 'Jenkins pipeline execution completed.'
        }
    }
}
