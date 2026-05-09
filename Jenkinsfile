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

                    echo "EC2 IP: ${env.EC2_IP}"
                }
            }
        }

        stage('Wait For EC2') {

            steps {

                sh 'sleep 90'
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

        stage('Install Kubernetes Tools') {

            steps {

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '

                    sudo yum update -y

                    sudo yum install -y docker git conntrack

                    sudo systemctl enable docker
                    sudo systemctl start docker

                    sudo usermod -aG docker ec2-user

                    curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

                    chmod +x kubectl

                    sudo mv kubectl /usr/local/bin/

                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

                    chmod +x minikube-linux-amd64

                    sudo mv minikube-linux-amd64 /usr/local/bin/minikube

                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

                    sudo minikube delete || true

                    sudo rm -rf /root/.kube /root/.minikube

                    sudo minikube start \
                    --driver=docker \
                    --force \
                    --memory=2200mb \
                    --cpus=2

                    sudo mkdir -p /home/ec2-user/.kube

                    sudo cp -r /root/.kube/config /home/ec2-user/.kube/config

                    sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube

                    export KUBECONFIG=/home/ec2-user/.kube/config

                    kubectl config current-context

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

                    export KUBECONFIG=/home/ec2-user/.kube/config

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

                    export KUBECONFIG=/home/ec2-user/.kube/config

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

                    export KUBECONFIG=/home/ec2-user/.kube/config

                    echo "=========================="

                    echo "APPLICATION URL"

                    minikube service python-app-service --url

                    echo "=========================="

                    kubectl get svc -n monitoring

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
