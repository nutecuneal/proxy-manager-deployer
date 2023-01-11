# Reverse Proxy - Deploy

Este repositório abordará sobre como instalar servidores de **balanceamento de carga (*Load Balancer*)**, **servidores web (*Web Server*)** e **proxy reverso (*Reverse Proxy*)**, além de Gerenciamento de Certificados SSL/TLS. 

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
      - [Executando o Docker-Compose](#executando-o-docker-compose)
    - [Nginx Rede](#nginx-rede)
      - [Com Docker-Compose](#com-docker-compose)
      - [Terminal](#terminal)
  - [Certificado SSL/TLS (HTTPS)](#certificado-ssltls-https)

## Requisitos e Dependências

- Nginx
  - [Docker e Docker-Compose](https://docs.docker.com/)

<br>

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
# Aponte para as pastas/arquivos criados anteriormente.

# Antes
volumes:
  - '$(pwd)/nginx.conf:/etc/nginx/nginx.conf:ro'
  - '$(pwd)/log_nginx:/var/log/nginx'
  - '$(pwd)/certs_live:/certs:ro'
  # - '$(pwd)/certbot_acme_challenge:/data/www/acme-challenge:ro'

# Depois (exemplo)
volumes:
  - '/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro'
  - '/var/log/nginx:/var/log/nginx'
```

1. ***\$(pwd)/certs_live*** será o local dos seus certificados SSL/TLS.
2. Somente descomente a linha ***\$(pwd)/certbot_acme_challenge...*** caso opte por obter os certificados SSL/TLS usando o Certbot. Este volume apontará para o diretório de “ACME Challenge” usado pelo seu Certbot.
3. Antes de prosseguir, leia o guia de gerenciamento de [Certificado SSL/TLS (HTTPS)](#certificado-ssltls-https).

##### Rede

```yml
# nginx.docker-compose.yml (Em networks.nginx-net.ipam)
# Altere os valores caso necessário. 

config:
# Endereço da rede
  - subnet: '172.18.0.0/28'
# Gateway da rede
    gateway: 172.18.0.1
```

#### Executando o Docker-Compose

```bash
$ docker-compose -f nginx.docker-compose.yml up
```

Dica.: consulte a documentação *Nginx* para configurar o arquivo ***nginx.conf***. É preciso uma configuração mínima para o container poder ser iniciado.

### Nginx Rede

A rede Nginx foi pensada para que matenha o isolamento completo de outros containers presentes na máquina host, por isso, para que o container Nginx alcance outros containers/hosts é necessário adicioná-los a rede. 

Para isso existem dos métodos:
1. Com [ Docker-Compose](#com-docker-compose), recomendado, porém necessita recriar o container alvo.
2. Via [Terminal](#terminal).

#### Com Docker-Compose

```yml
# No [..]docker-compose.yml do seu serviço alvo.

# (Em networks) adicione:
nginx-net:
  name: 'nginx-net'
  external: true

# (Em services.SERVICENAME.networks) adicione:
- nginx-net
```

#### Terminal

```bash
# Execute

docker network connect nginx-net CONTAINER_NAME --alias CONTAINER_ALIAS
```

Dica.: você poderá localizar os containers na rede através de seus IPs, para inspecionar isso use o comando "***docker inspect CONTAINER_NAME***". Ou simplesmene use o "***alias***" do container como se fosse um **Hostname/DNS**.

<br>

## Certificado SSL/TLS (HTTPS)

>> [Clique aqui para ir ao guia](./README.cert.md)