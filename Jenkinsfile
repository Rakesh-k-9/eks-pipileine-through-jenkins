pipeline {

    agent any

    environment {

        AWS_REGION       = 'us-east-1'
        AWS_ACCOUNT_ID   = '786830914319'
        ECR_REPO_NAME    = 'rangesh_repository_for_springboot'
        EKS_CLUSTER_NAME = 'rangesh-eks-cluster'

        

        IMAGE_TAG       = "${BUILD_NUMBER}"
        ECR_REGISTRY    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        FULL_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
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
                echo '==== RUNNING TESTS ===='
                sh 'mvn test'
            }

            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('4. Package JAR') {
            steps {
                echo '==== PACKAGING APPLICATION ===='
                sh 'mvn package -DskipTests'
            }
        }

        stage('5. Build Docker Image') {
            steps {
                echo "==== BUILDING ${FULL_IMAGE_NAME}:${IMAGE_TAG} ===="

                sh """
                    docker build \
                      -t ${FULL_IMAGE_NAME}:${IMAGE_TAG} \
                      .
                """
            }
        }

        stage('6. Push Image to ECR') {
            steps {

                echo '==== PUSHING IMAGE TO ECR ===='

                withCredentials([
                    usernamePassword(
                        credentialsId: "${AWS_CREDENTIALS_ID}",
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {

                    sh """
                        aws ecr get-login-password \
                          --region ${AWS_REGION} | \
                        docker login \
                          --username AWS \
                          --password-stdin ${ECR_REGISTRY}

                        docker push ${FULL_IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('7. Deploy to EKS') {
            steps {

                echo '==== DEPLOYING TO EKS ===='

        {

                    sh """
                        aws eks update-kubeconfig \
                          --region ${AWS_REGION} \
                          --name ${EKS_CLUSTER_NAME}

                        sed -i "s|image: IMAGE_PLACEHOLDER|image: ${FULL_IMAGE_NAME}:${IMAGE_TAG}|g" \
                          k8s/deployment.yaml

                        kubectl apply -f k8s/namespace.yaml

                        kubectl apply -f k8s/deployment.yaml

                        kubectl apply -f k8s/service.yaml

                        kubectl apply -f k8s/ingress.yaml

                        kubectl rollout status \
                          deployment/springboot-app \
                          -n devops \
                          --timeout=180s
                    """
                }
            }
        }

        stage('8. Verify Deployment') {
            steps {

                sh """
                    kubectl get pods -n devops
                    kubectl get svc -n devops
                    kubectl get ingress -n devops
                """
            }
        }
    }

    post {

        always {

            echo '==== CLEANING DOCKER IMAGE ===='

            sh """
                docker rmi ${FULL_IMAGE_NAME}:${IMAGE_TAG} || true
            """
        }

        success {

            echo """
            SUCCESS:
            Build #${BUILD_NUMBER}
            Docker image pushed to ECR
            Application deployed to EKS
            Ingress configured
            """
        }

        failure {

            echo """
            FAILURE:
            Build #${BUILD_NUMBER} failed.
            Check Jenkins console output.
            """
        }
    }
}