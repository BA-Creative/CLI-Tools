#!/bin/bash

# RoxyPress - Shell Script Generator

# Prompt for Project Name
clear
printf "=========================================\n\n"
read -p "Enter Project Name: " SHELL__PROJECT_NAME
export SHELL__PROJECT_NAME
SHELL__PROJECT_NAME_HANDLE=$(echo "$SHELL__PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | sed 's/--/-/g')

mkdir $SHELL__PROJECT_NAME_HANDLE && cd $SHELL__PROJECT_NAME_HANDLE || exit 1

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

cat > "./.env" << EOF
MYSQL_ROOT_USER=root
MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=wp

# LOCAL DEV
LOCAL_PORT_PHP=8080
LOCAL_PORT_NPM=3000

# WORDPRESS
WP_DB_NAME=wp
WP_DB_USER=root
WP_DB_PASSWORD=root
WP_TEMPLATE_REPO=RoxyPress-Lite-V2
WP_BASE_THEME_DIR=roxypress-lite
WP_PROJECT_NAME="$SHELL__PROJECT_NAME"
WP_PROJECT_HANDLE="$SHELL__PROJECT_NAME_HANDLE"
WP_ADMIN_USER=admin
WP_ADMIN_PASS=admin

#ACF
ACF_KEY=MWQ0YjAxZWJlNDUwNzcxMTQzMDNmNDFjYzgwMDczYWIyNzExYTY2NDM3ZjYxMzFlMjY5YWQ4
EOF
    
cat > "./docker-compose.yml" << 'EOF'
services:

  database:
    image: mariadb:10.6.4-focal
    #restart: unless-stopped
    restart: "no"
    ports:
      - 3307:3306
    env_file: .env
    environment:
      MYSQL_ROOT_USER: '${MYSQL_ROOT_USER}'
      MYSQL_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
      MYSQL_DATABASE: '${MYSQL_DATABASE}'
    volumes:
      - db-data:/var/lib/mysql
      - ./_database:/backup # Mount the host directory for syncing the dump
    networks:
      - wordpress-network
    deploy:
      resources:
        limits:
          memory: 2048m
    command: >
      sh -c "
        apt-get update && apt-get install cron -y &&
        echo \"* * * * * mysqldump -u${MYSQL_ROOT_USER} -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > /backup/out.sql\" > /etc/cron.d/mysql-dump && 
        chmod 0644 /etc/cron.d/mysql-dump && crontab /etc/cron.d/mysql-dump && cron && 

        docker-entrypoint.sh mysqld;
      "

  phpmyadmin:
    depends_on:
      - database
    image: phpmyadmin/phpmyadmin
    restart: unless-stopped
    ports:
      - 8081:80
    env_file: .env
    environment:
      PMA_HOST: database
      MYSQL_ROOT_PASSWORD: '${MYSQL_ROOT_PASSWORD}'
    networks:
      - wordpress-network

  wordpress:
    depends_on:
      - database
    image: wordpress
    restart: unless-stopped
    #restart: "no"
    ports:
      - '${LOCAL_PORT_PHP}:80'
      - '${LOCAL_PORT_NPM}:${LOCAL_PORT_NPM}'
    env_file: .env
    environment:
      WORDPRESS_DB_HOST: database:3306
      WORDPRESS_DB_NAME: '${WP_DB_NAME}'
      WORDPRESS_DB_USER: '${WP_DB_USER}'
      WORDPRESS_DB_PASSWORD: '${WP_DB_PASSWORD}'
    volumes:
      - ./_wordpress:/var/www/html
      - ./docker-init.sh:/docker-init.sh
    networks:
      - wordpress-network
    command: >
      sh -c "
        if [ -d "/var/www/html/wp-content/themes/${WP_PROJECT_HANDLE}" ]; then
          (cd /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}" && npm run dev &);
        else
          chmod +x /docker-init.sh && /docker-init.sh;
        fi;
        docker-entrypoint.sh apache2-foreground;
      "

volumes:
  db-data:

networks:
  wordpress-network:
    driver: bridge
EOF

cat > "./docker-init.sh" << 'MAINEOF'
#!/bin/bash
set -e

# Update OS dependencies # =====================================================
# ==============================================================================
apt-get update;
apt-get install -y curl unzip vim rsync;

# Install Node.js and NPM # ====================================================
# ==============================================================================
curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh;
bash nodesource_setup.sh;
apt-get install -y nodejs;

# Install Composer # ===========================================================
# ==============================================================================
curl -sS https://getcomposer.org/installer | php;
mv composer.phar /usr/local/bin/composer;

# Install WP-CLI # =============================================================
# ==============================================================================
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
chmod +x wp-cli.phar;
mv wp-cli.phar /usr/local/bin/wp;

# Install Git-CLI # ============================================================
# ==============================================================================
apt install -y git-all;

# Clean up /var/www/html if not empty # ========================================
# ==============================================================================
# if [ -n "$(ls -A /var/www/html)" ]; then
#   rm -rf /var/www/html/*
# fi;

# Write multiline text to a file
if [ ! -d ~/.ssh/ ]; then
  mkdir ~/.ssh/;
fi
cat <<EOF > ~/.ssh/git.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH4+wUfAQ/j612no5JsaioUGGzg61phX2Q49eKV/5l73
EOF
cat <<EOF > ~/.ssh/git
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACB+PsFHwEP4+tdp6OSbGoqFBhs4OtaYV9kOPXilf+Ze9wAAAJjDVyWGw1cl
hgAAAAtzc2gtZWQyNTUxOQAAACB+PsFHwEP4+tdp6OSbGoqFBhs4OtaYV9kOPXilf+Ze9w
AAAEAJL5qa26thDn6wpP7fLnsHI9t8X54zSSvF2RNqgew/qX4+wUfAQ/j612no5JsaioUG
Gzg61phX2Q49eKV/5l73AAAAFG1hcnlvQEJBcy1pTWFjLmxvY2FsAQ==
-----END OPENSSH PRIVATE KEY-----
EOF

chmod 600 ~/.ssh/git;
chmod 644 ~/.ssh/git.pub;
eval "$(ssh-agent -s)";
ssh-add ~/.ssh/git;
ssh-keyscan -H github.com >> ~/.ssh/known_hosts;

# Set PHP.ini file # ===========================================================
# ==============================================================================
cat <<EOF > /usr/local/etc/php/conf.d/custom.ini
upload_max_filesize = 100M
display_errors = 1
upload_max_size =  256M
post_max_size = 256M
max_execution_time = 300
memory_limit = 512M
EOF

# WordPress setup # ============================================================
# ==============================================================================
cd /var/www/html;
# Download & Create wp-config.php
if [ ! -f wp-config.php ]; then
  wp core download --allow-root;
  wp config create --allow-root --dbname="${WP_DB_NAME}" --dbuser="${WP_DB_USER}" --dbpass="${WP_DB_PASSWORD}" --dbhost="database:3306";
fi

# Set WP config
wp config set --allow-root WP_DEBUG true;
wp config set --allow-root WP_DEBUG_LOG true;
wp config set --allow-root WP_DEBUG_DISPLAY true;
wp config set --allow-root WP_ALLOW_REPAIR true;
# Install default WP
wp core install --allow-root --url="http://localhost:${LOCAL_PORT_PHP}" --title="${WP_PROJECT_NAME}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASS}" --admin_email="admin@example.com" --skip-email;
# Remove default themes and plugins
rm -rf /var/www/html/wp-content/themes/twenty* || true;
rm -rf /var/www/html/wp-content/plugins/akismet || true;
rm /var/www/html/wp-content/plugins/hello.php || true;
# Install required plugins
# --- ACF Pro
if [ ! -d "/var/www/html/wp-content/plugins/advanced-custom-fields-pro" ]; then
  acf_zip_file="/advanced-custom-fields-pro.zip";
  curl --output ${acf_zip_file} "https://connect.advancedcustomfields.com/v2/plugins/download?p=pro&k=${ACF_KEY}";
  wp plugin install ${acf_zip_file} --allow-root --activate;
  rm ${acf_zip_file};
fi
# --- CF7
wp plugin install contact-form-7 --allow-root --activate;
# --- Flamingo
wp plugin install flamingo --allow-root --activate;
# --- WP Mail SMTP
wp plugin install wp-mail-smtp --allow-root --activate;

# ===================================
# Clone RoxyPress (Expects: wp-content)
# ===================================
git clone -b prod git@github.com:BA-Creative/$WP_TEMPLATE_REPO.git /var/www/git-repo-download;
rm -rf /var/www/git-repo-download/.git || true;
rm -rf /var/www/git-repo-download/.gitignore || true;

#rsync -av --exclude='.git' --exclude='.gitignore' --ignore-existing /var/www/git-repo-download/ /var/www/html/wp-content;
rsync -av /var/www/git-repo-download/ /var/www/html/wp-content/

# Rename folder
cd /var/www/html/wp-content/themes;
mv $WP_BASE_THEME_DIR $WP_PROJECT_HANDLE;
cd /var/www/html/wp-content/themes/$WP_PROJECT_HANDLE;

# Replace "base" in vite.config.js
sed -i "s|base: .*|base: '/app/themes/${WP_PROJECT_HANDLE}/public/build/',|" vite.config.js;
# Append "server" property to vite.config.js
sed -i "/export default defineConfig({/a server: { host: 'localhost', port: ${LOCAL_PORT_NPM}, strictPort: true, https: false }," vite.config.js;

# Set up sage .env file
printf "APP_URL=http://localhost:${LOCAL_PORT_PHP}" > /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}"/.env;

# Install dependencies
composer install;
npm install;

# Remove temporary git clone directory
rm -rf /var/www/git-repo-download;

# ===================================
# Activate theme
# ===================================
cd /var/www/html;
wp theme activate $WP_PROJECT_HANDLE --allow-root;

cd /var/www/html/wp-content/themes/$WP_PROJECT_HANDLE;

# Build assets
npm run build;
npm run dev;

MAINEOF

if ! command -v docker-compose &> /dev/null; then
  print_color "$YELLOW" "docker-compose not found. Attempting to install via Homebrew..."
  if command -v brew &> /dev/null; then
    brew install --cask docker
    brew install docker-compose
  else
    print_color "$RED" "Homebrew is not installed. Please install Homebrew or docker-compose manually."
    exit 1
  fi

else
  echo
fi

open -a "Docker" && docker-compose -f docker-compose.yml up -d --build

printf "\n=========================================\n\n"
print_color "$GREEN" "PHP: http://localhost:8080"
print_color "$GREEN" "NPM: http://localhost:3000"
printf "\n\n=========================================\n"
