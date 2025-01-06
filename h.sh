#!/bin/bash

######################
#     CONSTANTES     #
######################

## Redis ##
HONEYPOT_DIR="/opt/redis_honeypot"
HONEYPOT_USER="redis_honeypot"
REDIS_CONF="/etc/redis/redis_honeypot.conf"
DUMP_FILE="$HONEYPOT_DIR/dump.rdb"
REDIS_PORT="6379"
REDIS_PASSWORD="SuperWeakPassword123"

## General ##
TMP=$(mktemp -d)
read -p "non-root username: " USER

######################
#     FUNCTIONS      #
######################

## Log to std in ##
log() {
    echo -e "\e[1;32m[+]\e[0m $1" | tee "$TMP/log.log"
}

error() {
    echo -e "\e[1;31m[-]\e[0m $1" | tee "$TMP/log.log"
    exit 1
}

## Install dep and setup service ##
install_pkg() {
    if apt update > "$TMP/apt.log" 2>&1 && apt install redis-server curl nginx openssl nginx-extras tree -y >> "$TMP/apt.log" 2>&1; then
        log "Dependencies installed"
    else
        error "Failed to install dependencies $TMP/apt.log"
    fi
}

service_start_and_enable() {
    systemctl daemon-reload
    systemctl disable redis-server redis
    systemctl stop redis-server redis 
    systemctl enable nginx redis_honeypot
    systemctl restart nginx redis_honeypot

}

service_verif() {
    systemctl status nginx redis redis_honeypot
    echo "============================================="
    ss -tulns
    echo "============================================="
    tree $TMP
    echo "============================================="
    df -h
}

footprint() {
    log "Clear log"
    journalctl --vacuum-time=1h
    rm -f /var/log/wtmp /var/log/btmp /var/log/lastlog /root/.bash_history

    log "Replace history"
    history -c
    history -w
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/history/root.txt >> /root/.bash_history
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/history/user.txt >> /home/$USER/.bash_history
    chmod 444 /home/$USER/.bash_history
    chown $USER:$USER /home/$USER/.bash_history

    # Change password
    passwd root
    passwd $USER
}

fortideceptor() {
    MOUNT=$(mktemp -d)
    mount /dev/sr1 $MOUNT
    bash $MOUNT/Ubuntu/install_ubuntu_modules.sh | tee "$TMP/forti.log"
    bash $MOUNT/Ubuntu/decoy_strace_installation.sh | tee "$TMP/forti.log"
    bash $MOUNT/Ubuntu/ubuntu_cus_toolkit.sh | tee "$TMP/forti.log"

}


## Honey setup ##
honey_redis() {
    log "Create user for redis honeypots"
    useradd -r -s /bin/false $HONEYPOT_USER
    mkdir -p $HONEYPOT_DIR
    chown $HONEYPOT_USER:$HONEYPOT_USER $HONEYPOT_DIR
    chown -R $HONEYPOT_USER:$HONEYPOT_USER /etc/redis/

    log "Redis config"
    cat > $REDIS_CONF<<EOL
    bind 0.0.0.0
    protected-mode no
    port $REDIS_PORT
    requirepass "$REDIS_PASSWORD"
    dir $HONEYPOT_DIR
    dbfilename "dump.rdb"

    # Désactiver les commandes critiques
    rename-command CONFIG ""
    rename-command SHUTDOWN ""
    rename-command FLUSHALL ""
    rename-command FLUSHDB ""
    rename-command DEBUG ""

    # Simulations crédibles
    notify-keyspace-events KEA
    logfile /dev/null
    maxmemory 50mb
    maxclients 10
EOL

    log "Génération de données crédibles pour un e-commerce..."
    redis-server --daemonize yes --port 6380 --requirepass "$REDIS_PASSWORD"
    sleep 2
    redis-cli -p 6380 -a "$REDIS_PASSWORD"<<EOL
    SET "user:1001" "Raphael Jamis"
    SET "user:1002" "Jane Dedand"
    SET "user:1003" "Alice Johnson"
    HSET "product:2001" "name" "Laptop" "price" "1200" "stock" "45"
    HSET "product:2002" "name" "Smartphone" "price" "800" "stock" "150"
    HSET "product:2003" "name" "Headphones" "price" "150" "stock" "80"
    LPUSH "orders" '{"order_id": "3001", "user": "1001", "product": "2001", "quantity": "1", "total": "1200"}'
    LPUSH "orders" '{"order_id": "3002", "user": "1003", "product": "2002", "quantity": "2", "total": "1600"}'
    SET "stats:total_sales" "2800"
    SET "stats:active_users" "150"
EOL

    log "Sauvegarde des données dans dump.rdb..."
    redis-cli -p 6380 -a "$REDIS_PASSWORD" SAVE
    mv /var/lib/redis/dump.rdb $DUMP_FILE
    chown $HONEYPOT_USER:$HONEYPOT_USER $DUMP_FILE

    redis-cli -p 6380 -a "$REDIS_PASSWORD" SHUTDOWN
    sleep 2

    log "Configuration du service systemd pour le honeypot..."
    cat > /etc/systemd/system/redis_honeypot.service<<EOL
    [Unit]
    Description=Redis Service
    After=network.target
    [Service]
    ExecStart=/usr/bin/redis-server $REDIS_CONF
    User=$HONEYPOT_USER
    Group=$HONEYPOT_USER
    RuntimeDirectory=redis_honeypot
    ProtectSystem=full
    ProtectHome=yes
    NoNewPrivileges=yes
    PrivateTmp=yes
    ReadOnlyPaths=/
    ReadWritePaths=$HONEYPOT_DIR

    [Install]
    WantedBy=multi-user.target
EOL

    log "Bind redis to 0.0.0.0 in /etc/redis.conf"
    sed -i 's/^bind 127\.0\.0\.1 ::1$/bind 0.0.0.0/' /etc/redis/redis.conf
    log "Honeypot Redis configuré avec succès !"
}

honey_nginx() {
    log "Create /etc/nginx/nginx.conf"
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/nginx/nginx.conf > /etc/nginx/nginx.conf

    log "/etc/nginx/sites-available/notssl.conf"
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/nginx/notssl.conf > /etc/nginx/sites-available/notssl.conf

    log "/etc/nginx/sites-available/ssl.conf"
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/nginx/ssl.conf > /etc/nginx/sites-available/ssl.conf

    log "Enable site with ln -s"
    ln -s /etc/nginx/sites-available/ssl.conf /etc/nginx/sites-enabled/
    ln -s /etc/nginx/sites-available/notssl.conf /etc/nginx/sites-enabled/

    log "Delete default page"
    rm -f /etc/nginx/sites-enabled/default

    log "Dl html page" 
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/www/index.html > /var/www/html/index.html
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/www/api-auth-error.html > /var/www/html/api-auth-error.html
    curl -s https://raw.githubusercontent.com/r648r/DirtyNginx/refs/heads/main/www/api-forbidden.html > /var/www/html/api-forbidden.html

    for file in /var/www/html/*.html; do
      echo "<script>fetch('http://172.17.13.222/HoneyPotsCustom', {method: 'GET',mode: 'no-cors',})</script>" >> "$file"
    done
}

setup_ssl() {
    read -p "Pays (Code ISO) : " COUNTRY
    read -p "État : " STATE
    read -p "Ville : " CITY
    read -p "Organisation : " ORGANIZATION
    read -p "Unité d'organisation : " ORG_UNIT
    read -p "Nom commun (ex: localhost) : " COMMON_NAME

    log "Create folder in /etc/ssl/certs and keys in /etc/ssl/private"
    mkdir -p /etc/ssl/certs /etc/ssl/private

    for PORT in 9091 9191 7001 5001; do
        if openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout /etc/ssl/private/secure${PORT}.key \
            -out /etc/ssl/certs/secure${PORT}.crt \
            -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORG_UNIT/CN=$COMMON_NAME"; then
            log "Cert and key created $PORT."
        else
            error "Failed to create SSL for $PORT." >&2
        fi
    done
}


#################
#     MAIN      #
#################
# Checks
[ "$EUID" -ne 0 ] && error "Veuillez exécuter ce script en tant que root."
ping -c 1 8.8.8.8 > /dev/null 2>&1 || error "Internet failed"
ping -c 1 google.jp > /dev/null || error "DNS failed"

# Init
setup_ssl
install_pkg

# Setup
honey_nginx
honey_redis
service_start_and_enable
footprint

service_verif
fortideceptor
service_verif
