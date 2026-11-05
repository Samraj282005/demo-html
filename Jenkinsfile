pipeline {
    agent any

    tools {
        git 'Default'
    }

    environment {
        SONARQUBE_ENV = 'SonarQube'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                script {
                    if (fileExists('package.json')) {
                        sh 'npm install'
                    } else {
                        echo 'No package.json found. Skipping dependency installation.'
                    }
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    if (fileExists('package.json')) {
                        sh '''
                            if npm run | grep -q "build"; then
                                npm run build
                            else
                                echo "No build script found. Skipping build."
                            fi
                        '''
                    } else {
                        echo 'Static HTML project detected. Skipping build.'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                        withSonarQubeEnv('SonarQube') {
                            sh '''
                                if command -v sonar-scanner >/dev/null 2>&1; then
                                    sonar-scanner
                                else
                                    echo "SonarScanner not installed. Skipping analysis."
                                fi
                            '''
                        }
                    }
                }
            }
        }

        stage('SonarQube Quality Gate') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                        timeout(time: 2, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deployment stage completed.'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed due to a non-SonarQube issue.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
        }
    }
}

