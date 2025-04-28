Claro. Vou estruturar de maneira clara e objetiva para você.

---

# **Entendimento dos Requisitos do Projeto**

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

# **Pontos de Atenção (em destaque)**

- **NÃO EXPOR** o serviço WordPress diretamente via **IP público** da instância EC2.
- **Tráfego de internet deve sair pelo Load Balancer** (preferencialmente Classic Load Balancer).
- **Pastas públicas/estáticas do WordPress** devem ser armazenadas usando **EFS**.
- **Instalação automatizada via User Data** (valoriza o trabalho).
- **WordPress acessível apenas nas portas 80 ou 8080**.
- **Demonstrar tela de login do WordPress funcionando** ao final.

---

# **Checklist de Etapas**

### Preparação:
- [ ] Criar repositório Git para o projeto.
- [ ] Definir se utilizará **Docker** ou **containerd**.
- [ ] Desenhar rapidamente a infraestrutura no papel (baseado na imagem que enviou).

### Infraestrutura:
- [ ] Criar uma **VPC** customizada se necessário (ou usar a default).
- [ ] Criar **Subnets** públicas/privadas (separando bem a arquitetura).
- [ ] Criar **Security Groups**:
  - Para EC2 (permitir apenas comunicação interna e via Load Balancer).
  - Para Load Balancer (permitir acesso HTTP externo).
  - Para RDS (permitir acesso apenas das instâncias EC2).
- [ ] Criar **EFS**:
  - Definir ponto de montagem compartilhado entre instâncias.

### Instâncias EC2:
- [ ] Criar EC2 instances (Amazon Linux 2 ou Ubuntu).
- [ ] Configurar **Auto Scaling Group** para EC2 (opcional, mas recomendado).
- [ ] Criar script **user_data.sh** para:
  - Instalar Docker/containerd.
  - Fazer pull da imagem WordPress.
  - Montar o EFS.
  - Rodar o container WordPress na porta 80/8080.
- [ ] Testar se a aplicação sobe automaticamente após a criação da instância.

### Banco de Dados:
- [ ] Criar **Amazon RDS MySQL**:
  - Banco de dados WordPress.
  - Configurar endpoint, usuário e senha.

### Deploy WordPress:
- [ ] Configurar container WordPress apontando para:
  - Banco RDS.
  - EFS para pastas estáticas.
- [ ] Validar variáveis de ambiente necessárias (DB_HOST, DB_USER, DB_PASSWORD, etc).

### Load Balancer:
- [ ] Criar **Classic Load Balancer**.
- [ ] Apontar para as instâncias EC2.
- [ ] Testar o acesso externo via Load Balancer.

### Finalização:
- [ ] Validar funcionamento da aplicação:
  - Tela de login acessível.
  - Conteúdo sendo salvo no EFS.
  - Comunicação segura entre componentes.
- [ ] Documentar todo o processo.
- [ ] Fazer commit e push contínuo no repositório Git.