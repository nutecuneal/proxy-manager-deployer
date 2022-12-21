# Nginx - Reverse Proxy - Deploy

## Sumário

- [Nginx - Reverse Proxy - Deploy](#nginx---reverse-proxy---deploy)
  - [Sumário](#sumário)
  - [Sobre](#sobre)
    - [Nginx](#nginx)
    - [Certbot](#certbot)
    - [Requisitos e Dependências](#requisitos-e-dependências)
      - [Nginx](#nginx-1)
      - [Certbot](#certbot-1)
      - [OpenSSL](#openssl)
  - [Nginx](#nginx-2)
    - [Instalação](#instalação)
      - [Armazenamento - Nginx](#armazenamento---nginx)
      - [Configuração Docker-Compose - Nginx](#configuração-docker-compose---nginx)
      - [Obtendo Certificado - Certbot](#obtendo-certificado---certbot)
      - [Executando a Instalação](#executando-a-instalação)
  - [Gerenciamento de Certificados (TLS/SSL | HTTPS) - Certbot](#gerenciamento-de-certificados-tlsssl--https---certbot)
    - [Armazenamento - Certbot](#armazenamento---certbot)
    - [Configuração Docker-Compose - Certbot](#configuração-docker-compose---certbot)
    - [Instalação - Certbot](#instalação---certbot)
    - [Renovação - Certbot](#renovação---certbot)
  - [Gerenciamento de Certificados (TLS/SSL | HTTPS) - Com OpenSSL (Manual)](#gerenciamento-de-certificados-tlsssl--https---com-openssl-manual)
    - [Instalação - OpenSSL](#instalação---openssl)
    - [Renovação - OpenSSL](#renovação---openssl)

## Sobre

### Nginx

"NGINX é um servidor HTTP gratuito, de código aberto e de alto desempenho e proxy reverso, bem como um servidor proxy IMAP/POP3. O NGINX é conhecido por seu alto desempenho, estabilidade, rico conjunto de recursos, configuração simples e baixo consumo de recursos."

- [Nginx - Docs](https://docs.nginx.com/)

### Certbot

O Certbot é uma ferramenta de software gratuita e de código aberto para usar automaticamente os certificados Let's Encrypt em sites administrados manualmente para habilitar o HTTPS. O Let's Encrypt é uma Autoridade Certificadora gratuita, automatizada e aberta. Os certificados Let's Encrypt gratuitos têm validade de apenas 90 dias, com o Certbot é possível automatizar a criação e a renovação desses certificados.

- [Certbot](https://certbot.eff.org/)
- [Let´s Encrypt](https://letsencrypt.org/)
- [Certbot - Docs](https://eff-certbot.readthedocs.io/en/stable/intro.html)

### Requisitos e Dependências

#### Nginx
- [Docker e Docker-Compose](https://docs.docker.com/)

#### Certbot
- [Docker e Docker-Compose](https://docs.docker.com/)
  
#### OpenSSL
- [OpenSSL](https://www.openssl.org/)
- [Documentação](https://www.openssl.org/docs/)

## Nginx

### Instalação

#### Armazenamento - Nginx

```bash
# Crie os diretórios.

# Dir. Config
$ mkdir **/dir_nginxconfig 

# Dir. Log
$ mkdir **/dir_nginxlog

# Crie o arquivo de configuração do Nginx.
$ touch **/dir_nginxconfig/nginx.conf
```

Sugestão (no Linux):
- Dir. Config: /etc/nginx
- Dir. Log: /var/log/nginx

*Obs*: consulte a documentação [Nginx](#nginx) para configurar o arquivo ***nginx.conf***.

#### Configuração Docker-Compose - Nginx

```yml
# docker-compose.yml
# ... networks

config:
  - subnet: '172.18.0.0/28'
    gateway: 172.18.0.1

# Configure subnet e gateway para o "range" de sua preferência.

# Não obrigatório.
```

```yml
# docker-compose.yml
# ... app

# Altere a secção "volume",
#   aponte para as pastas/arquivos criadas anteriomente.
volumes:
  - '**/dir_nginxconfig/nginx.conf:/etc/nginx/nginx.conf:ro'
  - '**/dir_nginxlog:/var/log/nginx'
  - '**/dir_certlive:/certs:ro'
  - '**/dir_acme-challenge:/data/www/acme-challenge:ro' # Só descomente caso opte pelo Certbot

# Altere o valor de ipv4_address de acordo
#   com o seu "range" configurado.
rproxy-net:
  ipv4_address: 172.18.0.2
```

- *Obs1*: ***\*\*/dir_certlive*** deve ser apontado para o seu diretório de certificados. Com o Certbot será ***\*\*/dir_letsconf/live***, com OpenSSL dependerá de sua configuração.
- *Obs2*: ***\*\*/dir_acme-challenge*** é discutido na secção [Armazenamento - Certbot](#armazenamento---certbot).


#### Obtendo Certificado - Certbot

Se você optou por obter seu certificado via Certbot será necessário comprovar que o domínio é seu, por isso, na primeira execução rode o nginx com a seguinte configuração. Em seguida rode o comando da secção [Instalação - Certbot](#instalação---certbot).

Depois que obter o certificado você pode parar o nginx e fazer as suas configurações.

```text
# nginx.com

events {

}

http {
    charset utf-8;
    server_tokens off;

    server {
        listen 80 default_server;
        server_name _;

        location ~ /.well-known/acme-challenge/ {
          root /data/www/acme-challenge;
        }
    }
}
```
#### Executando a Instalação

```bash
$ docker-compose -f docker-compose.yml up
```

<br>

## Gerenciamento de Certificados (TLS/SSL | HTTPS) - Certbot

### Armazenamento - Certbot

```bash
# Dir. Config/Dados
$ mkdir **/dir_letsconf

# Dir. Lib
$ mkdir **/dir_letslib

# Dir. Log
$ mkdir **/dir_letslog

# Dir. ACME
$ mkdir **/dir_acme-challenge
```
Sugestão (no Linux):
- Dir. Config/Dados: /etc/letsencrypt
- Dir. Lib: /var/lib/letsencrypt
- Dir. Log: /var/log/letsencrypt
- Dir. ACME: /var/www/certbot

### Configuração Docker-Compose - Certbot

```yml
# docker-compose-certbot.yml
# ... networks

config:
  - subnet: '172.18.0.0/28'
    gateway: 172.18.0.1

# Configure subnet e gateway para o "range" de sua preferência.

# Não obrigatório.
```

```yml
# docker-compose-certbot.yml
# ... app

# Altere a secção "volume",
#   aponte para as pastas criadas anteriomente.
# Ficando:
volumes:
  - '**/dir_letsconf:/etc/letsencrypt'
  - '**/dir_letslib:/var/lib/letsencrypt'
  - '**/dir_letslog:/var/log/letsencrypt'
  - '**/dir_acme-challenge:/var/www/certbot'

# Altere o valor de ipv4_address de acordo
#   com o seu "range" configurado.
glpi-net:
  ipv4_address: 172.18.0.2
```

### Instalação - Certbot

Altere todas as ocorrências de ***\*\*/docker-compose-certbot.yml*** pelo caminho do arquivo ***docker-compose-certbot.yml*** 

```bash
# Execute para gerar um novo certificado

$ docker-compose -f **/docker-compose-certbot.yml run -rm certbot certonly --webroot --webroot-path=/var/www/certbot -d $cert_value1 -m $cert_value2 --agree-tos
```

| Varíavel      | Descrição                                                    |
| ------------- | ------------------------------------------------------------ |
| \$cert_value1 | Domínio do site.<br>Ex.: servico.uneal.edu.br                |
| \$cert_value2 | Endereço de Email.<br>Ex.: nutec@email.com                   |

<br>

*Info*: esse comando gerará um certificado com o domínio, e-mail.


### Renovação - Certbot

Adicione a seguinte configuração no crontab da máquina host.

```text
#  Esse comando verificará e, se necessário atualizará, os certificados todos domingos às 00h:00m.
0 0 * * 0 root docker-compose -f **/dir_certbot-deploy/docker-compose-certbot.yml run -rm \
  certbot renew -q
```

Para que o novo certificado tenha efeito é necessário recarregar as configurações. Portanto adicione ao crontab:


```text
#  Esse comando fará o recarregamento das configurações do Nginx todos os domingos às   01h:00m.
0 1 * * 0 root docker exec -it nginx-app nginx -s reload
```

<br>

## Gerenciamento de Certificados (TLS/SSL | HTTPS) - Com OpenSSL (Manual)

### Instalação - OpenSSL

```bash
# Após instalar o OpenSSL

# Geração de chave privada RSA
$ openssl genpkey -out $open_value_1 -algorithm RSA -pkeyopt rsa_keygen_bits:$open_value_2

# Geração de certificado
$ openssl req -new -x509 -key $open_value_1 -out $open_value_3 -days $open_value_4 -subj="/C=$open_value_5/ST=$open_value_6/L=$open_value_7/O=$open_value_8/OU=$open_value_9/CN=$open_value_10/emailAddress=$open_value_11"

# Copie a chave e o certificado para o seu "diretório de certificados" 
```

| Varíavel         | Descrição                                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------------ |
| \$open_value_1   | Nome do arquivo (chave privada)<br>Ex.: **nome.key**.                                            |
| \$open_value_2   | Tamanho(bits) da chave gerada.<br>Ex.: 2048 (bom), 3072 (Ideal), 4096 (Forte - porém mais lento) |
| \$open_value_3   | Nome do arquivo (certificado)<br>Ex.: **nome.pem**.                                              |
| \$open_value_4   | Dias de validade do certificado<br>Ex.:1000                                                      |
| \$open_value_5   | Código do país (duas letras).<br>Ex.: BR                                                         |
| \$open_value_6   | Estado.<br>Ex.: Alagoas.                                                                         |
| \$open_value_7   | Cidade.<br>Ex.: Arapiraca.                                                                       |
| \$open_value_8   | Nome da Organização.<br>Ex.:Universidade Estadual de Alagoas.                                    |
| \$open_value_9   | Departamento da Organização.<br>Ex.: NUTEC.                                                      |
| \$open_value_10: | Nome comum - Domínio.<br>Ex.: servico.uneal.edu.br.                                              |
| \$open_value_11  | Endereço de Email.<br>Ex.: nutec@gmail.com                                                       |

### Renovação - OpenSSL

Para renovar um certificado basta gerar um novo seguindo o mesmo processo descrito no secção [Instalação - Com OpenSSL (Manual)](#instalação---openssl).

- A geração da chave privada RSA é opcional. (Recomendado gerar uma nova).
- Se a chave ou o certificado forem gerados com nomes diferentes será necessário alterar o arquivo *nginx.conf*.
- Após realizar o processo reinicie o container do seu Nginx para que as mudança sejam aplicadas.