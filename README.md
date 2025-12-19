# Terraform AWS EKS GitOps Landing Zone

## Overview

This repository demonstrates a **scalable AWS infrastructure** built with **Terraform**, following **modular design**, **GitOps principles**, and **cloud best practices**. It provisions a complete EKS-based platform with optional data services and CI/CD automation.

The project is intentionally structured to scale from a **simple EKS environment** to a **multi-account landing zone**
---

## Architecture Highlights

### High-Level Architecture (Conceptual)

```text
┌──────────────┐        ┌──────────────────┐
│ GitHub Repo  │ ─────▶ │ GitHub Actions   │
└──────────────┘        │ (Terraform CI)   │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │ AWS Infrastructure│
                         │  - VPC            │
                         │  - EKS            │
                         │  - IAM / IRSA     │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │ Argo CD           │
                         │ (GitOps Engine)  │
                         └────────┬─────────┘
                                  │
                                  ▼
                         ┌──────────────────┐
                         │ Kubernetes Apps  │
                         │ (Ingress / ALB) │
                         └──────────────────┘
```

* **Terraform** provisions AWS resources
* **GitHub Actions** enforces CI discipline
* **Argo CD** continuously reconciles Kubernetes state

---

## Repository Structure

```text
.
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── rds-aurora/        # Optional
│   └── dynamodb/          # Optional (app usage)
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── backend.tf
│       ├── providers.tf
│       └── terraform.tfvars
│
├── argocd/
│   ├── install.yaml
│   └── applications/
│       └── sample-app.yaml
│
├── k8s-apps/
│   └── nginx/
│       ├── deployment.yaml
│       └── service.yaml
│
├── .github/
│   └── workflows/
│       └── terraform.yml
│
├── README.md
└── .gitignore
```

---

## Terraform Backend

Terraform state is stored remotely to support collaboration and safety:

* **S3**: Stores the `terraform.tfstate` file
* **DynamoDB**: Provides state locking and consistency (not an application database)

```hcl
backend "s3" {
  bucket         = "b-eks-terraform-state-sandbox"
  key            = "eks/dev/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-locks"
}
```
---

## GitHub Actions, Terraform, and ArgoCD Deployment Workflow

This section outlines how GitHub Actions automate Terraform to provision EKS infrastructure, followed by manual installation and configuration of ArgoCD for GitOps application deployment.

GitHub Actions Terraform Automation

Initializes Terraform

Plans infrastructure changes

Applies changes on the main branch or protected branches

### Step 1: Configure kubectl to Access Your EKS Cluster

Replace <region> and <cluster-name> with your actual AWS region and EKS cluster name:

aws eks update-kubeconfig --region <region> --name <cluster-name>
kubectl cluster-info
kubectl get nodes

### Step 2: Install ArgoCD

Create the argocd namespace and deploy ArgoCD manifests:

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

### Step 3: Expose ArgoCD Server with a LoadBalancer

Change the ArgoCD server service type so you can access the UI via an external IP:

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

### Step 4: Retrieve Initial Admin Password

Get the auto-generated ArgoCD admin password:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

### Step 5: Access the ArgoCD UI

Fetch the external IP of the ArgoCD server:

kubectl get svc argocd-server -n argocd


Then open your browser to:

http://<EXTERNAL-IP>


Log in with:

Username: admin

Password: (retrieved in previous step)

Security Note: For production, consider restricting access via Ingress with authentication instead of a public LoadBalancer.

### Step 6: Configure ArgoCD for Automated Application Deployment

Log into the ArgoCD UI.

Click New App.

Enter the following application details:

Application Name: my-app

Project: default

Sync Policy: Automatic (optional)

Configure the source repository:

Repository URL: https://github.com/your-username/application

Revision: main

Path: / (or folder with Kubernetes manifests)

Set destination:

Cluster: https://kubernetes.default.svc

Namespace: default

Save the application.

ArgoCD will now monitor your Git repository and automatically deploy application changes to your EKS cluster, completing the GitOps workflow.

---

---

## Versions & Compatibility

| Component                    | Version |
| ---------------------------- | ------- |
| Terraform                    | >= 1.5  |
| AWS Provider                 | ~> 5.0  |
| EKS                          | 1.31    |
| Argo CD                      | 2.10.2  |
| AWS Load Balancer Controller | 2.7.x   |

---

## Prerequisites

Install the following tools before starting:

AWS CLI

aws --version

If not installed:

Windows: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

macOS: brew install awscli

Linux: use your package manager

Terraform

terraform version

Minimum recommended version: >= 1.5

Download from: https://developer.hashicorp.com/terraform/downloads

kubectl

kubectl version --client

Install guide: https://kubernetes.io/docs/tasks/tools/

## AWS Authentication

You can authenticate using IAM credentials or AWS SSO.

Option A: IAM Credentials

aws configure

Provide:

Access Key

Secret Key

Default region (e.g. us-east-1)

Option B: AWS SSO (Recommended for Enterprise)

aws configure sso

Follow the prompts and select the correct account and role.

Then export the profile:

export AWS_PROFILE=sandboxadm   # macOS/Linux
setx AWS_PROFILE sandboxadm     # Windows PowerShell 

---

## Prod vs Sandbox Differences

| Area            | Sandbox                | Production                           |
| --------------- | ---------------------- | ------------------------------------ |
| AWS Account     | Single account         | Multi-account (Organizations)        |
| Terraform Apply | Manual / CI            | CI only (protected branches)         |
| Networking      | Public subnets allowed | Private subnets + controlled ingress |
| Load Balancing  | Service `LoadBalancer` | ALB Ingress + WAF                    |
| IAM             | Broad roles            | Least privilege + SCPs               |
| Data Services   | Optional / minimal     | Aurora Multi-AZ, backups enabled     |
| Cost Controls   | Minimal                | Budgets, alerts, scaling policies    |

---

## Status

This repository represents a **sandbox-to-production progression** and is intentionally designed to be extended with additional security, compliance, and observability controls.
