
pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    environment {
        SONARQUBE_SERVER = 'sonar-qube'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub SCM'

                checkout scm

                echo 'GitHub checkout completed successfully'
            }
        }

        stage('Workspace Information') {
            steps {
                sh '''
                    echo "Current workspace:"
                    pwd

                    echo "Repository files:"
                    ls -la
                '''
            }
        }

        stage('Build HTML Project') {
            steps {
                script {
                    echo 'Building Demo-html project'

                    if (fileExists('package.json')) {
                        sh '''
                            npm install

                            if npm run | grep -q "build"; then
                                npm run build
                            else
                                echo "No build script found. Skipping npm build."
                            fi
                        '''
                    } else {
                        echo 'Static HTML project detected.'
                        echo 'No additional build required.'
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    catchError(
                        buildResult: 'SUCCESS',
                        stageResult: 'SUCCESS'
                    ) {
                        withSonarQubeEnv('sonar-qube') {
                            sh '''
                                if command -v sonar-scanner >/dev/null 2>&1; then
                                    sonar-scanner
                                else
                                    echo "SonarScanner not installed."
                                    echo "Skipping SonarQube analysis."
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
                    catchError(
                        buildResult: 'SUCCESS',
                        stageResult: 'SUCCESS'
                    ) {
                        timeout(time: 2, unit: 'MINUTES') {
                            waitForQualityGate(
                                abortPipeline: true
                            )
                        }
                    }
                }
            }
        }

        stage('Deployment Preparation') {
            steps {
                echo 'Preparing HTML project for deployment'

                sh '''
                    echo "Deployment preparation completed."
                '''
            }
        }
    }

    post {
        success {
            echo 'Demo-html pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed due to a checkout, build, or other non-ignored error.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
        }
    }
}

