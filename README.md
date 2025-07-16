# WordPress com Docker + Infraestrutura AWS

## ÍNDICE
| Seção | Descrição |  
|-------|-----------|
| [Objetivos](#objetivos) | Metas do projeto |  
| [Requisitos Técnicos](#requisitos-técnicos) | Especificações técnicas do projeto |
| [Arquitetura Proposta](#arquitetura-proposta) | Topologia e componentes da infraestrutura |
| [Recursos Necessários](#recursos-necessários) | Pré-requisitos e configurações |  
| [Configuração AWS](#configurando-o-ambiente-aws) | VPC, Security Groups e EC2 |  
| [Serviços de Armazenamento](#criar-o-efs) | EFS e RDS |
| [Balanceamento de Carga](#criar-o-target-group-do-load-balancer) | Target Groups e Load Balancer |
| [Instalação do WordPress](#criando-a-aplicação-do-wordpress) | Template EC2 e Auto Scaling |
| [Testando a Aplicação](#testando-a-aplicação) | Verificação e troubleshooting |
| [Contribuição](#contribuição) | Como contribuir com o projeto |
| [Licença](#licença) | Licenciamento do projeto |

---

## OBJETIVOS

Implantar uma aplicação WordPress altamente disponível na AWS, utilizando:
- Containers Docker
- Banco de dados gerenciado (RDS MySQL)
- Armazenamento de arquivos estáticos (EFS)
- Balanceamento de carga (Load Balancer)
- Monitoramento e notificações via CloudWatch e SNS 

### Visão Geral da Arquitetura

Este projeto implementa uma aplicação WordPress escalável e altamente disponível na AWS, utilizando serviços gerenciados e conteinerização com Docker. A arquitetura foi projetada para eliminar pontos únicos de falha, garantir persistência de dados e permitir substituição automática de instâncias sem interrupções.

- **Docker** empacota o WordPress de forma portátil e consistente, facilitando a automação do provisionamento via scripts de inicialização.

- **Auto Scaling Group (ASG)** garante elasticidade, criando ou removendo instâncias conforme a carga.

- **Application Load Balancer (ALB)** distribui o tráfego entre múltiplas zonas de disponibilidade, assegurando tolerância a falhas.

- **Amazon RDS (MySQL)** centraliza e gerencia o banco de dados da aplicação.

- **Amazon EFS** fornece um sistema de arquivos compartilhado entre instâncias, mantendo uploads e configurações persistentes.

- **User Data** automatiza o provisionamento das instâncias, incluindo montagem do EFS, definição de variáveis de ambiente e inicialização do contêiner WordPress.

Esta abordagem é robusta e indicada para aplicações que precisam de alta disponibilidade desde o início do ciclo de vida, embora exija maior complexidade de configuração e dependência de automação confiável no boot das instâncias.

[⬆️ Voltar ao índice](#índice)

---

## REQUISITOS TÉCNICOS

1. **Instalação e configuração do Docker** em instâncias EC2.
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

[⬆️ Voltar ao índice](#índice)

---

## ARQUITETURA PROPOSTA

<div align="center">
    
![0 TOPOLOGIA](https://github.com/user-attachments/assets/a2c1a614-5df4-459b-8670-e6e8c55732d0)

</div>

### Componentes
- **Compute**: AWS EC2 com Docker
- **Database**: Amazon RDS MySQL
- **Storage**: Amazon EFS
- **Network**: VPC, Subnets e Security Groups
- **Load Balancing**: AWS Application Load Balancer

[⬆️ Voltar ao índice](#índice)

---

## RECURSOS NECESSÁRIOS

### Conta AWS ativa ([Criar conta gratuita](https://aws.amazon.com/pt/free/))

> A [Amazon Web Services (AWS)](https://aws.amazon.com/pt/what-is-aws/) é a plataforma de nuvem mais adotada e mais abrangente do mundo, oferecendo mais de 200 serviços completos de datacenters em todo o mundo. Milhões de clientes, incluindo as startups que crescem mais rápido, as maiores empresas e os maiores órgãos governamentais, estão usando a AWS para reduzir custos, ganhar agilidade e inovar mais rapidamente.

### AWS CLI instalado
> [Clique aqui](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) para acessar a documentação oficial.

### Terminal com acesso SSH (Linux/Mac/WSL)

### Conhecimentos básicos em:
- AWS
- Docker
- Redes
- Linux

[⬆️ Voltar ao índice](#índice)

---

## CONFIGURANDO O AMBIENTE AWS

### Criar a VPC
Agora vamos criar uma VPC na AWS com 4 sub-redes (2 privadas e 2 públicas), com um internet gateway conectado à uma das sub-redes públicas.

1. **Acesse o console AWS** - Na barra de busca, selecione VPC.
   
<div align="center">
   
![1 VPC - DASHB](https://github.com/user-attachments/assets/5f711d5b-3050-4262-8011-a679e76fc148)


</div>

2. **Inicie a criação** - Clique em *Create VPC*.
   
<div align="center">
   
![1 VPC - CREATE](https://github.com/user-attachments/assets/10b6b3da-6148-4148-b0a5-4921ac59c522)


</div>

3. **Configure a VPC** - Aplique as seguintes configurações e clique em *Create VPC*.
   
<div align="center">
   
![1 VPC - SETTINGS](https://github.com/user-attachments/assets/40b48d17-9f34-48b6-b7da-06098be59f32)


<br>

![1 VPC - CREATE](https://github.com/user-attachments/assets/0de83dae-239a-45c5-8414-15165586d9da)


</div>

4. **Verifique a criação** - O fluxo deve ser similar a este:
   
<div align="center">
   
![1 VPC - RESOURCE MAP](https://github.com/user-attachments/assets/7bc93873-eea6-4746-a4ef-4073b6c51061)


</div>

[⬆️ Voltar ao índice](#índice)

---

### Criando Security Groups
Para este projeto, nós teremos 04 Security Groups, um para cada serviço.

1. **Acesse EC2** - No dashboard, clique em EC2. Na seção à esquerda, selecione *Security Groups*.
   
<div align="center">
   
![2 SG - SELECIONAR](https://github.com/user-attachments/assets/7565521e-b16e-45ad-af2b-7ba301d6c540)


</div>

2. **Inicie a criação** - Clique em *Create Security Group*.
   
<div align="center">
   
![2 SG - CREATE](https://github.com/user-attachments/assets/c864cfe8-784d-4770-b0cc-e7529cfddfc9)


</div>

3. **Configure o Security Group** - Escolha um nome, faça uma descrição e selecione a VPC.
   
<div align="center">
   
![2 SG - BASIC DETAILS](https://github.com/user-attachments/assets/f3ed0fd4-ef74-499d-96bf-b486b3042c42)


</div>

Agora, para cada Security Group, aplique as regras de entrada e saída conforme abaixo:

#### Security Group do Load Balancer
Objetivo: Proteger o Load Balancer e permitir tráfego somente vindo da internet.

***Inbound***:

| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| HTTP  | TCP       | 80   | Anywhere - IPV4| Permitir todo tráfego vindo da internet |
| Custom TCP  | TCP       | 8080  | Anywhere - IPV4 | Permitir tráfego HTTP alternativo vindo da internet |

<br>

***Outbound***:

| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

<br>

#### Security Group da EC2 (Instância WordPress)
Objetivo: Proteger a instância e permitir tráfego somente vindo do Load Balancer.

***Inbound***:

| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| HTTP  | TCP       | 80    | SG do Load Balancer | Permitir tráfego HTTP |
| Custom TCP  | TCP       | 8080  | SG do Load Balancer | Permitir tráfego HTTP alternativo |
| SSH   | TCP       | 22    | Seu IP | Permitir acesso SSH para administração |

<br>

***Outbound***:

| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

<br>

#### Security Group do RDS (Banco de Dados MySQL)
Objetivo: Proteger o banco de dados e permitir tráfego somente vindo da instância EC2.

***Inbound***:

| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| MYSQL/Aurora  | TCP       | 3306   | SG da EC2 | Permitir tráfego MySQL |

<br>

***Outbound***:

| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

<br>

#### Security Group do EFS (Armazenamento de Arquivos)
Objetivo: Proteger o EFS e permitir tráfego somente vindo da instância EC2.

***Inbound***:

| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| NFS  | TCP       | 2049  | SG da EC2 | Permitir tráfego no EFS |

<br>

***Outbound***:

| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

<br>

4. **Verifique os Security Groups** - Após a criação, seu dashboard deve estar similar a:

<div align="center">
   
![2 SG - REVIEW](https://github.com/user-attachments/assets/5da9b9c1-8959-4eae-bb90-450cee652b9b)


</div>

[⬆️ Voltar ao índice](#índice)

---

## CRIAR O EFS

1. **Acesse o serviço EFS** - Na barra de pesquisa, digite EFS e clique na primeira opção. Em seguida, clique em *Create file system*.
   
<div align="center">
   
![3 EFS - SELECIONAR](https://github.com/user-attachments/assets/2df74e2d-7341-4e85-83ef-aa4c567059dd)

<br>

![3 EFS - CREATE](https://github.com/user-attachments/assets/6013d2e7-5db9-4c11-87df-1ce027772d71)


</div>

2. **Configure o EFS** - Escolha um nome, selecione a *VPC* e clique em *Customize*.
   
<div align="center">
   
![3 EFS - CUSTOMIZE](https://github.com/user-attachments/assets/4dbcc6db-c5cf-4434-bad3-576da1be8dc2)


</div>

3. **Aplique as configurações** - Configure conforme as imagens abaixo e clique em *Next*.
   
> *As configurações que não estão indicadas ou alteradas permanecem como padrão*
   
<div align="center">
   
![3 EFS - GENERAL](https://github.com/user-attachments/assets/b002119b-7f26-4799-b8bf-e712962f128c)


<br>

![3 EFS - PERFORMANCE](https://github.com/user-attachments/assets/5de820d1-7ef6-41ae-a715-e0cf0b5ee6f8)

<br>

![3 EFS - NETWORK](https://github.com/user-attachments/assets/efaae4cc-246a-45ff-805b-1c136af4568d)


<br>

![3 EFS - POLICY](https://github.com/user-attachments/assets/27188b86-e6ad-47bf-a685-e54c8e4d2b3b)


</div>

4. **Finalize a criação** - Na última tela, revise as configurações e clique em *Create*.

## CRIAR O RDS

1. **Acesse o serviço RDS** - Na barra de pesquisa, digite RDS e clique na primeira opção. Em seguida, clique em *Create database*.
   
<div align="center">
   
![4 RDS - SELECIONAR](https://github.com/user-attachments/assets/5400ad5a-a235-49cb-ab17-66ec9f875bb1)


<br>

![4 RDS - CREATE](https://github.com/user-attachments/assets/9b6aa5d7-c927-4e6c-9261-fedc20010b9c)


</div>

2. **Configure o banco de dados** - Aplique as configurações conforme as imagens abaixo, clicando em *Next* em cada etapa.
   
> *As configurações que não estão indicadas ou alteradas permanecem como padrão*
   
<div align="center">
   
![4 RDS - MYSQL](https://github.com/user-attachments/assets/385d917e-9b4e-4864-ac73-f0d5866fa310)


<br>

![4 RDS - FREE TIER](https://github.com/user-attachments/assets/9b450a6a-c166-46ea-a136-b954f8b08537)


<br>

![4 RDS - AVAILABILITY](https://github.com/user-attachments/assets/2e42186e-a9c6-4123-bd87-0f4a5dfe06ab)


<br>

![4 RDS - CREDENTIALS](https://github.com/user-attachments/assets/8a00ed18-6dae-40eb-a4a7-8a37f736acd3)


<br>

![4 RDS - INSTANCE](https://github.com/user-attachments/assets/e8b01c35-d2d2-468a-8594-42ee0c6a8fb2)


<br>

![4 RDS - CONECTIVITY](https://github.com/user-attachments/assets/b06e1ad5-099e-4f96-a6a9-632d237a87a6)

<br>

![4 RDS - VPC](https://github.com/user-attachments/assets/ab0fdf02-62d4-42b6-9f94-69ce11ffa7d0)


<br>

![4 RDS - ADDITIONAL](https://github.com/user-attachments/assets/0f12c131-5296-4c9b-bc13-a7264779f248)


</div>

3. **Finalize a criação** - Revise os dados e clique em *Create database*.

4. **Obtenha o endpoint** - Após a criação, clique em *View database* e copie o *endpoint* do banco de dados para uso posterior.
   
<div align="center">
   
![4 RDS - REVIEW](https://github.com/user-attachments/assets/c9f02de7-a619-4340-8301-fc598d6cc4ab)


</div>

[⬆️ Voltar ao índice](#índice)

---

### CRIAR O TARGET GROUP DO LOAD BALANCER

1. **Acesse Target Groups** - Na barra de pesquisa, digite *Target Groups* e clique em *"Target Groups - EC2 Feature"*. Em seguida, clique em *Create target group*.
   
<div align="center">
   
![5 TG - SELECIONAR](https://github.com/user-attachments/assets/c797cd38-d488-47bc-8170-841e229906cb)


<br>

![5 TG - CREATE](https://github.com/user-attachments/assets/3c2de51e-40a1-45da-bb8c-f36643a9f8ad)


</div>

2. **Configure o Target Group** - Aplique as configurações conforme as imagens abaixo e clique em *Next*.
   
> *As configurações que não estão indicadas ou alteradas permanecem como padrão*
   
<div align="center">
   
![5 TG - BASIC](https://github.com/user-attachments/assets/77b34bfe-af17-46fb-a3b7-d0c3281a5546)


<br>

![5 TG - CONFIGURATIONS](https://github.com/user-attachments/assets/c9d24905-21c0-4eb7-8ede-a89fbdea0513)


<br>

![5 TG - HEALTH](https://github.com/user-attachments/assets/8157c0cd-168e-4568-a681-c80032d27375)

   
</div>

> Para este projeto, o path do health check será `/readme.html`, página padrão criada automaticamente ao instalarmos o WordPress.

3. **Finalize a criação** - Não adicione instâncias neste momento e clique em *Create target group*.
   
<div align="center">
   
![5 TG - CREATE](https://github.com/user-attachments/assets/ff20fa64-e7f6-4fb8-afe5-7e3450e54343)


</div>

4. **Edite atributos do Target Group** - Clique no target group criado e depois em *Edit*.
   
<div align="center">
   
![5 TG - EDIT](https://github.com/user-attachments/assets/1a54037a-de75-4d16-b08d-e472556106d1)


</div>

5. **Ajuste as configurações** - Aplique as configurações conforme a imagem abaixo e clique em *Save changes*.
   
<div align="center">
   
![5 TG - COOKIES](https://github.com/user-attachments/assets/9e76b01d-7626-44d2-bff6-5a64306c2c51)


</div>

## CRIAR O LOAD BALANCER

1. **Acesse Load Balancers** - Na barra de pesquisa, digite *Load Balancers* e clique em *"Load Balancers - EC2 Feature"*. Em seguida, clique em *Create Load Balancer*.
   
<div align="center">
   
![6 LB - SELECIONAR](https://github.com/user-attachments/assets/bef136f4-cd91-4dd0-9de5-c6c1861bfa74)


<br>

![6 LB - CREATE](https://github.com/user-attachments/assets/69b6ca22-765e-4b8e-9006-e69f88906f5d)


</div>

2. **Escolha o tipo** - Selecione *Application Load Balancer* e clique em *Create*.
   
<div align="center">
   
![6 LB - TYPE](https://github.com/user-attachments/assets/b5eadd4e-414b-455c-827d-bab85a571819)


</div>

3. **Configure o Load Balancer** - Aplique as configurações conforme as imagens abaixo e clique em *Next*.
   
> *As configurações que não estão indicadas ou alteradas permanecem como padrão*
   
<div align="center">
   
![6 LB - BASIC](https://github.com/user-attachments/assets/983b70a0-b6d0-4c78-bfcd-d88e634141cf)


<br>

![6 LB - NETWORK](https://github.com/user-attachments/assets/ac353250-5db0-4372-9d2c-088ee2b16630)


<br>

![6 LB - SECURITY](https://github.com/user-attachments/assets/d74f620b-01ba-42e9-a4cb-c357f28ab25e)


<br>

![6 LB - CREATE LB](https://github.com/user-attachments/assets/3c4bc0c8-2c57-4af5-b9aa-1cafeb35f533)


</div>

[⬆️ Voltar ao índice](#índice)

---

## CRIANDO A APLICAÇÃO DO WORDPRESS

### CRIAR UM TEMPLATE DA EC2

1. **Acesse Launch Templates** - Na barra de pesquisa, digite *Launch Templates* e clique na primeira opção. Em seguida, clique em *Launch instance*.
   
<div align="center">
   
![7 LT - SELECIONAR](https://github.com/user-attachments/assets/079ff1d5-ddeb-40ea-85e5-a30db7bbd33b)


<br>

![7 LT - CREATE](https://github.com/user-attachments/assets/9888e9d3-1fa6-4bb3-ac98-a1051ab331a5)


</div>

2. **Configure o template** - Aplique as configurações conforme as imagens abaixo e clique em *Next*.
   
> *As configurações que não estão indicadas ou alteradas permanecem como padrão*
   
<div align="center">
   
![7 LT - NAME](https://github.com/user-attachments/assets/90500aa9-b10f-4c54-9691-0e5596f9769a)

<br>

![7 LT - AMI](https://github.com/user-attachments/assets/54f0f373-9fc9-4845-924a-dceecb08528e)


<br>

![7 LT - INSTANCE](https://github.com/user-attachments/assets/31bba68d-929f-420f-9c1c-7b56b69d6cea)


</div>

> **Configurando a chave de acesso**
> 
> Se precisar criar a chave, clique em *Create new key pair* e siga as instruções.
> 
> <div align="center">
>   
> ![7 LT - KEY PAIR](https://github.com/user-attachments/assets/cd4af543-5566-4147-9c0f-fcb432ca1dac)
>
>
> </div>
>
> Após a criação, a chave será baixada automaticamente para sua máquina. É importante mantê-la disponível no momento da conexão com a instância. Se estiver usando o Windows com WSL, utilize o comando abaixo para copiar para a máquina Linux. Se já estiver utilizando Linux, pule esta etapa.
> ```cmd
> scp \caminho_para_chave\[SUA_CHAVE].pem [USUÁRIO]@[IP_LINUX]:/home/[USUÁRIO]
> ```
>
> Já no Linux, aplique as permissões para a chave:
> ```bash
> chmod 400 [SUA_CHAVE].pem
> ```

<div align="center">
   
![7 LT - NETWORK](https://github.com/user-attachments/assets/47291720-35bb-451b-b4a9-353753d42f0d)


<br>

![7 LT - STORAGE](https://github.com/user-attachments/assets/9b45158d-e39a-45dd-99bd-ea7105410fea)


</div>

3. **Configure o User Data** - Na seção *Advanced details*, cole o script abaixo no campo *User data* e clique em *Create launch template*.
   
> Este script irá instalar o WordPress e configurar o Docker na instância. Ele será executado automaticamente quando a instância for criada.

```bash
#!/bin/bash -xe
set -e
trap 'echo "Erro na linha $LINENO. Comando: $BASH_COMMAND" >> /var/log/user-data-error.log' ERR

# Força IPv4
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# Aguarda rede estar funcional
while ! ping -c1 8.8.8.8 &>/dev/null; do
    echo "Aguardando rede..."
    sleep 2
done
# VARIÁVEIS DE AMBIENTE
export DB_HOST="[ENDPOINT DO RDS]"
export DB_USER="[USUÁRIO MASTER CRIADO NO RDS]"
export DB_PASSWORD="[SENHA CRIADA NO RDS]"
export DB_NAME="[NOME ESCOLHIDO PARA O PRIMEIRO DATABASE]"
export DB_ROOT_PASSWORD="[ESCOLHA UMA SENHA ROOT]"

# DOCKER
apt-get update -y
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    nfs-common

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker

usermod -aG docker ubuntu

# EFS
mkdir -p /mnt/wordpress
if mountpoint -q /mnt/wordpress; then
    echo "EFS já montado"
else
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport [ENDPOINT DO EFS]:/ /mnt/wordpress
fi

mkdir -p /mnt/wordpress/wp-content

# DOCKER COMPOSE
cat > /home/ubuntu/compose.yml <<'EOF'
services:
  wordpress:
    image: wordpress:latest
    restart: always
    ports:
      - 80:80
    environment:
      WORDPRESS_DB_HOST: ${DB_HOST}
      WORDPRESS_DB_USER: ${DB_USER}
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: ${DB_NAME}
    volumes:
      - /mnt/wordpress/wp-content:/var/www/html/wp-content
      - /mnt/wordpress/wp-config:/var/www/html/wp-config
    network_mode: host
    
networks:
  wordpress:
    driver: bridge
EOF

# SUBIR O COMPOSE
cd /home/ubuntu
docker compose up -d

echo "Instalação concluída em $(date)" >> /var/log/user-data-complete.log
```

> **ATENÇÃO**: Não esqueça de substituir os valores entre colchetes `[]` pelas informações corretas.

<div align="center">
   
![7 LT - USERDATA](https://github.com/user-attachments/assets/b25c0094-a0e5-4c68-b2c4-31b0c4b033a1)


</div>

[⬆️ Voltar ao índice](#índice)

---

## CRIAR O AUTO SCALING

1. **Acesse Auto Scaling Groups** - Na barra de pesquisa, digite *Auto Scaling Groups* e clique na primeira opção. Em seguida, clique em *Create Auto Scaling group*.
   
<div align="center">
   
![8 ASG - SELECIONAR](https://github.com/user-attachments/assets/5db49a59-f8a5-4e5a-a553-aff2995410b2)


<br>

![8 ASG - CREATE](https://github.com/user-attachments/assets/3dd81ac7-f9c0-4961-b24c-4d653a94205a)


</div>

2. **Configure o Auto Scaling Group** - Aplique as configurações conforme as imagens abaixo e clique em *Next*.
   
> *As configurações que não estão indicadas ou alteradas permanecem como padrão*
   
<div align="center">
   
![8 ASG - NAME](https://github.com/user-attachments/assets/3d238db5-92fb-4bd7-82fb-b25637d8ff8d)

<br>

![8 ASG - VERSION](https://github.com/user-attachments/assets/547cefd6-31f1-4385-947a-4fce35a914a6)

<br>

![8 ASG - NETWORK](https://github.com/user-attachments/assets/ad87a98c-8ba5-46da-a7a2-15a50f63a031)


<br>

![8 ASG - INTEGRATE](https://github.com/user-attachments/assets/f1867db0-a96e-44eb-ba54-c6c2bcca84ec)


<br>

![8 ASG - POLICY](https://github.com/user-attachments/assets/4306b752-98d0-4d1a-bb1f-a9235bebedbf)


<br>

![8 ASG - HEALTH](https://github.com/user-attachments/assets/34187cff-7c8d-4cbe-aa2a-24a6a3b9bf08)


<br>

![8 ASG - SCALING](https://github.com/user-attachments/assets/40f65e0f-60cd-4d46-a96b-95391632b654)


<br>

![8 ASG - TRACKING](https://github.com/user-attachments/assets/508fc28c-3a65-4b68-a16a-03586e82b6ae)


</div>
   
> Escolha a *Scaling Policy* de acordo com seu projeto. Para este projeto, escolhemos a *Target tracking scaling policy*, utilizando o *metric type* **Average CPU utilization**, que irá aumentar ou diminuir a quantidade de instâncias de acordo com a utilização média da CPU.

3. **Finalize a criação** - Após finalizar, clique em *Create Auto Scaling group*. Se tudo estiver correto, seu dashboard de instâncias deve estar assim:
   
<div align="center">
   
![8 ASG - INSTÂNCIAS](https://github.com/user-attachments/assets/bde0eaaa-47a0-4f1b-9575-502e2875d43d)


</div>

[⬆️ Voltar ao índice](#índice)

---

## TESTANDO A APLICAÇÃO

1. **Acesse o Load Balancer** - Após alguns minutos, seu Load Balancer deve estar ativo. Busque na barra de pesquisa por Load Balancer e clique na opção.

2. **Obtenha o DNS do Load Balancer** - Selecione o Load Balancer criado e copie o *DNS name*.

3. **Acesse o WordPress** - Cole o DNS no navegador e verifique se a página do WordPress está carregando. Caso não esteja, aguarde alguns minutos e tente novamente.

4. **Configure o WordPress** - Se tudo estiver correto, você verá a tela de instalação do WordPress. Siga as instruções para finalizar a instalação.
   
<div align="center">
   
![9 TESTE - LINGUA](https://github.com/user-attachments/assets/17757904-d12b-48a9-84b5-be881d82ccec)


<br>

![9 TESTE - CONFIGURAÇÃO](https://github.com/user-attachments/assets/a1a38e7c-0c15-4ed6-82f6-096150e7a644)


</div>

5. **Faça login** - Após a instalação, você verá a tela de boas-vindas do WordPress. Clique em *Log in* para acessar o painel administrativo.
   
<div align="center">
   
![9 TESTE - LOGIN](https://github.com/user-attachments/assets/3c0819bc-72b9-4d85-9912-02f23ac3cbff)

</div>

6. **Acesse o dashboard** - Após logar, você verá o painel administrativo do WordPress. Aqui, você pode gerenciar seu site, adicionar plugins, temas e muito mais.
   
<div align="center">
   
![9 TESTE - PÁGINA INICIAL](https://github.com/user-attachments/assets/c321aa29-4ecc-4006-998c-237544c492db)


</div>

### TESTANDO A PERSISTÊNCIA DOS ARQUIVOS

1. **Faça upload de uma imagem** - Acesse o painel administrativo do WordPress e vá em *Mídia* > *Biblioteca*. Faça o upload de uma imagem qualquer.
   
<div align="center">
   
![9 TESTE - UP](https://github.com/user-attachments/assets/6656e025-0313-4fd3-a720-bf15b5165ecd)


</div>

2. **Verifique o EFS** - Após o upload, acesse o EFS e verifique se a imagem foi salva na pasta `/mnt/wordpress/wp-content/uploads`.

3. **Teste a persistência** - Delete as instâncias EC2 e aguarde alguns minutos até que novas instâncias sejam criadas pelo Auto Scaling Group.

4. **Verifique a persistência** - Acesse o painel administrativo do WordPress novamente (através do DNS do Load Balancer) e vá em *Mídia* > *Biblioteca*. Verifique se a imagem ainda está disponível.
   
<div align="center">
   
![9 TESTE - VERIFICAR](https://github.com/user-attachments/assets/83ec9696-86fe-494e-8c5c-e7e3b624bce0)


</div>

5. **Confirme o sucesso** - Se tudo estiver correto, você verá a imagem que fez o upload anteriormente.

### Problemas Comuns

| Problema | Possível Causa | Solução |
|----------|----------------|---------|
| WordPress não inicia | Problema na montagem do EFS | Verificar `df -h` e logs do Docker |
| Erro de conexão no banco | Credenciais incorretas ou Security Groups | Verificar variáveis de ambiente e regras de SG |
| Load Balancer marca instâncias como unhealthy | Aplicação não responde na porta 80 | Verificar status do Docker e firewall |
| Arquivos não persistem | EFS não montado corretamente | Verificar status da montagem e permissões |

[⬆️ Voltar ao índice](#índice)

---

## Licença

Este projeto está licenciado sob a licença MIT - consulte o arquivo [LICENSE](LICENSE) para obter detalhes.

Principais termos da licença MIT:

- Uso comercial e privado permitido
- Modificações e distribuições autorizadas
- Atribuição de créditos ao autor original
- Sem garantias ou responsabilidades legais

[⬆️ Voltar ao índice](#índice)

---

## Contribuição

### Como Contribuir

1. Faça um fork do projeto
2. Crie sua branch de feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adicionar nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

### Diretrizes para Contribuição

- Siga as boas práticas de programação
- Mantenha o código limpo e bem documentado
- Adicione testes para novas funcionalidades
- Respeite o estilo de código existente

[⬆️ Voltar ao índice](#índice)

---

## Olá! 👋 Meu nome é Vinicius

#### Desenvolvedor em Construção: Da Saúde à Tecnologia

Graduando em Análise e Desenvolvimento de Sistemas pela [FATEC Arthur de Azevedo](https://fatecmm.cps.sp.gov.br/), atualmente estagiando em Cloud & DevSecOps na Compass UOL. Minha jornada é marcada pela transição da área da saúde para a tecnologia, motivado pelo desejo de resolver problemas de forma escalável e impactante.

### Conecte-se Comigo

<p align="left">
  <a href="https://www.linkedin.com/in/viniciusesilva/" target="_blank" rel="noreferrer">
    <img src="https://raw.githubusercontent.com/danielcranney/readme-generator/main/public/icons/socials/linkedin.svg" width="32" height="32" />
  </a>
</p>

[⬆️ Voltar ao índice](#índice)

---
