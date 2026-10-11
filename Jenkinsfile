pipeline {
    agent any

    parameters {
        string(name: 'AWS_REGION', defaultValue: 'us-west-2', description: 'AWS Region for EKS and ECR')
        string(name: 'CLUSTER_NAME', defaultValue: 'bbhealthapp-dev', description: 'EKS Cluster Name')
        string(name: 'NAMESPACE', defaultValue: 'bbhealthapp', description: 'Kubernetes Namespace')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'prod'], description: 'Deployment Environment')
    }

    environment {
        AWS_CREDENTIALS_ID = 'aws-credentials'
        AWS_DEFAULT_REGION = "${params.AWS_REGION}"
        CLUSTER_NAME       = "${params.CLUSTER_NAME}"
        NAMESPACE          = "${params.NAMESPACE}"
        IMAGE_TAG          = "${env.BUILD_NUMBER}"

        // ECR Repository Names matching Terraform / AWS setup
        FRONTEND_REPO      = 'bbhealthapp-frontend'
        MASTER_REPO        = 'bbhealthapp-master-service'
        REGISTER_REPO      = 'bbhealthapp-register-service'
        DOCUMENT_REPO      = 'bbhealthapp-document-service'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "=== Stage 1: Checkout Source Code ==="
                checkout scm
            }
        }

        stage('Configure AWS & ECR Login') {
            steps {
                echo "=== Stage 2: Configure AWS and Authenticate Docker with ECR ==="
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                    sh '''
                        set -e
                        echo "Configuring AWS region: ${AWS_DEFAULT_REGION}"
                        export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

                        # Dynamically retrieve AWS Account ID
                        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
                        ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
                        echo "ECR Registry: ${ECR_REGISTRY}"

                        # Save to workspace file for subsequent steps
                        echo "${ECR_REGISTRY}" > ecr_registry.txt

                        # Log in Docker to AWS ECR
                        aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                        echo "Successfully authenticated with Amazon ECR."
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                echo "=== Stage 3: Build Docker Images ==="
                script {
                    def ECR_REGISTRY = readFile('ecr_registry.txt').trim()
                    sh """
                        set -e
                        echo "Building Docker images with tag: ${IMAGE_TAG} and latest"

                        # Build Master Service
                        echo "Building Master Service..."
                        docker build -t ${ECR_REGISTRY}/${MASTER_REPO}:${IMAGE_TAG} \\
                                     -t ${ECR_REGISTRY}/${MASTER_REPO}:latest \\
                                     ./bbhealthapp-backend/bbhealthapp-api-master

                        # Build Register Service
                        echo "Building Register Service..."
                        docker build -t ${ECR_REGISTRY}/${REGISTER_REPO}:${IMAGE_TAG} \\
                                     -t ${ECR_REGISTRY}/${REGISTER_REPO}:latest \\
                                     ./bbhealthapp-backend/bbhealthapp-api-register

                        # Build Document Service
                        echo "Building Document Service..."
                        docker build -t ${ECR_REGISTRY}/${DOCUMENT_REPO}:${IMAGE_TAG} \\
                                     -t ${ECR_REGISTRY}/${DOCUMENT_REPO}:latest \\
                                     ./bbhealthapp-backend/bbhealthapp-api-document

                        # Build Frontend
                        echo "Building Frontend Service..."
                        docker build -t ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} \\
                                     -t ${ECR_REGISTRY}/${FRONTEND_REPO}:latest \\
                                     ./bbhealthapp-frontend
                    """
                }
            }
        }

        stage('Push Images to ECR') {
            steps {
                echo "=== Stage 4: Push Docker Images to Amazon ECR ==="
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                    script {
                        def ECR_REGISTRY = readFile('ecr_registry.txt').trim()
                        sh """
                            set -e
                            export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

                            echo "Pushing Master Service image..."
                            docker push ${ECR_REGISTRY}/${MASTER_REPO}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${MASTER_REPO}:latest

                            echo "Pushing Register Service image..."
                            docker push ${ECR_REGISTRY}/${REGISTER_REPO}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${REGISTER_REPO}:latest

                            echo "Pushing Document Service image..."
                            docker push ${ECR_REGISTRY}/${DOCUMENT_REPO}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${DOCUMENT_REPO}:latest

                            echo "Pushing Frontend image..."
                            docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
                            docker push ${ECR_REGISTRY}/${FRONTEND_REPO}:latest

                            echo "All container images pushed to ECR successfully."
                        """
                    }
                }
            }
        }

        stage('Deploy to EKS (Pure Kubectl - No Helm)') {
            steps {
                echo "=== Stage 5: Deploy Application to AWS EKS using Kubectl Manifests ==="
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                    script {
                        def ECR_REGISTRY = readFile('ecr_registry.txt').trim()
                        sh """
                            set -e
                            export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

                            echo "Updating kubeconfig for cluster: ${CLUSTER_NAME} in ${AWS_DEFAULT_REGION}..."
                            aws eks update-kubeconfig --region ${AWS_DEFAULT_REGION} --name ${CLUSTER_NAME}

                            echo "Applying base Kubernetes manifests (Namespace, ConfigMap, Secret, PVC)..."
                            kubectl apply -f k8s/namespace.yaml
                            kubectl apply -f k8s/configmap.yaml
                            kubectl apply -f k8s/secret.yaml
                            kubectl apply -f k8s/pvc.yaml

                            echo "Applying service deployments and ingress manifests..."
                            kubectl apply -f k8s/master-service-deployment.yaml
                            kubectl apply -f k8s/register-service-deployment.yaml
                            kubectl apply -f k8s/document-service-deployment.yaml
                            kubectl apply -f k8s/frontend-deployment.yaml
                            kubectl apply -f k8s/ingress.yaml

                            echo "Updating container images to newly pushed ECR build tag (${IMAGE_TAG})..."
                            kubectl set image deployment/master-service master-service=${ECR_REGISTRY}/${MASTER_REPO}:${IMAGE_TAG} -n ${NAMESPACE}
                            kubectl set image deployment/register-service register-service=${ECR_REGISTRY}/${REGISTER_REPO}:${IMAGE_TAG} -n ${NAMESPACE}
                            kubectl set image deployment/document-service document-service=${ECR_REGISTRY}/${DOCUMENT_REPO}:${IMAGE_TAG} -n ${NAMESPACE}
                            kubectl set image deployment/frontend frontend=${ECR_REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG} -n ${NAMESPACE}

                            echo "Awaiting deployment rollouts to complete..."
                            kubectl rollout status deployment/master-service -n ${NAMESPACE} --timeout=300s
                            kubectl rollout status deployment/register-service -n ${NAMESPACE} --timeout=300s
                            kubectl rollout status deployment/document-service -n ${NAMESPACE} --timeout=300s
                            kubectl rollout status deployment/frontend -n ${NAMESPACE} --timeout=300s

                            echo "All deployments successfully rolled out to EKS!"
                        """
                    }
                }
            }
        }

        stage('Verification & Health Check') {
            steps {
                echo "=== Stage 6: Verify Kubernetes Resources & Services ==="
                withCredentials([aws(credentialsId: env.AWS_CREDENTIALS_ID)]) {
                    sh '''
                        set -e
                        export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

                        echo "=== Pods in namespace ${NAMESPACE} ==="
                        kubectl get pods -n ${NAMESPACE} -o wide

                        echo "=== Services & Load Balancers ==="
                        kubectl get svc -n ${NAMESPACE}

                        echo "=== Ingress Details ==="
                        kubectl get ingress -n ${NAMESPACE}

                        echo "=== Persistent Volume Claims ==="
                        kubectl get pvc -n ${NAMESPACE}
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline run completed. Cleaning up workspace..."
            cleanWs()
        }
        success {
            echo "CI/CD Pipeline succeeded! BBHealthApp build #${BUILD_NUMBER} deployed successfully to EKS."
        }
        failure {
            echo "CI/CD Pipeline failed! Check stage console output logs for detailed errors."
        }
    }
}
