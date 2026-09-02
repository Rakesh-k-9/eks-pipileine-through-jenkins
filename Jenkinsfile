pipeline {
    agent any

    environment {
        // AWS & ECR Configuration - Update these values for your AWS account
        AWS_REGION         = 'us-east-1'
        AWS_ACCOUNT_ID     = '123456789012' // Replace with your 12-digit AWS Account ID
        ECR_REPO_NAME      = 'devops-springboot-project'
        EKS_CLUSTER_NAME   = 'my-eks-cluster'
        
        // Jenkins Credentials ID configured in Jenkins Credentials Manager
        AWS_CREDENTIALS_ID = 'aws-credentials'
        
        // Dynamic build tagging
        IMAGE_TAG          = "${BUILD_NUMBER}"
        ECR_REGISTRY       = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME    = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
        timeout(time: 1, unit: 'HOURS')
        timestamps()
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo '==== PULLING CODE FROM GITHUB ===='
                checkout scm
            }
        }

        stage('2. Build Spring Boot') {
            steps {
                echo '==== BUILDING SPRING BOOT APPLICATION ===='
                sh 'mvn clean compile'
            }
        }

        stage('3. Run Tests') {
            steps {
                echo '==== RUNNING UNIT AND INTEGRATION TESTS ===='
                sh 'mvn test'
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('4. Package Jar') {
            steps {
                echo '==== PACKAGING APPLICATION JAR ===='
                sh 'mvn package -DskipTests'
            }
        }

        stage('5. Build Docker Image') {
            steps {
                echo "==== BUILDING DOCKER IMAGE: ${FULL_IMAGE_NAME}:${IMAGE_TAG} ===="
                sh "docker build -t ${FULL_IMAGE_NAME}:${IMAGE_TAG} -t ${FULL_IMAGE_NAME}:latest ."
            }
        }

        stage('6. Push Image to ECR') {
            steps {
                echo '==== AUTHENTICATING AND PUSHING DOCKER IMAGE TO AWS ECR ===='
                withCredentials([usernamePassword(credentialsId: "${AWS_CREDENTIALS_ID}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${FULL_IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('7. Deploy to EKS') {
            steps {
                echo '==== DEPLOYING APPLICATION TO AWS EKS ===='
                withCredentials([usernamePassword(credentialsId: "${AWS_CREDENTIALS_ID}", usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh """
                        # Update local kubeconfig for target EKS cluster
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}
                        
                        # Replace image tag placeholder in Kubernetes Deployment manifest
                        sed -i 's|image: IMAGE_PLACEHOLDER|image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}|g' k8s/deployment.yaml
                        
                        # Apply Deployment and Service manifests
                        kubectl apply -f k8s/deployment.yaml
                        kubectl apply -f k8s/service.yaml
                        
                        # Verify deployment rollout status
                        kubectl rollout status deployment/devops-springboot-project --timeout=180s
                    """
                }
            }
        }
    }

    post {
        always {
            echo '==== CLEANING UP LOCAL DOCKER IMAGES ===='
            sh """
                docker rmi ${FULL_IMAGE_NAME}:${IMAGE_TAG} || true
                docker rmi ${FULL_IMAGE_NAME}:latest || true
            """
        }
        success {
            echo "SUCCESS: Build #${BUILD_NUMBER} successfully built, tested, pushed to ECR, and deployed to EKS cluster standard!"
        }
        failure {
            echo "FAILURE: Build #${BUILD_NUMBER} failed during execution. Check console logs for details."
        }
    }
}
