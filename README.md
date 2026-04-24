# 🧪 Lab Integrado — Módulos + Backend Remoto + Policy as Code

**Curso:** Arquitectura de Soluciones Multinube  
**Módulo 4, Sesión 3:** Automatización Avanzada y Policy as Code  
**Docente:** Aldo Trucios — UTEC Posgrado  
**Duración total:** ~90 minutos  
**Herramienta:** Terraform + OPA/Conftest

---

## 🎯 ¿Qué construirás en este laboratorio?

Un proyecto Terraform completo y realista con **tres capas integradas**:

```
┌─────────────────────────────────────────────────────────────┐
│  FASE 1 (20 min)  — Backend Remoto                          │
│  S3 (state) + DynamoDB (lock) + KMS (encriptación)          │
├─────────────────────────────────────────────────────────────┤
│  FASE 2 (35 min)  — Módulos Terraform                       │
│  module/vpc  +  module/security-group  +  module/ec2        │
│  Desplegados en el entorno "dev" consumiendo los módulos     │
├─────────────────────────────────────────────────────────────┤
│  FASE 3 (25 min)  — Policy as Code con OPA                  │
│  Políticas Rego que validan el plan antes del apply          │
│  conftest test → bloqueo si hay violaciones                  │
└─────────────────────────────────────────────────────────────┘
```

Al terminar habrás construido esta infraestructura en AWS, con el state guardado de forma segura en S3 y habiendo validado las políticas de gobernanza antes del despliegue:

```
                 ┌──────────────────────────────┐
                 │          AWS VPC              │
                 │  CIDR: 10.0.0.0/16           │
                 │                              │
                 │  ┌────────────────────────┐  │
                 │  │   Public Subnet        │  │
                 │  │   10.0.1.0/24          │  │
                 │  │                        │  │
                 │  │   ┌────────────────┐   │  │
                 │  │   │  EC2 t3.micro  │   │  │
                 │  │   │  + Security    │   │  │
                 │  │   │    Group       │   │  │
                 │  │   └────────────────┘   │  │
                 │  └────────────────────────┘  │
                 └──────────────────────────────┘
                          ▲  State guardado en:
                          │
                 ┌────────────────────┐
                 │  S3 Bucket (state) │
                 │  DynamoDB (lock)   │
                 │  KMS (cifrado)     │
                 └────────────────────┘
```

---

## 📁 Estructura del Repositorio

```
m04-s3-terraform-lab/
│
├── README.md                          ← Este archivo
│
├── backend-setup/                     ← FASE 1: Infraestructura del backend
│   ├── README.md
│   ├── main.tf                        ← S3 + DynamoDB + KMS
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── modules/                           ← FASE 2: Módulos reutilizables
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-group/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   └── dev/                           ← FASE 2: Entorno que consume los módulos
│       ├── README.md
│       ├── backend.tf                 ← Apunta al S3 creado en Fase 1
│       ├── main.tf                    ← Invoca los 3 módulos
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars
│
└── policy/                            ← FASE 3: Políticas OPA/Rego
    ├── README.md
    ├── aws_required_tags.rego         ← Política: tags obligatorios
    ├── aws_instance_type.rego         ← Política: tipos de instancia permitidos
    ├── aws_s3_encryption.rego         ← Política: S3 debe tener encriptación
    └── aws_open_ports.rego            ← Política: prohibir puertos abiertos al mundo
```

---

## ⚙️ Requisitos Previos

| Herramienta | Versión mínima | Instalación |
|-------------|----------------|-------------|
| Terraform | >= 1.5.0 | https://developer.hashicorp.com/terraform/install |
| AWS CLI | >= 2.13 | https://aws.amazon.com/cli/ |
| conftest | >= 0.45.0 | https://www.conftest.dev/install/ |
| OPA (opcional) | >= 0.60.0 | https://www.openpolicyagent.org/docs/latest/#1-download-opa |

```bash
# Verificar instalaciones
terraform version
aws sts get-caller-identity
conftest --version
```

---

## 🔐 Permisos IAM necesarios

Tu usuario/rol IAM debe tener permisos para:
- `s3:*` (crear bucket, habilitar versionado, políticas)
- `dynamodb:*` (crear tabla)
- `kms:*` (crear y usar llaves KMS)
- `ec2:*` (VPC, subnets, security groups, instancias)
- `iam:CreateRole`, `iam:AttachRolePolicy` (para instance profile)

> 💡 Para el laboratorio, el rol `AdministratorAccess` simplifica la configuración.

---

## 🗺️ Flujo del Laboratorio

```
[Fase 1] backend-setup/
    │  terraform init → plan → apply
    │  Resultado: S3 bucket + DynamoDB table + KMS key
    │
    ▼
[Fase 2] environments/dev/
    │  Editar backend.tf con outputs de Fase 1
    │  terraform init → plan → apply
    │  Resultado: VPC + EC2 + Security Group usando módulos
    │
    ▼
[Fase 3] policy/
       terraform plan -out=plan.tfplan
       terraform show -json plan.tfplan > plan.json
       conftest test plan.json -p ../policy/
       Resultado: validación de gobernanza ANTES del apply
```

---

> 🚀 **Comienza por:** [`backend-setup/README.md`](backend-setup/README.md)
