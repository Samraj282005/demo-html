
pipeline {
    agent any

    options {
        timestamps()
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    environment {
        SONAR_ANALYSIS_SUBMITTED = 'false'
    }

    stages {

        // 1. Checkout source code
        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub SCM'

                checkout scm

                echo 'GitHub checkout completed successfully'
            }
        }

        // 2. Display workspace information
        stage('Workspace Information') {
            steps {
                sh '''
                    echo "Current workspace:"
                    pwd

                    echo "Repository files:"
                    ls -la

                    echo "Git commit:"
                    git rev-parse --short HEAD
                '''
            }
        }

        // 3. Validate HTML project
        stage('Build HTML Project') {
            steps {
                script {
                    echo 'Building Demo-html project'

                    sh '''
                        set -eu

                        echo "Checking HTML files..."

                        if ! find . -maxdepth 1 -type f -name "*.html" | grep -q .; then
                            echo "ERROR: No HTML files found!"
                            exit 1
                        fi

                        echo "HTML files detected:"
                        find . -maxdepth 1 -type f -name "*.html" -print

                        echo "Static HTML project validation completed."
                    '''
                }
            }
        }

        // 4. SonarQube code analysis
        stage('SonarQube Analysis') {
            steps {
                catchError(
                    buildResult: 'SUCCESS',
                    stageResult: 'UNSTABLE',
                    message: 'SonarQube analysis failed. Continuing pipeline.'
                ) {
                    script {
                        echo 'Starting SonarQube code analysis'

                        def scannerHome = tool 'SonarScanner'

                        withSonarQubeEnv('SonarQube-Docker') {

                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=demo-html \
                                -Dsonar.projectName='Demo HTML' \
                                -Dsonar.projectVersion=1.0 \
                                -Dsonar.sources=. \
                                -Dsonar.sourceEncoding=UTF-8 \
                                -Dsonar.exclusions=.git/**,**/*.jpg,**/*.jpeg,**/*.png,**/*.webp
                            """
                        }

                        env.SONAR_ANALYSIS_SUBMITTED = 'true'

                        echo 'SonarQube analysis submitted successfully'
                    }
                }
            }
        }

        // 5. SonarQube Quality Gate
        stage('SonarQube Quality Gate') {
            when {
                expression {
                    env.SONAR_ANALYSIS_SUBMITTED == 'true'
                }
            }

            steps {
                catchError(
                    buildResult: 'SUCCESS',
                    stageResult: 'UNSTABLE',
                    message: 'SonarQube Quality Gate failed. Continuing pipeline.'
                ) {
                    timeout(time: 5, unit: 'MINUTES') {

                        echo 'Waiting for SonarQube Quality Gate result'

                        def qualityGate = waitForQualityGate(
                            abortPipeline: true
                        )

                        echo "SonarQube Quality Gate: ${qualityGate.status}"
                    }
                }
            }
        }

        // 6. Deployment preparation
        stage('Deployment Preparation') {
            steps {
                echo 'Preparing HTML project for deployment'

                sh '''
                    echo "Deployment preparation completed."
                    echo "HTML project is ready."
                '''
            }
        }
    }

    post {
        success {
            echo 'Demo-html pipeline completed successfully!'
        }

        unstable {
            echo 'Pipeline completed with warnings. Check SonarQube stages.'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins console output.'
        }

        always {
            echo 'Jenkins pipeline execution finished.'
            echo "Final build result: ${currentBuild.currentResult}"
        }
    }
}
