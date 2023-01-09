# Reverse Proxy - Deploy

Este repositório abordará sobre como instalar servidores de **balanceamento de carga (*Load Balancer*)**, **servidores web (*Web Server*)** e **proxy reverso (*Reverse Proxy*)**. 

1. [NGINX](https://docs.nginx.com) é um servidor HTTP gratuito, de código aberto e de alto desempenho e proxy reverso, bem como um servidor proxy IMAP/POP3. O NGINX é conhecido por seu alto desempenho, estabilidade, rico conjunto de recursos, configuração simples e baixo consumo de recursos.

## Sumário

- [Reverse Proxy - Deploy](#reverse-proxy---deploy)
  - [Sumário](#sumário)
  - [Requisitos e Dependências](#requisitos-e-dependências)
  - [Nginx](#nginx)
    - [Instalação](#instalação)
      - [Estrutura de Diretórios](#estrutura-de-diretórios)
      - [Docker-Compose](#docker-compose)
        - [Portas](#portas)
        - [Volumes](#volumes)
        - [Rede](#rede)
        - [Subindo o Container](#subindo-o-container)

## Requisitos e Dependências

- [Docker e Docker-Compose](https://docs.docker.com/)

## Nginx

### Instalação

#### Estrutura de Diretórios

```bash
# Crie os diretórios.

# Dir. Config
$ mkdir $(pwd)/conf-nginx 

# Crie o arquivo de configuração do Nginx.
$ touch $(pwd)/conf-nginx/nginx.conf

# Dir. Log
$ mkdir $(pwd)/log-nginx
```

Sugestão (no Linux):
- Dir. Config: /etc/nginx
- Dir. Log: /var/log/nginx

#### Docker-Compose

##### Portas

```yml
# nginx.docker-compose.yml (Em services.app)

# Comente/Descomente (e/ou altere) as portas/serviços que você deseja oferecer.

ports:
# Porta para HTTP.
  - '80:80'
# Porta para HTTPS.
  - '443:443'
```

##### Volumes

```yml
# nginx.docker-compose.yml (Em services.app)
# Aponte para as pastas/arquivos criadas anteriormente.

# Antes
volumes:
  - '$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro'
  - '$(pwd)/log_nginx:/var/log/nginx'
  - '$(pwd)/certs_live:/certs:ro' # Local dos certificados TLS/SSL
  # - '$(pwd)/certbot_acme_challenge:/data/www/acme-challenge:ro'

# Descomente a linha acima caso opte por obter os certificados TLS/SSL usando o certbot.

# Depois (exemplo)
volumes:
  - '/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro'
  - '/var/log/nginx:/var/log/nginx'
```

Obs: os volumes **"\$(pwd)/certs_live:/certs:ro"** e **"\$(pwd)/certbot_acme_challenge:/data/www/acme-challenge:ro"** serão mapeados para os diretórios de armazenamento de seus certificados TLS/SSL e para o diretório de “ACME Challenge” usado pelo seu Certbot, respectivamente. 


##### Rede

```yml
# nginx.docker-compose.yml (Em networks.nginx-net.ipam)
# Altere o valores caso necessário. 

config:
# Endereço da rede
  - subnet: '172.18.0.0/28'
# Gateway da rede
    gateway: 172.18.0.1
```

##### Subindo o Container

```bash
$ docker-compose -f docker-compose.yml up
```

*Obs*: consulte a documentação *Nginx* para configurar o arquivo ***nginx.conf***.