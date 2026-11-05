
pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 45, unit: 'MINUTES')
    }

    environment {
        AWS_REGION       = 'ap-south-1'
        AWS_ACCOUNT_ID   = 'YOUR_AWS_ACCOUNT_ID'
        ECR_REPOSITORY   = 'demo-html'
        ECS_CLUSTER      = 'YOUR_ECS_CLUSTER'
        ECS_SERVICE      = 'YOUR_ECS_SERVICE'

        IMAGE_NAME       = 'demo-html'
        SONAR_SERVER     = 'SonarQube'
        SONAR_SCANNER    = 'SonarQubeScanner'
    }

    stages {

        stage('GitHub Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        // SonarQube analysis: record failure, continue pipeline
        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    script {
                        def scannerHome = tool "${SONAR_SCANNER}"

                        withSonarQubeEnv("${SONAR_SERVER}") {
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=demo-html \
                                -Dsonar.sources=. \
                                -Dsonar.exclusions=.git/**,trivy-report.html
                            """
                        }
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                sh """
                    docker build \
                    -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                    -t ${IMAGE_NAME}:latest .
                """
            }
        }

        // Trivy generates report; vulnerabilities do not stop pipeline
        stage('Trivy Security Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    sh """
                        docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        -v trivy-cache:/root/.cache/ \
                        -v "\$WORKSPACE:/report" \
                        aquasec/trivy:latest image \
                        --image-src docker \
                        --scanners vuln \
                        --severity HIGH,CRITICAL \
                        --format template \
                        --template "@contrib/html.tpl" \
                        --output /report/trivy-report.html \
                        ${IMAGE_NAME}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Push to Amazon ECR') {
            steps {
                sh """
                    aws ecr get-login-password \
                    --region ${AWS_REGION} | \
                    docker login \
                    --username AWS \
                    --password-stdin \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                """

                sh """
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${BUILD_NUMBER}

                    docker push \
                    ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${BUILD_NUMBER}
                """
            }
        }

        stage('Deploy to Amazon ECS') {
            steps {
                sh """
                    aws ecs update-service \
                    --cluster ${ECS_CLUSTER} \
                    --service ${ECS_SERVICE} \
                    --force-new-deployment \
                    --region ${AWS_REGION}

                    aws ecs wait services-stable \
                    --cluster ${ECS_CLUSTER} \
                    --services ${ECS_SERVICE} \
                    --region ${AWS_REGION}
                """
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'trivy-report.html',
                             allowEmptyArchive: true
            echo 'Pipeline execution completed'
        }

        success {
            echo 'Pipeline completed successfully'
        }

        failure {
            echo 'A required pipeline stage failed. Check Console Output.'
        }
    }
}
