pipeline {

    agent any

    environment {

        IMAGE_NAME = "ashwin0717/devops-monitoring-dashboard:latest"

        EC2_USER = "ec2-user"

        AWS_ACCESS_KEY_ID = credentials('keyy')

        AWS_SECRET_ACCESS_KEY = credentials('seckey')
    }

    stages {

        stage('Git Clone') {

            steps {

                git branch: 'main',
                credentialsId: 'github-creds',
                url: 'https://github.com/ashwin1707-cell/devops-monitoring-dashboard.git'
            }
        }

        stage('Terraform Init') {

            steps {

                dir('terraform') {

                    sh 'terraform init -upgrade'
                }
            }
        }

        stage('Terraform Apply') {

            steps {

                dir('terraform') {

                    sh 'terraform apply -auto-approve'
                }
            }
        }

        stage('Build Docker Image') {

            steps {

                sh 'docker build -t $IMAGE_NAME python-app/'
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
                    echo $DOCKER_PASS | docker login \
                    -u $DOCKER_USER --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {

            steps {

                sh 'docker push $IMAGE_NAME'
            }
        }

        stage('Get EC2 Public IP') {

            steps {

                script {

                    env.EC2_IP = sh(

                        script: """
                        aws ec2 describe-instances \
                        --filters "Name=tag:Name,Values=k8s-monitoring-server" \
                        --query "Reservations[*].Instances[*].PublicIpAddress" \
                        --output text
                        """,

                        returnStdout: true

                    ).trim()

                    echo "EC2 Public IP: ${EC2_IP}"
                }
            }
        }

        stage('Install Docker + Kubernetes Tools') {

            steps {

                sshagent(['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ec2-user@$EC2_IP '

                    sudo yum update -y

                    sudo yum install docker -y

                    sudo systemctl start docker

                    sudo systemctl enable docker

                    sudo usermod -aG docker ec2-user

                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

                    sudo install minikube-linux-amd64 /usr/local/bin/minikube

                    curl -LO "https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

                    chmod +x kubectl

                    sudo mv kubectl /usr/local/bin/

                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

                    minikube start --driver=docker --force

                    '
                    """
                }
            }
        }

        stage('Copy Kubernetes Files') {

            steps {

                sshagent(['ec2-key']) {

                    sh """
                    scp -o StrictHostKeyChecking=no \
                    -r k8s ec2-user@$EC2_IP:/home/ec2-user/
                    """
                }
            }
        }

        stage('Deploy Application + Monitoring') {

            steps {

                sshagent(['ec2-key']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no \
                    ec2-user@$EC2_IP '

                    sleep 60

                    kubectl apply -f k8s/deployment.yaml

                    kubectl apply -f k8s/service.yaml

                    kubectl create namespace monitoring || true

                    helm repo add prometheus-community \
                    https://prometheus-community.github.io/helm-charts

                    helm repo update

                    helm install prometheus \
                    prometheus-community/prometheus \
                    -n monitoring || true

                    helm install grafana \
                    prometheus-community/grafana \
                    -n monitoring || true

                    kubectl patch svc grafana \
                    -n monitoring \
                    -p "{\"spec\":{\"type\":\"NodePort\"}}"

                    kubectl apply -f \
                    https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml || true

                    kubectl get pods -A

                    kubectl get svc -A

                    '
                    """
                }
            }
        }
    }

    post {

        success {

            echo 'Pipeline Executed Successfully!'
        }

        failure {

            echo 'Pipeline Failed!'
        }
    }
}
