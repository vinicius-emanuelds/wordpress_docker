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