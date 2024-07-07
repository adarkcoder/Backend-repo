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
        stage('Checkout') {
            steps {
                git 'https://github.com/adarkcoder/Backend-repo.git'
            }
        }
        

        stage('Test') {
            steps {
                // Run Maven clean and test phases with error handling
                dir('FullStackApp') {
                    script {
                        def status = sh(script: 'mvn clean test', returnStatus: true)
                        if (status != 0) {
                            echo "Maven tests failed, but continuing the pipeline. "
                        }
                    }
                }
            }
        }

        stage('SonarQube - SAST') {
            steps {
                // Run SonarQube analysis after build and test
                dir('FullStackApp') {
                    script {
                        withSonarQubeEnv('Sonar') {
                            sh '''mvn sonar:sonar \
                                -Dsonar.projectKey=numeric-application \
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
            junit 'target/surefire-reports/*.xml'
            jacoco execPattern: 'target/jacoco.exec'
            cleanWs()
        }
    }
}
