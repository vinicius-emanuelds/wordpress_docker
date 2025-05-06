# **Wordpress com Docker + AWS**

**Objetivo Geral:**  
Implantar uma aplicação WordPress altamente disponível na AWS utilizando containers (Docker ou containerd), com banco de dados gerenciado (RDS MySQL), armazenamento de arquivos estáticos (EFS) e balanceamento de carga (Load Balancer).

**Resumo dos requisitos técnicos:**

1. **Instalação e configuração do Docker/containerd** em instâncias EC2.
2. **Deploy do WordPress** em containers:
   - Aplicação WordPress containerizada.
   - Banco de dados MySQL via Amazon RDS.
3. **Utilização do Amazon EFS**:
   - Para armazenar arquivos estáticos (wp-content/uploads, etc.).
4. **Configuração de Load Balancer AWS**:
   - Direcionar tráfego para instâncias EC2.
   - **Evitar exposição de IP público direto** nas instâncias WordPress.
5. **Provisionamento automático**:
   - Instalações e configurações via **user_data.sh** (script de inicialização da instância).
6. **Aplicação WordPress**:
   - Deve funcionar na porta **80 ou 8080**.
   - Acesso via Load Balancer.
7. **Versionamento via Git**:
   - Todo o projeto deve ser versionado em repositório Git.
8. **Documentação clara e detalhada**:
   - Explicação dos passos, decisões e arquitetura.

---

## 1. Criação da Infraestrutura AWS

### 1.1 VPC

### 1.2 Securtiy Groups
Para os Security Groups, vamos criar quatro grupos: um para a instância EC2, um para o RDS, um para o EFS e outro para o Load Balancer.

#### 1.2.3 Security Group do Load Balancer
🔒 Objetivo: Proteger o Load Balancer e permitir tráfego somente vindo da internet.

Inbound:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| HTTP  | TCP       | 80   | Anywhere - IPV4| Permitir todo tráfego vindo da internet |
| Custom TCP  | TCP       | 8080  | Anywhere - IPV4 | Permitir tráfego HTTP alternativo vindo da internet |

Outbound:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

#### 1.2.1 Security Group da EC2 (Instância WordPress)
🔒 Objetivo: Proteger a instância e permitir tráfego somente vindo do Load Balancer.

Inbound:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| HTTP  | TCP       | 80    | SG do Load Balancer | Permitir tráfego HTTP |
| Custom TCP  | TCP       | 8080  | SG do Load Balancer | Permitir tráfego HTTP alternativo |
| SSH   | TCP       | 22    | Seu IP | Permitir acesso SSH para administração |

Outbound:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

#### 1.2.2 Security Group do RDS (Banco de Dados MySQL)
🔒 Objetivo: Proteger o banco de dados e permitir tráfego somente vindo da instância EC2.

Inbound:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| MYSQL/Aurora  | TCP       | 3306   | SG da EC2 | Permitir tráfego MySQL |

Outbound:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |



#### 1.2.4 Security Group do EFS (Armazenamento de Arquivos)
🔒 Objetivo: Proteger o EFS e permitir tráfego somente vindo da instância EC2.

Inbound:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| NFS  | TCP       | 2049  | SG da EC2 | Permitir tráfego no EFS |

Outbound:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

1.3. Criação do EFS (Elastic File System)
- Criar um sistema de arquivos EFS na mesma VPC e sub-rede da instância EC2.

1.4. Criação do RDS (Banco de Dados MySQL)
- Criar um banco de dados MySQL RDS na mesma VPC e sub-rede da instância EC2.

