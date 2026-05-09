pipeline {

    agent any

    environment {

        IMAGE_NAME = "ashwin0717/devops-monitoring-dashboard:${BUILD_NUMBER}"

        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')

        TF_DIR = "terraform"
    }

    stages {

        stage('Clone Repository') {

            steps {

                cleanWs()

                git(
                    branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/ashwin1707-cell/devops-monitoring-dashboard.git'
                )

                sh 'ls -la'
            }
        }

        stage('Terraform Deploy') {

            steps {

                dir("${TF_DIR}") {

                    sh '''
                    terraform init
                    terraform validate
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get EC2 IP') {

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

                sh 'sleep 60'
            }
        }

        stage('Build And Push Docker Image') {

            steps {

                sh 'docker system prune -af || true'

                sh 'docker build -t $IMAGE_NAME .'

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

                    docker push $IMAGE_NAME
                    '''
                }
            }
        }

        stage('Setup Kubernetes And Deploy') {

            steps {

                sh """
                sed -i 's|image:.*|image: ${IMAGE_NAME}|g' k8s/deployment.yaml
                """

                sshagent(credentials: ['ec2-key']) {

                    sh """
                    scp -o StrictHostKeyChecking=no \
                    -r k8s ec2-user@${EC2_IP}:/home/ec2-user/

                    ssh -o StrictHostKeyChecking=no ec2-user@${EC2_IP} '

                    sudo yum update -y

                    sudo yum install docker git conntrack -y

                    sudo systemctl enable docker
                    sudo systemctl start docker

                    curl -LO "https://dl.k8s.io/release/v1.35.1/bin/linux/amd64/kubectl"

                    chmod +x kubectl

                    sudo mv kubectl /usr/local/bin/

                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

                    chmod +x minikube-linux-amd64

                    sudo mv minikube-linux-amd64 /usr/local/bin/minikube

                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

                    docker system prune -af || true

                    minikube delete || true

                    minikube start \
                    --driver=docker \
                    --force \
                    --memory=2200 \
                    --cpus=2

                    mkdir -p \$HOME/.kube

                    sudo cp -f /root/.kube/config \$HOME/.kube/config || true

                    sudo chown -R ec2-user:ec2-user \$HOME/.kube

                    export KUBECONFIG=\$HOME/.kube/config

                    kubectl config use-context minikube

                    kubectl get nodes

                    kubectl apply -f /home/ec2-user/k8s/

                    kubectl rollout status deployment/python-app

                    kubectl get pods

                    kubectl get svc

                    kubectl create namespace monitoring || true

                    helm repo add prometheus-community \
                    https://prometheus-community.github.io/helm-charts

                    helm repo update

                    helm upgrade --install monitoring \
                    prometheus-community/kube-prometheus-stack \
                    --namespace monitoring \
                    --set alertmanager.enabled=false

                    kubectl get svc -n monitoring

                    echo "=============================="

                    echo "APPLICATION URL"

                    minikube service python-app-service --url

                    echo "=============================="

                    '

                    """
                }
            }
        }
    }

    post {

        success {

            echo 'PIPELINE SUCCESSFULLY COMPLETED'
        }

        failure {

            echo 'PIPELINE FAILED'
        }
    }
}
