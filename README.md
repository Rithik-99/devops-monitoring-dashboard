# DevOps Monitoring Dashboard

## Project Overview

This project demonstrates a complete DevOps CI/CD pipeline for deploying and monitoring a Java application using modern DevOps tools and AWS cloud infrastructure.

---

# Technologies Used

- Java
- Jenkins
- Docker
- Docker Hub
- Terraform
- AWS EC2
- Minikube
- Kubernetes
- Prometheus
- Grafana
- GitHub

---

# Project Architecture

Developer → GitHub → Jenkins → Docker → Docker Hub → Kubernetes (Minikube) → Monitoring

---

# Features

- Automated CI/CD Pipeline
- Docker Containerization
- Kubernetes Deployment
- Infrastructure Automation using Terraform
- Real-time Monitoring with Prometheus
- Dashboard Visualization using Grafana
- Cloud Deployment on AWS EC2

---

# Project Structure

```text
devops-monitoring-dashboard/
│
├── src/
├── Dockerfile
├── Jenkinsfile
├── terraform/
├── k8s/
├── monitoring/
├── screenshots/
└── README.md
```

---

# Jenkins Pipeline

The Jenkins pipeline automates:

1. Source Code Clone
2. Docker Image Build
3. Docker Image Push
4. Kubernetes Deployment
5. Monitoring Setup

---

# Docker Build Command

```bash
docker build -t devops-monitoring-dashboard .
```

---

# Docker Push Command

```bash
docker push your-dockerhub-username/devops-monitoring-dashboard
```

---

# Kubernetes Deployment

```bash
kubectl apply -f k8s/
```

---

# Terraform Infrastructure

Terraform is used to automate AWS EC2 infrastructure creation.

```bash
terraform init
terraform apply
```

---

# Monitoring Stack

## Prometheus
- Collects application and system metrics

## Grafana
- Visualizes monitoring dashboards
- Displays CPU, Memory, and Application metrics

---

# Screenshots

## Jenkins Pipeline
![Jenkins](screenshots/jenkins.png)


## Grafana Dashboard
![Grafana](screenshots/grafana.png)

## Prometheus Dashboard
![Prometheus](screenshots/prometheus.png)

## Application Output
![Application](screenshots/app.png)

---

# AWS Services Used

- EC2
- Security Groups
- IAM
- VPC

---

# Future Improvements

- Add SonarQube
- Add ArgoCD
- Add Helm Charts
- Multi-node Kubernetes Cluster

---

# Author

Ashwin P

---

# GitHub Repository

[devops-monitoring-dashboard Repository](https://github.com/ashwin1707-cell/devops-monitoring-dashboard?utm_source=chatgpt.com)