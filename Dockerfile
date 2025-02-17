FROM debian:10-slim AS ssl
WORKDIR /ssl/
RUN apt update && apt-get install -y libnss3-tools curl
RUN curl -JLO "https://dl.filippo.io/mkcert/latest?for=linux/amd64"
RUN chmod +x mkcert-v*-linux-amd64
RUN mv mkcert-v*-linux-amd64 /usr/local/bin/mkcert
RUN mkcert -key-file server.key -cert-file server.crt localhost 127.0.0.1 ::1

FROM httpd:2.4

ENV DOCKERIZE_VERSION v0.6.1
RUN apt-get update && apt-get install -y wget \
    && wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ENV PORTA_PHP=9000
ENV TIMEOUT_PHP=60s

COPY httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf
COPY httpd-php.conf /usr/local/apache2/conf/extra/httpd-php.conf

COPY --from=ssl /ssl/server.crt /usr/local/apache2/conf/server.crt
COPY --from=ssl /ssl/server.key /usr/local/apache2/conf/server.key
RUN ls -la /usr/local/apache2/conf/

COPY sh/ /usr/local/bin/
RUN chmod +x /usr/local/bin/start

CMD ["start"]