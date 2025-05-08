# 🐳 WordPress com Docker + AWS Infrastructure

<br>

## ÍNDICE
| Seção | Descrição |  
|-------|-----------|
| [🎯 Objetivos](#objetivos) | Metas do projeto |  
| [🛠 Recursos Necessários](#recursos-necessários) | Pré-requisitos e configurações |  
| [🌐 Configuração AWS](#configurando-o-ambiente-aws) | VPC, Security Groups e EC2 |  
| [🔌 Conexão com a Instância](#conectando-se-à-instância) | Acesso SSH passo a passo |  
| [⚙️ Servidor Web](#configuração-do-servidor-web) | Instalação do Nginx e testes |  
| [🚨 Monitoramento](#monitoramento-e-notificações) | Scripts + Notificações no Telegram |  
| [🤖 Automação](#automação-com-user-data) | User Data para deploy rápido |  
| [📚 Recursos Úteis](#recursos-úteis) | Scripts prontos e comandos-chave |
| [✅ Conclusão](#conclusão) | Aprendizados e considerações finais |

---

<br>

## OBJETIVOS
Implantar uma aplicação WordPress altamente disponível na AWS, utilizando:
- Containers Docker
- Banco de dados gerenciado (RDS MySQL)
- Armazenamento de arquivos estáticos (EFS)
- Balanceamento de carga (Load Balancer)
- Monitoramento e notificações via CloudWatch e SNS 

<br>

[Voltar ao índice ⬆️](#índice)

---

## **RESQUISITOS TÉCNICOS**

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

---

<br>

## ARQUETETURA PROPOSTA
![alt text](<docs/images/0 TOPOLOGIA.png>)

### Componentes
- **Compute**: AWS EC2 com Docker
- **Database**: Amazon RDS MySQL
- **Storage**: Amazon EFS
- **Network**: VPC, Subnets e Security Groups
- **Load Balancing**: AWS Application Load Balancer

<br>

[Voltar ao índice ⬆️](#índice)

---

<br>

## RECURSOS NECESSÁRIOS

✔️ Conta AWS ativa ([Criar conta gratuita](https://aws.amazon.com/pt/free/))

> A [Amazon Web Services (AWS)](https://aws.amazon.com/pt/what-is-aws/) é a plataforma de nuvem mais adotada e mais abrangente do mundo, oferecendo mais de 200 serviços completos de datacenters em todo o mundo. Milhões de clientes, incluindo as startups que crescem mais rápido, as maiores empresas e os maiores órgãos governamentais, estão usando a AWS para reduzir custos, ganhar agilidade e inovar mais rapidamente.

<br>

✔️ AWS CLI instalado
> [Clique aqui](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) para acessar a documentação oficial.

<br>

✔️ Terminal com acesso SSH (Linux/Mac/WSL)

<br>

✔️ Conhecimentos básicos em:
  - AWS
  - Docker
  - Redes
  - Linux

<br>

[Voltar ao índice ⬆️](#índice)

---

<br>

# **CONFIGURANDO O AMBIENTE AWS**

## **Criar a VPC**
Agora vamos criar uma VPC na AWS com 4 sub-redes (2 privadas e 2 públicas), com um internet gateway conectado à uma das sub-redes públicas.

- Após logar no console AWS, selecione VPC (ou digite na barra de busca).<br>
![alt text](<docs/images/1 VPC - DASHB.png>)

- Clique em *Create VPC*<br>
![alt text](<docs/images/1 VPC - CREATE.png>)

- Aplique as configurações abaixo e clique em *Create VPC*<br>
![alt text](<docs/images/1 VPC - SETTINGS.png>)<br>
![alt text](<docs/images/1 VPC - CREATE VPC.png>)

- Se as configurações estiverem corretas, o fluxo deve ser similar à esse:<br>
![alt text](<docs/images/1 VPC - RESOURCE MAP.png>)


<br>

## **Criando um Security Group**
Para este projeto, nós teremos 04 Security Groups, um para cada serviço.

- No dashboard, clique em EC2. Depois, na seção à esquerda, selecione *Secuity Group*<br>
![alt text](<docs/images/2 SG - SELECIONAR.png>)

- Clique em *Create Security Group*<br>
![alt text](<docs/images/2 SG - CREATE.png>)

- Escolha um nome, faça uma descrição e selecione a VPC <br>
![alt text](<docs/images/2 SG - BASIC DETAILS.png>)

Agora, para cada Security Group, aplique as regras de entrada e saída conforme abaixo:

### Security Group do Load Balancer
Objetivo: Proteger o Load Balancer e permitir tráfego somente vindo da internet.

***Inbound***:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| HTTP  | TCP       | 80   | Anywhere - IPV4| Permitir todo tráfego vindo da internet |
| Custom TCP  | TCP       | 8080  | Anywhere - IPV4 | Permitir tráfego HTTP alternativo vindo da internet |

***Outbound***:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |


### Security Group da EC2 (Instância WordPress)
Objetivo: Proteger a instância e permitir tráfego somente vindo do Load Balancer.

***Inbound***:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| HTTP  | TCP       | 80    | SG do Load Balancer | Permitir tráfego HTTP |
| Custom TCP  | TCP       | 8080  | SG do Load Balancer | Permitir tráfego HTTP alternativo |
| SSH   | TCP       | 22    | Seu IP | Permitir acesso SSH para administração |

***Outbound***:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

### Security Group do RDS (Banco de Dados MySQL)
Objetivo: Proteger o banco de dados e permitir tráfego somente vindo da instância EC2.

***Inbound***:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| MYSQL/Aurora  | TCP       | 3306   | SG da EC2 | Permitir tráfego MySQL |

***Outbound***:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

### Security Group do EFS (Armazenamento de Arquivos)
Objetivo: Proteger o EFS e permitir tráfego somente vindo da instância EC2.

***Inbound***:
| Tipo | Protocolo | Porta | Origem | Descrição |
|-------|-----------|-------|--------|-----------| 
| NFS  | TCP       | 2049  | SG da EC2 | Permitir tráfego no EFS |

***Outbound***:
| Tipo | Protocolo | Porta | Destino | Descrição |
|-------|-----------|-------|---------|-----------|
| All traffic | All | All | Anywhere - IPv4 | Permitir todo tráfego de saída |

<br>

- Após criar os Security Groups, seu dashboard deve estar assim:

![alt text](<docs/images/2 SG - REVIEW.png>)

<br>

## **Criar o EFS**
- Na barra de pesquisa, digite EFS e depois clique na primeira opção. Depois, clique em *Create file system*<br>

![alt text](<docs/images/3 EFS - SELECIONAR.png>)<br>
![alt text](<docs/images/3 EFS - CREATE.png>)


- Depois, escolha um nome, selecione a *VPC* e clique em *Customize*
  
![alt text](<docs/images/3 EFS - CUSTOMIZE.png>)

- Aplique as configurações abaixo e clique em *Next*<br>
> *As configurações que não estão indicadas ou alteradas, permanecem como padrão*<br>
![alt text](<docs/images/3 EFS - GENERAL.png>)<br>
![<alt text>](<docs/images/3 EFS - PERFORMANCE.png>)<br>
![alt text](<docs/images/3 EFS - NETWORK.png>)<br>
![alt text](<docs/images/3 EFS - POLICY.png>)

- Na última tela, revise as configurações e clique em *Create*<br>

<br>

## **Criar o RDS**
- Na barra de pesquisa, digite RDS e depois clique na primeira opção. Depois, clique em *Create database*<br>
![alt text](<docs/images/4 RDS - SELECIONAR.png>)<br>
![alt text](<docs/images/4 RDS - CREATE.png>)

- Aplique as configurações abaixo e clique em *Next* em cada etapa<br>

> *As configurações que não estão indicadas ou alteradas, permanecem como padrão*<br>

![alt text](<docs/images/4 RDS - MYSQL.png>)<br>
![alt text](<docs/images/4 RDS - FREE TIER.png>)<br>
![alt text](<docs/images/4 RDS - AVAILABILITY.png>)<br>
![alt text](<docs/images/4 RDS - CREDENTIALS.png>)<br>
![alt text](<docs/images/4 RDS - INSTANCE.png>)<br>
![alt text](<docs/images/4 RDS - CONECTIVITY.png>)<br>
![alt text](<docs/images/4 RDS - VPC.png>)<br>
![alt text](<docs/images/4 RDS - ADDITIONAL.png>)<br>

- Na tela final, revise os dados e clique em *Create database*
- Após a criação, clique em *View database*
- Na tela de detalhes, copie o *endpoint* do banco de dados. Você precisará dele mais tarde.
  
![alt text](<docs/images/4 RDS - REVIEW.png>)<br>

## *CRIAR O TARGET GROUP DO LOAD BALANCER*
- Na barra de pesquisa, digite *Target Groups* e clique em *"Target Groups - EC2 Feature"*. Depois, clique em *Create target group*
  
![alt text](<docs/images/5 TG - SELECIONAR.png>)<br>
![alt text](<docs/images/5 TG - CREATE.png>)<br>

- Aplique as configurações abaixo e clique em *Next* em cada etapa<br>

> *As configurações que não estão indicadas ou alteradas, permanecem como padrão*<br>

![alt text](<docs/images/5 TG - BASIC.png>)<br>
![alt text](<docs/images/5 TG - CONFIGURATIONS.png>)<br>
![alt text](<docs/images/5 TG - HEALTH.png>)
> Para este projeto, o path do health check será `/readme.html`, página padrão criada por automaticamente ao instalarmos o WordPress <br>

- Nesse momento, não adicione instâncias. Clique em *Create target group*

![alt text](<docs/images/5 TG - CREATE TG.png>)

- Agora, iremos editar os atributos do target group. Clique no target group criado e depois em *Edit*

![alt text](<docs/images/5 TG - EDIT.png>)<br>

- Aplique as configurações abaixo e clique em *Save changes*<br>

![alt text](<docs/images/5 TG - COOKIES.png>)

<br>

## **CRIAR O LOAD BALANCER**
- Na barra de pesquisa, digite *Load Balancers* e clique em *"Load Balancers - EC2 Feature"*. Depois, clique em *Create Load Balancer*

![alt text](<docs/images/6 LB - SELECIONAR.png>)

![alt text](<docs/images/6 LB - CREATE.png>)

- Escolha o tipo de Load Balancer *Application Load Balancer* e clique em *Create*

![alt text](<docs/images/6 LB - TYPE.png>)

- Aplique as configurações abaixo e clique em *Next* em cada etapa
  
> *As configurações que não estão indicadas ou alteradas, permanecem como padrão*

![alt text](<docs/images/6 LB - BASIC.png>)

![alt text](<docs/images/6 LB - NETWORK.png>)

![alt text](<docs/images/6 LB - SECURITY.png>)

![alt text](<docs/images/6 LB - CREATE LB.png>)

# *CRIANDO A APLICAÇÃO DO WORDPRESS*
## *CRIAR UM TEMPLATE DA EC2*
- Nesse projeto, iremos utilizar o *Automatic Scaling* da AWS para criar uma instância EC2 com o WordPress já instalado. Para isso, precisamos criar um template da instância.

- Na barra de pesquisa, digite *Launch Templates* e clique na primeira opção. Depois, clique em *Launch instance*

![alt text](<docs/images/7 LT - SELECIONAR.png>)

![alt text](<docs/images/7 LT - CREATE.png>)

- Aplique as configurações abaixo e clique em *Next* em cada etapa

> *As configurações que não estão indicadas ou alteradas, permanecem como padrão*

![alt text](<docs/images/7 LT - NAME.png>)

![alt text](<docs/images/7 LT - INSTANCE.png>)

> Se precisar criar a chave, clique em *Create new key pair* e siga as instruções.
> 
> ![alt text](<docs/images/7 LT - KEY PAIR.png>)
>
> Após a criação, a chave será baixada automaticamente para sua máquina. É importante mantê-la disponível no momento da conexão com a instância. Se estiver usando o windows, com wsl, utilize o comando abaixo para copiar para a máquina Linux. Se já estiver utilizando Linux, pule esta etapa.
> ```cmd
> scp \caminho_para_chave\[SUA_CHAVE].pem [USUÁRIO]@[IP_LINUX]:/home/[USUÁRIO]
> ```
>
> Já no linux, aplique as permissões para a chave:
> ```bash
> chmod 400 [SUA_CHAVE].pem
> ```

![alt text](<docs/images/7 LT - NETWORK.png>)

![alt text](<docs/images/7 LT - STORAGE.png>)

- Na seção *Advanced details*, cole o script abaixo no campo *User data* e clique em *Create launch template*
> *Esse script irá instalar o WordPress e configurar o Docker na instância. Ele será executado automaticamente quando a instância for criada*<br>

```bash
#!/bin/bash
set -e
trap 'echo "Erro na linha $LINENO. Comando: $BASH_COMMAND" >> /var/log/user-data-error.log' ERR

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

> **ATENÇÃO**: Não esqueça de substituir os valores entre colchetes `[]` pelas informações corretas. <br>


![alt text](<docs/images/7 LT - USERDATA.png>)

## CRIAR O AUTO SCALING
- Na barra de pesquisa, digite *Auto Scaling Groups* e clique na primeira opção. Depois, clique em *Create Auto Scaling group*

![alt text](<docs/images/8 ASG - SELECIONAR.png>)

![alt text](<docs/images/8 ASG - CREATE.png>)

- Aplique as configurações abaixo e clique em *Next* em cada etapa

> *As configurações que não estão indicadas ou alteradas, permanecem como padrão*

![alt text](<docs/images/8 ASG - NAME.png>)

![alt text](<docs/images/8 ASG - VERSION.png>)

![alt text](<docs/images/8 ASG - NETWORK.png>)

![alt text](<docs/images/8 ASG - INTEGRATE.png>)

![alt text](<docs/images/8 ASG - POLICY.png>)

![alt text](<docs/images/8 ASG - HEALTH.png>)

![alt text](<docs/images/8 ASG - SCALING.png>)

![alt text](<docs/images/8 ASG - TRACKING.png>)

> Escolha a *Scaling Policy* de acordo com seu projeto. Para este projeto, escolhemos a *Target tracking scaling policy*, utilizando o *metric type* **Average CPU utilization**, que irá aumentar ou diminuir a quantidade de instâncias de acordo com a utilização média da CPU. <br>

- Após finalizar, clique em *Create Auto Scaling group*<br>. Se tudo estiver correto, seu dashboard de instâncias deve estar assim:

![alt text](<docs/images/8 ASG - INSTÂNCIAS.png>)

# *TESTANDO A APLICAÇÃO*
- Após alguns minutos, seu Load Balancer deve estar ativo. Busque na barra de pesquisa por Load Balancer e clique na opção (como fizemos anteriormente).

- Selecione o Load Balancer criado e copie o *DNS name*.

- Cole no navegador e verifique se a página do WordPress está carregando. Caso não esteja, aguarde alguns minutos e tente novamente.

- Se tudo estiver correto, você verá a tela de instalação do WordPress. Siga as instruções para finalizar a instalação.

![alt text](docs/images/TESTE.png)

![alt text](<docs/images/9 TESTE - CONFIGURAÇÃO.png>)

- Após a instalação, você verá a tela de boas-vindas do WordPress. Clique em *Log in* para acessar o painel administrativo.

![alt text](<docs/images/9 TESTE - LOGIN.png>)

- Após logar, você verá o painel administrativo do WordPress. Aqui, você pode gerenciar seu site, adicionar plugins, temas e muito mais.

![alt text](<docs/images/9 TESTE - PÁGINA INICIAL.png>)

# TESTANDO A PERSISTÊNCIA DOS ARQUIVOS
- Acesse o painel administrativo do WordPress e vá em *Mídia* > *Biblioteca*. Faça o upload de uma imagem qualquer.

![alt text](<docs/images/9 TESTE - UP.png>)

- Após o upload, acesse o EFS e verifique se a imagem foi salva na pasta `/mnt/wordpress/wp-content/uploads`.

- Após verificar, delete as instância EC2.

- Após alguns minutos, novas instância será criada pelo Auto Scaling Group.

- Acesse o painel administrativo do WordPress novamente (através do DNS do Load Balancer) e vá em *Mídia* > *Biblioteca*. Verifique se a imagem ainda está disponível.

![alt text](<docs/images/9 TESTE - VERIFICAR.png>)

- Se tudo estiver correto, você verá a imagem que fez o upload anteriormente.

### Problemas Comuns

| Problema | Possível Causa | Solução |
|----------|----------------|---------|
| WordPress não inicia | Problema na montagem do EFS | Verificar `df -h` e logs do Docker |
| Erro de conexão no banco | Credenciais incorretas ou Security Groups | Verificar variáveis de ambiente e regras de SG |
| Load Balancer marca instâncias como unhealthy | Aplicação não responde na porta 80 | Verificar status do Docker e firewall |
| Arquivos não persistem | EFS não montado corretamente | Verificar status da montagem e permissões |

## 📜 Licença

Este projeto está licenciado sob a licença MIT - consulte o arquivo [LICENSE](LICENSE) para obter detalhes.

## 🤝 Contribuição

1. Faça um fork do projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adicionar nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

Desenvolvido por [Seu Nome] - [Seu Email/Contato]