pipeline {
    agent any

    environment {
        REGISTRY = 'docker.io/ajit189'  
        NAMESPACE = 'bbhealthapp'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    options {
        skipDefaultCheckout true
    }

    stages {
        stage('Pull stage') {
            steps {
                git branch: 'main', credentialsId: 'github-credentials', url: 'https://github.com/Ajit-Swami/BBHealthApp.git'
            }
        }

        stage('Build') {
            steps {
                echo "Building Docker images for BBHealthApp..."
                
                // Build Master Service
                dir('bbhealthapp-backend/bbhealthapp-api-master') {
                    sh "docker build -t ${REGISTRY}/bbhealthapp-master-service:${IMAGE_TAG} -t ${REGISTRY}/bbhealthapp-master-service:latest ."
                }
                
                // Build Register Service
                dir('bbhealthapp-backend/bbhealthapp-api-register') {
                    sh "docker build -t ${REGISTRY}/bbhealthapp-register-service:${IMAGE_TAG} -t ${REGISTRY}/bbhealthapp-register-service:latest ."
                }
                
                // Build Document Service
                dir('bbhealthapp-backend/bbhealthapp-api-document') {
                    sh "docker build -t ${REGISTRY}/bbhealthapp-document-service:${IMAGE_TAG} -t ${REGISTRY}/bbhealthapp-document-service:latest ."
                }
                
                // Build Frontend
                dir('bbhealthapp-frontend') {
                    sh "docker build -t ${REGISTRY}/bbhealthapp-frontend:${IMAGE_TAG} -t ${REGISTRY}/bbhealthapp-frontend:latest ."
                }
            }
        }

        stage('Push stage') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
                
                sh "docker push ${REGISTRY}/bbhealthapp-master-service:${IMAGE_TAG}"
                sh "docker push ${REGISTRY}/bbhealthapp-master-service:latest"
                sh "docker push ${REGISTRY}/bbhealthapp-register-service:${IMAGE_TAG}"
                sh "docker push ${REGISTRY}/bbhealthapp-register-service:latest"
                sh "docker push ${REGISTRY}/bbhealthapp-document-service:${IMAGE_TAG}"
                sh "docker push ${REGISTRY}/bbhealthapp-document-service:latest"
                sh "docker push ${REGISTRY}/bbhealthapp-frontend:${IMAGE_TAG}"
                sh "docker push ${REGISTRY}/bbhealthapp-frontend:latest"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying to Kubernetes cluster..."

                dir('k8s') {
                    // Update image references in deployment files
                    sh """
                        sed -i 's|image: .*bbhealthapp-master-service.*|image: ${REGISTRY}/bbhealthapp-master-service:${IMAGE_TAG}|g' master-service-deployment.yaml
                        sed -i 's|image: .*bbhealthapp-register-service.*|image: ${REGISTRY}/bbhealthapp-register-service:${IMAGE_TAG}|g' register-service-deployment.yaml
                        sed -i 's|image: .*bbhealthapp-document-service.*|image: ${REGISTRY}/bbhealthapp-document-service:${IMAGE_TAG}|g' document-service-deployment.yaml
                        sed -i 's|image: .*bbhealthapp-frontend.*|image: ${REGISTRY}/bbhealthapp-frontend:${IMAGE_TAG}|g' frontend-deployment.yaml
                        sed -i 's|imagePullPolicy: Never|imagePullPolicy: IfNotPresent|g' *.yaml
                    """

                    // Apply base configurations and persistent storage
                    sh 'kubectl apply -f namespace.yaml'
                    sh 'kubectl apply -f configmap.yaml'
                    sh 'kubectl apply -f secret.yaml'
                    sh 'kubectl apply -f pvc.yaml'

                    // Deploy backend and frontend microservices
                    sh 'kubectl apply -f master-service-deployment.yaml'
                    sh 'kubectl apply -f register-service-deployment.yaml'
                    sh 'kubectl apply -f document-service-deployment.yaml'
                    sh 'kubectl apply -f frontend-deployment.yaml'
                    sh 'kubectl apply -f ingress.yaml'

                    // Wait for deployments to be ready
                    sh "kubectl rollout status deployment/master-service -n ${NAMESPACE} --timeout=300s"
                    sh "kubectl rollout status deployment/register-service -n ${NAMESPACE} --timeout=300s"
                    sh "kubectl rollout status deployment/document-service -n ${NAMESPACE} --timeout=300s"
                    sh "kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=300s"
                }
            }
        }

        stage('Verify') {
            steps {
                echo "Verifying Kubernetes deployment..."
                sh "kubectl get pods -n ${NAMESPACE}"
                sh "kubectl get services -n ${NAMESPACE}"
                sh "kubectl get ingress -n ${NAMESPACE}"
            }
        }
    }

    post {
        success {
            echo "BBHealthApp deployment to Kubernetes completed successfully!"
        }
        failure {
            echo "BBHealthApp deployment failed. Check logs for details."
        }
    }
}
