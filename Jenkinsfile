pipeline {

    agent any

    environment {

        IMAGE_NAME = "ashwin0717/devops-monitoring-dashboard:${BUILD_NUMBER}"

        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')

        TF_DIR = "terraform"
    }

    stages {

        stage('Clone GitHub Repository') {

            steps {

                cleanWs()

                git(
                    branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/ashwin1707-cell/devops-monitoring-dashboard.git'
                )

                sh 'echo "Repository Cloned Successfully"'

                sh 'ls -la'
            }
        }

        stage('Terraform Init') {

            steps {

                dir("${TF_DIR}") {

                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {

            steps {

                dir("${TF_DIR}") {

                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Apply') {

            steps {

                dir("${TF_DIR}") {

                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Get EC2 Public IP') {

            steps {

                script {

                    env.EC2_IP = sh(
                        script: "cd terraform && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    echo "EC2 PUBLIC IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Wait For EC2') {

            steps {

                echo "Waiting for EC2 instance..."

                sh 'sleep 90'
            }
        }

        stage('Docker Cleanup') {

            steps {

                sh 'docker system prune -af || true'
            }
        }

        stage('Build Docker Image') {

            steps {

                sh 'docker build -t $IMAGE_NAME .'
            }
        }

        stage('Docker Login') {

            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {

                    sh '''
                    echo "$DOCKER_PASS" | docker login \
                    -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {

            steps {

                sh 'docker push $IMAGE_NAME'
            }
        }

        stage('Install Docker + Kubernetes + Helm') {

            steps {

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '

                    sudo yum update -y

                    if ! command -v docker &> /dev/null
                    then
                        sudo yum install docker -y
                        sudo systemctl enable docker
                        sudo systemctl start docker
                        sudo usermod -aG docker ec2-user
                    fi

                    if ! command -v kubectl &> /dev/null
                    then
                        curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

                        chmod +x kubectl

                        sudo mv kubectl /usr/local/bin/
                    fi

                    if ! command -v minikube &> /dev/null
                    then
                        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

                        sudo install minikube-linux-amd64 /usr/local/bin/minikube
                    fi

                    if ! command -v helm &> /dev/null
                    then
                        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                    fi

                    minikube delete || true

                    sudo minikube start \
                    --driver=docker \
                    --force \
                    --memory=4096 \
                    --cpus=2

                    kubectl get nodes

                    '
                    """
                }
            }
        }

        stage('Update Kubernetes Deployment') {

            steps {

                sh """
                sed -i 's|image:.*|image: ${IMAGE_NAME}|g' k8s/deployment.yaml
                """

                sh 'cat k8s/deployment.yaml'
            }
        }

        stage('Copy Kubernetes Files') {

            steps {

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    scp -o StrictHostKeyChecking=no \
                    -r k8s ec2-user@${EC2_IP}:/home/ec2-user/
                    """
                }
            }
        }

        stage('Deploy Application') {

            steps {

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '

                    kubectl apply -f /home/ec2-user/k8s/

                    kubectl rollout status deployment/python-app

                    kubectl get pods

                    kubectl get svc

                    '
                    """
                }
            }
        }

        stage('Install Monitoring Stack') {

            steps {

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '

                    kubectl create namespace monitoring || true

                    helm repo add prometheus-community \
                    https://prometheus-community.github.io/helm-charts

                    helm repo update

                    helm upgrade --install monitoring \
                    prometheus-community/kube-prometheus-stack \
                    --namespace monitoring \
                    --set alertmanager.enabled=false

                    kubectl patch svc monitoring-grafana \
                    -n monitoring \
                    -p "{\"spec\":{\"type\":\"NodePort\"}}"

                    kubectl patch svc monitoring-kube-prometheus-prometheus \
                    -n monitoring \
                    -p "{\"spec\":{\"type\":\"NodePort\"}}"

                    kubectl get svc -n monitoring

                    '
                    """
                }
            }
        }

        stage('Show URLs') {

            steps {

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '

                    echo "======================================"

                    echo "APPLICATION URL"

                    minikube service python-app-service --url

                    echo "======================================"

                    echo "MONITORING SERVICES"

                    kubectl get svc -n monitoring

                    echo "======================================"

                    '
                    """
                }
            }
        }
    }

    post {

        success {

            echo 'PIPELINE EXECUTED SUCCESSFULLY'
        }

        failure {

            echo 'PIPELINE FAILED'
        }
    }
}
