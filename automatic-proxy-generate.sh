: > $CONF_DEST

cat << 'EOL' >> $CONF_DEST
proxy_redirect off;
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

server {
  listen 80 default_server;
  listen [::]:80 default_server;
EOL

[ "$3" = 'https' ] && cat << 'EOL' >> $CONF_DEST
  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  ssl_certificate /certs/server.crt;
  ssl_certificate_key /certs/server.key;
  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;
  ssl_dhparam /etc/ssl/certs/dhparam.pem;
  ssl_protocols TLSv1.2;
  ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;
  ssl_prefer_server_ciphers on;
  add_header Strict-Transport-Security max-age=15768000;
  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 8.8.8.8 8.8.4.4;
EOL

cat << 'EOL' >> $CONF_DEST
}
EOL

gen() {
cat << EOL >> $CONF_DEST
server {
  server_name $1.*;
EOL

[ "$3" = 'https' ] && cat << 'EOL' >> $CONF_DEST
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  ssl_certificate /certs/server.crt;
  ssl_certificate_key /certs/server.key;
  ssl_session_timeout 1d;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;
  ssl_dhparam /etc/ssl/certs/dhparam.pem;
  ssl_protocols TLSv1.2;
  ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256;
  ssl_prefer_server_ciphers on;
  add_header Strict-Transport-Security max-age=15768000;
  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 8.8.8.8 8.8.4.4;
EOL

cat << 'EOL' >> $CONF_DEST
  location / {
    if (!-f $request_filename) {
EOL

cat << EOL >> $CONF_DEST
      proxy_pass $3://$1.rancher.internal:$2;
EOL

cat << 'EOL' >> $CONF_DEST
      break;
    }
  }
}
EOL
}

for name in $(docker ps --format "{{ .Names }}")
  do eval_env="docker inspect $name | jq --raw-output '.[].Config.Env | .[]'"
  host=$(docker inspect $name | jq --raw-output '.[].Config.Hostname')
  port=`(eval ${eval_env}) | grep '^PROXY_PASS_PORT=[[:digit:]]*' | cut --delimiter = --fields 2`

  (eval ${eval_env}) |
    grep '^PROXY_PASS_PORT=[[:digit:]]*' > /dev/null &&
      (eval ${eval_env}) |
        grep '^PROXY_PASS_SSL_ENABLED=true' > /dev/null &&
          gen $host $port 'https' &&
            break

  (eval ${eval_env}) |
    grep '^PROXY_PASS_PORT=[[:digit:]]*' > /dev/null &&
      gen $host $port 'http'
done

nginx -t && nginx -s reload