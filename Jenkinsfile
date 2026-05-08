pipeline {

    agent any

    environment {

        IMAGE_NAME = "ashwin0717/devops-monitoring-dashboard:latest"

        EC2_USER = "ec2-user"

        EC2_IP = "13.126.127.111"

        AWS_ACCESS_KEY_ID     = credentials('keyy')

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

        stage('Test SSH Connection') {

            steps {

                sshagent(credentials: ['ec2-user']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} '

                    echo "SSH CONNECTION SUCCESS"

                    hostname

                    '
                    """
                }
            }
        }

        stage('Install Docker + Kubernetes Tools') {

            steps {

                sshagent(credentials: ['ec2-user']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} '

                    sudo yum update -y

                    sudo yum install docker git -y

                    sudo systemctl enable docker

                    sudo systemctl start docker

                    sudo usermod -aG docker ec2-user

                    sudo chmod 666 /var/run/docker.sock

                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

                    sudo install minikube-linux-amd64 /usr/local/bin/minikube

                    curl -LO https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl

                    chmod +x kubectl

                    sudo mv kubectl /usr/local/bin/

                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

                    minikube delete || true

                    minikube start --driver=docker --force

                    kubectl get nodes

                    '
                    """
                }
            }
        }

        stage('Copy Kubernetes Files') {

            steps {

                sshagent(credentials: ['ec2-user']) {

                    sh """
                    scp -o StrictHostKeyChecking=no \
                    -r k8s ${EC2_USER}@${EC2_IP}:/home/ec2-user/
                    """
                }
            }
        }

        stage('Deploy Application + Monitoring') {

            steps {

                sshagent(credentials: ['ec2-user']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} '

                    export KUBECONFIG=/home/ec2-user/.kube/config

                    kubectl apply -f /home/ec2-user/k8s/deployment.yaml

                    kubectl apply -f /home/ec2-user/k8s/service.yaml

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

                    kubectl patch svc prometheus-server \
                    -n monitoring \
                    -p "{\"spec\":{\"type\":\"NodePort\"}}" || true

                    kubectl apply -f \
                    https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml || true

                    kubectl get pods -A

                    kubectl get svc -A

                    '
                    """
                }
            }
        }

        stage('Show Monitoring URLs') {

            steps {

                sshagent(credentials: ['ec2-user']) {

                    sh """
                    ssh -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_IP} '

                    echo "=============================="

                    echo "APPLICATION URL"

                    minikube service python-app-service --url

                    echo "=============================="

                    echo "GRAFANA NODEPORT"

                    kubectl get svc grafana -n monitoring

                    echo "=============================="

                    echo "PROMETHEUS NODEPORT"

                    kubectl get svc prometheus-server -n monitoring

                    echo "=============================="

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
