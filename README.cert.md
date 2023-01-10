# Certificado SSL/TLS (HTTPS)

Neste documento será abordado sobre como gerenciar certificados SSL/TLS para HTTPS, utilizando Certbot (Let's Encrypt) e/ou OpenSSL.

1. O [Certbot](https://certbot.eff.org/) é uma ferramenta de software gratuita e de código aberto para usar automaticamente os certificados [Let's Encrypt](https://letsencrypt.org/) em sites administrados manualmente para habilitar o HTTPS. O Let's Encrypt é uma Autoridade Certificadora gratuita, automatizada e aberta. Os certificados Let's Encrypt gratuitos têm validade de apenas 90 dias, com o Certbot é possível automatizar a criação e a renovação desses certificados. [Certbot - Docs](https://eff-certbot.readthedocs.io/en/stable/intro.html)

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
      - [Job Cron](#job-cron)
  - [OpenSSL (Manual)](#openssl-manual)
    - [Instalação](#instalação)
    - [Renovação](#renovação)

## Requisitos e Dependências

- Certbot
  - [Docker e Docker-Compose](https://docs.docker.com/)
- OpenSSL
  - [OpenSSL](https://www.openssl.org/)
  - [Documentação](https://www.openssl.org/docs/)

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

### Docker-Compose

#### Volume

```yml
# certbot.docker-compose.yml (Em services.app)
# Aponte para as pastas/arquivos criadas anteriormente.

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

Inicie o seu Nginx com a seguinte configuração:

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

$ docker-compose -f certbot.docker-compose.yml run --rm app certonly --webroot --webroot-path=$certb_var1 -m $certb_var2 -d $certb_var3 --agree-tos
```

| Varíavel     | Descrição                                     |
| ------------ | --------------------------------------------- |
| \$certb_var1 | **Dir. ACME**                                 |
| \$certb_var2 | Endereço de Email.<br>Ex.: nutec@email.com    |
| \$certb_var3 | Domínio do site.<br>Ex.: servico.uneal.edu.br |

Dica.: você pode especificar mais de um domínio, separando-os por "," (virgula).


### Renovação Automática

#### Configurando os Scripts

1. Pasta com os Scripts [***scripts-certbot***](./scripts-certbot).
2. Copie a pasta/arquivos para o local de sua preferência.
3. Em [***certbot-run-renew.sh***](./scripts-certbot/certbot-run-renew.sh) configure as variáveis de ambiente.
4. Se necessário, utilize o [***certbot-post-renew.sh***](scripts-certbot/certbot-post-renew.sh) para rodar scripts/comandos após a renovação do certificado (somente será executado se a renovação for bem sucedida). Uma aplicação desse script é o "*reload*" das configurações do servidor após a renovação.

#### Job Cron

Adicione a seguinte configuração no crontab da máquina host.

```
#  Esse comando verificará e, se necessário, atualizará os certificados todos domingos às 00h:00m.

0 0 * * 0 ./$(pwd)/certbot-run-renew.sh
```

Obs.: altere o trecho ***\$(pwd)/certbot-run-renew.sh*** para o caminho do script na máquina alvo.



<br>

## OpenSSL (Manual)

### Instalação

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

### Renovação

Para renovar um certificado basta gerar um novo seguindo o mesmo processo descrito no secção [Instalação - Com OpenSSL (Manual)](#instalação---openssl).

- A geração da chave privada RSA é opcional. (Recomendado gerar uma nova).
- Se a chave ou o certificado forem gerados com nomes diferentes será necessário alterar o arquivo *nginx.conf*.
- Após realizar o processo reinicie o container do seu Nginx para que as mudança sejam aplicadas.