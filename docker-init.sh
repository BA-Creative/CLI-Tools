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
# Download WP
wp core download --allow-root;
# Create WP config
wp config create --allow-root --dbname="${MYSQL_DATABASE}" --dbuser="${MYSQL_USER}" --dbpass="${MYSQL_PASSWORD}" --dbhost="database:3306";

# Set WP config
wp config set --allow-root WP_DEBUG true;
wp config set --allow-root WP_DEBUG_LOG true;
wp config set --allow-root WP_DEBUG_DISPLAY true;
wp config set --allow-root WP_ALLOW_REPAIR true;
# Install default WP
wp core install --allow-root --url="http://localhost:${LOCAL_PORT_PHP}" --title="${WP_PROJECT_NAME}" --admin_user="${WP_ADMIN_USER}" --admin_password="${WP_ADMIN_PASS}" --admin_email="admin@example.com" --skip-email;
# Remove default themes and plugins
rm -rf /var/www/html/wp-content/themes/twenty*;
rm -rf /var/www/html/wp-content/plugins/akismet;
rm /var/www/html/wp-content/plugins/hello.php;
# Install required plugins
# --- ACF Pro
acf_zip_file="/advanced-custom-fields-pro.zip";
curl --output ${acf_zip_file} "https://connect.advancedcustomfields.com/v2/plugins/download?p=pro&k=${ACF_KEY}";
wp plugin install ${acf_zip_file} --allow-root --activate;
rm ${acf_zip_file};
# --- CF7
wp plugin install contact-form-7 --allow-root --activate;
# --- Flamingo
wp plugin install flamingo --allow-root --activate;
# --- WP Mail SMTP
wp plugin install wp-mail-smtp --allow-root --activate;

# ===================================
# Install Sage theme and dependencies
# ===================================
composer create-project roots/sage "${WP_PROJECT_HANDLE}" --working-dir=/var/www/html/wp-content/themes;
cd /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}";
composer require roots/acorn;
composer require log1x/acf-composer;
composer require log1x/sage-directives;
composer require log1x/sage-svg;

# Replace "base" in vite.config.js
sed -i "s|base: .*|base: '/app/themes/${WP_PROJECT_HANDLE}/public/build/',|" vite.config.js;
# Append "server" property to vite.config.js
sed -i "/export default defineConfig({/a server: { host: 'localhost', port: ${LOCAL_PORT_NPM}, strictPort: true, https: false }," vite.config.js;

# Set up sage .env file
printf "APP_URL=http://localhost:${LOCAL_PORT_PHP}" > /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}"/.env;
# Install NPM dependencies
npm install;
npm install swiper;
printf "\nimport Swiper from 'swiper/bundle';\n" >> /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}"/resources/js/app.js;

# Build assets
#npm run build;

# ===================================
# Clone RoxyPress
# ===================================
git clone git@github.com:BA-Creative/${WP_TEMPLATE_REPO}.git /var/www/git-temp;

#rsync -av --exclude='.git' --exclude='.gitignore' --ignore-existing /var/www/git-temp/ /var/www/html/wp-content;
#rm -rf /var/www/git-temp;
rm -rf /var/www/html/wp-content/themes/${WP_PROJECT_HANDLE}/resources;

rsync -av /var/www/git-temp/themes/roxypress-lite/resources/ /var/www/html/wp-content/themes/${WP_PROJECT_HANDLE}/resources;
rsync -av /var/www/git-temp/themes/roxypress-lite/app/custom.php /var/www/html/wp-content/themes/${WP_PROJECT_HANDLE}/app/;
rsync -av /var/www/git-temp/themes/roxypress-lite/db/ /var/www/html/wp-content/themes/${WP_PROJECT_HANDLE}/db;
rm -rf /var/www/git-temp;

# ===================================
# Activate theme
# ===================================
cd /var/www/html;
wp theme activate "${WP_PROJECT_HANDLE}" --allow-root;

cd /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}";

# Build assets
npm run build;
# npm run dev;

# (cd /var/www/html/wp-content/themes/"${WP_PROJECT_HANDLE}" && npm run dev &);
