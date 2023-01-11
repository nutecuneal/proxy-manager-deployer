# Certificado SSL/TLS (HTTPS)

Neste documento será abordado sobre como gerenciar certificados SSL/TLS para HTTPS, utilizando Certbot (Let's Encrypt) e/ou OpenSSL.

1. O [Certbot](https://certbot.eff.org/) é uma ferramenta de software gratuita e de código aberto para manutenção de certificados [Let's Encrypt](https://letsencrypt.org/) em sites administrados manualmente. O Let's Encrypt é uma Autoridade Certificadora gratuita e aberta. Os certificados Let's Encrypt são gratuitos e têm validade de apenas 90 dias, com o Certbot é possível automatizar a criação e a renovação desses certificados. [Certbot - Docs](https://eff-certbot.readthedocs.io/en/stable/intro.html).
2. O [OpenSSL](https://www.openssl.org/) é um projeto que prover um kit robusto de ferramentas para criptografia de uso geral e comunicação. Com ele, é possível gera certificados de diversos tipos. Recomendado não usar em produção, pois seus certificados não possuem uma Autoridade Certificadoran (CA) que possa validá-lo e isso ocasionará mensagens de segurança nos navegadores. [OpenSSL - Docs](https://www.openssl.org/docs/).

## Sumário

- [Certificado SSL/TLS (HTTPS)](#certificado-ssltls-https)
  - [Sumário](#sumário)
  - [Requisitos e Dependências](#requisitos-e-dependências)
  - [Certbot](#certbot)
    - [Estrutura de Diretórios](#estrutura-de-diretórios)
    - [Docker-Compose](#docker-compose)
      - [Volume](#volume)
    - [Obtendo um Certificado](#obtendo-um-certificado)
      - [Com Nginx](#com-nginx)
      - [Executando o Docker-Compose - Certbot](#executando-o-docker-compose---certbot)
    - [Renovação Automática](#renovação-automática)
      - [Configurando os Scripts](#configurando-os-scripts)
      - [Agendamento de Tarefa](#agendamento-de-tarefa)
        - [Cron (Linux)](#cron-linux)
  - [OpenSSL (Manual)](#openssl-manual)
    - [Obtendo um Certificado](#obtendo-um-certificado-1)
    - [Renovação](#renovação)
  - [Referências](#referências)

## Requisitos e Dependências

- Certbot
  - [Docker e Docker-Compose](https://docs.docker.com/)
- OpenSSL
  - [OpenSSL](https://www.openssl.org/)

<br>

## Certbot

### Estrutura de Diretórios

```bash
# Crie os diretórios.

# Dir. Config/Dados
$ mkdir  $(pwd)/etc-lets

# Dir. Lib
$ mkdir $(pwd)/lib-lets

# Dir. Log
$ mkdir $(pwd)/log-lets

# Dir. ACME
$ mkdir $(pwd)/acme-challenge
```

Sugestão (no Linux):
- Dir. Config/Dados: */etc/letsencrypt*
- Dir. Lib: */var/lib/letsencrypt*
- Dir. Log: */var/log/letsencrypt*
- Dir. ACME: */var/www/certbot*


Dica: os certificados serão armazenados em **"Dir. Config/Dados"**, então, esse será o seu caminho ***\$(pwd)/certs_live***.

### Docker-Compose

#### Volume

```yml
# certbot.docker-compose.yml (Em services.app)
# Aponte para as pastas criadas anteriormente.

# Antes
volumes:
  - '$(pwd)/etc_lets:/etc/letsencrypt'
  - '$(pwd)/lib_lets:/var/lib/letsencrypt'
  - '$(pwd)/log_lets:/var/log/letsencrypt'
  - '$(pwd)/certbot_acme_challenge:/var/www/certbot'

# Depois (exemplo)
volumes:
  - '/etc/letsencrypt:/etc/letsencrypt'
  - '/var/lib/letsencrypt:/var/lib/letsencrypt'
  - '/var/log/letsencrypt:/var/log/letsencrypt'
  - '/var/www/certbot:/var/www/certbot'
```

### Obtendo um Certificado

Está secção será utilizada para obter o certificado pela primeira vez, ou seja, se você ainda não possui um certificado SSL/TLS.

#### Com Nginx

Inicialmente, configure seu arquivo *nginx.conf* da seguinte maneira:


```conf
# nginx.conf

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

#### Executando o Docker-Compose - Certbot

```bash
# Execute para gerar um novo certificado

$ docker-compose -f certbot.docker-compose.yml run --rm app certonly --webroot --webroot-path=/var/www/certbot -m EMAIL -d DOMAINS --agree-tos
```

| Varíavel | Descrição                                                         |
| -------- | ----------------------------------------------------------------- |
| EMAIL    | Um endereço de Email                                              |
| DOMAINS  | Domínio do site. Ou, domínios (separado por virgula e sem espaço) |


**Obs: após rodar o comando execute/suba o seu servidor Proxy-Manager. Você poderá também executar/subir o Proxy-Manager antes de rodar comando acima, porém necessitará criar os diretórios requisitados manualmente.**

### Renovação Automática

#### Configurando os Scripts

1. Pasta com os scripts: [***scripts-certbot***](./scripts-certbot).
2. Copie a pasta - ou somente os arquivos - para o local de sua preferência.
3. Em [***certbot-run-renew.sh***](./scripts-certbot/certbot-run-renew.sh) configure as variáveis de ambiente.
4. Se necessário, utilize o [***certbot-post-renew.sh***](scripts-certbot/certbot-post-renew.sh) para rodar scripts/comandos após a renovação do certificado (somente será executado se a renovação for bem sucedida). Esse script pode ser útil para efetuar "*reload*" das configurações do servidor após a renovação.

#### Agendamento de Tarefa

##### Cron (Linux)

Adicione a seguinte configuração no crontab da máquina host:

```
# Essa instrução adiciona uma tarefa que verificará e, se necessário, atualizará os certificados todos domingos às 00h:00m.

0 0 * * 0 ./$(pwd)/certbot-run-renew.sh
```

Dica.: altere o trecho ***\$(pwd)/certbot-run-renew.sh*** para o caminho do script na máquina host.

<br>

## OpenSSL (Manual)

### Obtendo um Certificado

```bash
# Após instalar o OpenSSL

# Geração de chave privada RSA
$ openssl genpkey -out KEYFILENAME -algorithm RSA -pkeyopt rsa_keygen_bits:RSABITS

# Geração de certificado
$ openssl req -new -x509 -key KEYFILENAME -out CERTFILENAME -days VALIDDAYS -subj="/C=COUNTRY/ST=STATE/L=CITY/O=ORG/OU=DEPARTMENT/CN=DOMAIN/emailAddress=EMAIL"

# Copie a chave e o certificado para o seu "diretório de certificados" 
```

| Varíavel     | Descrição                                                     |
| ------------ | ------------------------------------------------------------- |
| KEYFILENAME  | Nome do arquivo (chave privada)<br>Ex.: **nome.key**.         |
| RSABITS      | Tamanho(bits) da chave gerada.                                |
| CERTFILENAME | Nome do arquivo (certificado)<br>Ex.: **nome.pem**.           |
| VALIDDAYS    | Dias de validade do certificado<br>Ex.:1000                   |
| COUNTRY      | Código do país (duas letras).<br>Ex.: BR                      |
| STATE        | Estado.<br>Ex.: Alagoas.                                      |
| CITY         | Cidade.<br>Ex.: Arapiraca.                                    |
| ORG          | Nome da Organização.<br>Ex.:Universidade Estadual de Alagoas. |
| DEPARTMENT   | Departamento da Organização.<br>Ex.: NUTEC.                   |
| DOMAIN       | Nome comum - Domínio.<br>Ex.: servico.uneal.edu.br.           |
| EMAIL        | Endereço de Email.<br>Ex.: nutec@gmail.com                    |

Obs.: RSABITS - 2048 (bom), 3072 (Ideal), 4096 (Forte - porém mais lento).

### Renovação

A renovar de um certificado se dá da mesma forma explanada na secção ([OpenSSL (Manual) > Obtendo um Certificado](#obtendo-um-certificado-1)). Algumas observações:

1. A geração da chave privada RSA é opcional. (Recomendado gerar uma nova).
2. Se a chave ou o certificado forem gerados com nomes diferentes será necessário alterar o arquivo de configuração de ser servidor.
3. Após realizar o processo **reinicie o container** ou **faça o *reload* das configurações** no servidor para que as mudança sejam aplicadas.

## Referências

1. https://gist.github.com/maxivak/4706c87698d14e9de0918b6ea2a41015