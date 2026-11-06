
pipeline {
    agent any

    tools {
        nodejs 'NodeJS 26.x'
    }

    environment {
        AWS_REGION = 'ap-south-1'
        AWS_ACCOUNT_ID = '054022771060'
        ECR_REPOSITORY = 'sample/html1'
        REGISTRY = '054022771060.dkr.ecr.ap-south-1.amazonaws.com'

        LOCAL_IMAGE = 'sports-web:latest'
        IMAGE_TAG = "${BUILD_NUMBER}"
        ECR_IMAGE = "${REGISTRY}/sample/html1:${BUILD_NUMBER}"
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/Samraj282005/Sports-Web.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('SonarQube Code Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    script {
                        def scannerHome = tool 'SonarScanner'

                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=Sports-Web \
                            -Dsonar.projectName=Sports-Web \
                            -Dsonar.sources=src \
                            -Dsonar.exclusions=node_modules/**,dist/**,build/** \
                            -Dsonar.sourceEncoding=UTF-8
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t "$LOCAL_IMAGE" .
                '''
            }
        }

        stage('Docker Images') {
            steps {
                sh 'docker images'
            }
        }

        stage('Trivy Security Scan') {
            steps {
                sh '''
                    echo "Scanning Docker image with Trivy..."

                    trivy image \
                        --exit-code 1 \
                        --severity HIGH,CRITICAL \
                        "$LOCAL_IMAGE"
                '''
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                sh '''
                    echo "Authenticating with AWS..."

                    aws sts get-caller-identity

                    echo "Logging in to Amazon ECR..."

                    aws ecr get-login-password \
                        --region "$AWS_REGION" | \
                        docker login \
                        --username AWS \
                        --password-stdin "$REGISTRY"

                    echo "Tagging Docker image..."

                    docker tag "$LOCAL_IMAGE" "$ECR_IMAGE"

                    echo "Pushing Docker image to ECR..."

                    docker push "$ECR_IMAGE"

                    echo "Successfully pushed image:"
                    echo "$ECR_IMAGE"
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! Docker image pushed to Amazon ECR.'
        }

        failure {
            echo 'Pipeline failed. Please check the Console Output.'
        }
    }
}
