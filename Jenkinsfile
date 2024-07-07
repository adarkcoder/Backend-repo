pipeline {
    agent any
    
    tools {
        maven 'Maven'
    }

    environment {
        AWS_CREDENTIALS_ID = 'aws-credentials-id'
        DOCKER_IMAGE = 'public.ecr.aws/e8n4i2w8/backend:latest'
        AWS_REGION = 'us-east-1'
    }

    stages {

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }


        stage('Checkout') {
            steps {
                git 'https://github.com/adarkcoder/Backend-repo.git'
            }
        }
        

        stage('Test') {
            steps {
                // Run Maven clean and test phases with error handling
                dir('FullStackApp') {
                    catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                        sh 'mvn clean test'
                    }
                }
            }
        }

        stage('SonarQube - SAST') {
            environment {
                scannerHome = tool 'sonar-scanner'
            }
            steps {
                // Run SonarQube analysis after build and test
                dir('FullStackApp') {
                    script {
                        withSonarQubeEnv('Sonar') {
                            sh '''${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=Backend-project \
                                -Dsonar.projectName=Backend-project \
                                -Dsonar.sources=src/main/java \
                                -Dsonar.tests=src/test/java/com/ \
                                -Dsonar.java.binaries=target/test-classes/ \
                                -Dsonar.junit.reportsPath=target/surefire-reports/**/*.xml \
                                -Dsonar.jacoco.reportsPath=target/coverage-reports/jacoco-ut.exec \
                                -Dsonar.host.url=http://sonarqube.default.svc.cluster.local/'''  
                        }
                    }
                }
                timeout(time: 2, unit: 'MINUTES') {
                    script {     
                        waitForQualityGate abortPipeline: true  
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build Docker image within FullStackApp directory
                dir('FullStackApp') {
                    script {
                        sh 'docker build -t ${DOCKER_IMAGE} .'
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                        aws ecr-public get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin public.ecr.aws/e8n4i2w8
                        docker push ${DOCKER_IMAGE}
                        '''
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                dir('Backend') {
                    script {
                        // Use kubeconfig to configure Kubernetes context
                        withKubeCredentials(kubectlCredentials: [[caCertificate: '', clusterName: '', contextName: '', credentialsId: 'kube-config', namespace: '', serverUrl: '']]) {
                            withCredentials([usernamePassword(credentialsId: AWS_CREDENTIALS_ID, usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                                sh 'kubectl apply -f .'
                                sh 'kubectl rollout restart deploy backend'
                            }
                        }
                    }
                }
             }
        }
    }

    post {
        always {
            dir('FullStackApp'){
                jacoco execPattern: 'target/jacoco.exec'
            }
        }
    }
}
