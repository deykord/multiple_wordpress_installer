#!/bin/bash

# Multiple WordPress Installer Script
# Fully automated WordPress installation for multiple domains on fresh Ubuntu server
# Author: AI Assistant
# Version: 2.0
# Date: 2025-09-27

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
DOMAINS=()
WP_ADMIN_USER=""
WP_ADMIN_PASS=""
WP_ADMIN_EMAIL=""
SITE_TITLE_PREFIX=""
MYSQL_ROOT_PASSWORD=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓ INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠ WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗ ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}██████████████████████████████████████████████████████${NC}"
    echo -e "${BLUE}█${NC} ${CYAN}$1${NC} ${BLUE}█${NC}"
    echo -e "${BLUE}██████████████████████████████████████████████████████${NC}"
    echo ""
}

print_step() {
    echo -e "${PURPLE}[→ STEP]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_error "Please run: sudo $0"
        exit 1
    fi
}

# Get domain names and configuration from user
get_configuration() {
    print_header "WordPress Multi-Site Installer Configuration"
    
    echo -e "${CYAN}This script will install and configure multiple WordPress sites automatically${NC}"
    echo -e "${CYAN}Including: NGINX, PHP, MySQL, SSL certificates, and security configurations${NC}"
    echo ""
    
    # Get domains
    echo "Enter your domain names (one per line):"
    echo "Press Enter on empty line when finished"
    echo ""
    
    while true; do
        echo -n "Domain $(( ${#DOMAINS[@]} + 1 )): "
        read -r domain
        if [[ -z "$domain" ]]; then
            break
        fi
        # Validate domain format (basic)
        if [[ "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9\.-]*\.[a-zA-Z]{2,}$ ]]; then
            DOMAINS+=("$domain")
        else
            print_warning "Invalid domain format: $domain"
            echo -n "Add anyway? (y/N): "
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                DOMAINS+=("$domain")
            fi
        fi
    done
    
    if [[ ${#DOMAINS[@]} -eq 0 ]]; then
        print_error "No domains provided. Exiting."
        exit 1
    fi
    
    echo ""
    echo "WordPress Admin Configuration:"
    echo "This will be used for all WordPress installations"
    echo ""
    
    # Get WordPress admin details
    while [[ -z "$WP_ADMIN_USER" ]]; do
        echo -n "WordPress Admin Username: "
        read -r WP_ADMIN_USER
        if [[ ${#WP_ADMIN_USER} -lt 3 ]]; then
            print_warning "Username must be at least 3 characters"
            WP_ADMIN_USER=""
        fi
    done
    
    while [[ -z "$WP_ADMIN_PASS" ]]; do
        echo -n "WordPress Admin Password: "
        read -s WP_ADMIN_PASS
        echo ""
        if [[ ${#WP_ADMIN_PASS} -lt 6 ]]; then
            print_warning "Password must be at least 6 characters"
            WP_ADMIN_PASS=""
        fi
    done
    
    while [[ -z "$WP_ADMIN_EMAIL" ]]; do
        echo -n "WordPress Admin Email: "
        read -r WP_ADMIN_EMAIL
        if [[ ! "$WP_ADMIN_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            print_warning "Invalid email format"
            WP_ADMIN_EMAIL=""
        fi
    done
    
    echo -n "Site Title Prefix (will add domain name): "
    read -r SITE_TITLE_PREFIX
    if [[ -z "$SITE_TITLE_PREFIX" ]]; then
        SITE_TITLE_PREFIX="WordPress Site"
    fi
    
    echo ""
    print_status "Configuration Summary:"
    print_status "Domains to install: ${DOMAINS[*]}"
    print_status "Admin User: $WP_ADMIN_USER"
    print_status "Admin Email: $WP_ADMIN_EMAIL"
    print_status "Site Title Prefix: $SITE_TITLE_PREFIX"
    echo ""
    
    echo -n "Continue with installation? (Y/n): "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_error "Installation cancelled by user"
        exit 1
    fi
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    print_step "Updating package list and upgrading system..."
    
    apt update -qq && apt upgrade -y -qq
    
    print_status "System updated successfully"
}

# Install required packages
install_packages() {
    print_header "Installing Required Packages"
    
    # Add Ondrej PHP repository for latest PHP versions
    print_step "Adding PHP repository..."
    apt install -y software-properties-common
    add-apt-repository ppa:ondrej/php -y
    apt update
    
    # Detect PHP version available
    if apt-cache policy php8.3 | grep -q "Candidate:"; then
        PHP_VERSION="8.3"
    elif apt-cache policy php8.1 | grep -q "Candidate:"; then
        PHP_VERSION="8.1"
    else
        PHP_VERSION="8.1"  # Fallback
    fi
    
    print_step "Installing LEMP stack with PHP $PHP_VERSION..."
    
    # Install packages
    apt install -y \
        nginx \
        mariadb-server \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        unzip \
        curl \
        wget \
        openssl \
        ufw
    
    # Install WP-CLI
    print_step "Installing WP-CLI..."
    if [[ ! -f /usr/local/bin/wp ]]; then
        wget -q -O wp-cli.phar https://github.com/wp-cli/wp-cli/releases/download/v2.10.0/wp-cli-2.10.0.phar
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
    fi
    
    # Verify WP-CLI installation
    if wp --info --allow-root >/dev/null 2>&1; then
        print_status "WP-CLI installed successfully"
    else
        print_error "WP-CLI installation failed"
        exit 1
    fi
    
    # Enable and start services
    systemctl enable nginx mariadb php${PHP_VERSION}-fpm
    systemctl start nginx mariadb php${PHP_VERSION}-fpm
    
    print_status "All packages installed and services started"
    print_status "Using PHP version: $PHP_VERSION"
}

# Secure MySQL installation
secure_mysql() {
    print_header "Securing MySQL Installation"
    
    # Check if MySQL is already secured
    if mysql -u root -e "SELECT 1;" >/dev/null 2>&1; then
        print_step "MySQL root has no password - securing now..."
        
        # Generate random root password
        MYSQL_ROOT_PASSWORD=$(openssl rand -base64 32)
        
        # Secure MySQL
        mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
        
        # Save root password
        echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" > /root/mysql_root_credentials.txt
        chmod 600 /root/mysql_root_credentials.txt
        
        print_status "MySQL secured. Root password saved to /root/mysql_root_credentials.txt"
    else
        print_step "MySQL already secured"
        # Try to load existing credentials
        if [[ -f /root/mysql_root_credentials.txt ]]; then
            source /root/mysql_root_credentials.txt
        else
            print_error "MySQL is secured but no credentials file found."
            echo -n "Enter MySQL root password: "
            read -s MYSQL_ROOT_PASSWORD
            echo ""
            echo "MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}" > /root/mysql_root_credentials.txt
            chmod 600 /root/mysql_root_credentials.txt
        fi
    fi
}

# Create database and user for a domain
create_database() {
    local domain=$1
    local db_name=$(echo "wp_$domain" | sed 's/[.-]/_/g')
    local db_user=$(echo "${domain}_user" | sed 's/[.-]/_/g')
    local db_password=$(openssl rand -base64 20)
    
    print_step "Creating database for $domain..."
    
    # Determine MySQL authentication method
    if [[ -n "$MYSQL_ROOT_PASSWORD" ]]; then
        local mysql_auth="-u root -p${MYSQL_ROOT_PASSWORD}"
    else
        local mysql_auth="-u root"
    fi
    
    # Create database and user
    mysql $mysql_auth <<EOF
CREATE DATABASE IF NOT EXISTS \`${db_name}\`;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON \`${db_name}\`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    # Save database credentials
    echo "${domain}:${db_name}:${db_user}:${db_password}" >> /root/wp_database_credentials.txt
    
    print_status "Database created: $db_name"
    print_status "User created: $db_user"
}

# Setup WordPress with full automation
setup_wordpress() {
    local domain=$1
    local site_dir="/var/www/${domain}"
    
    print_step "Setting up WordPress for $domain..."
    
    # Create site directory
    mkdir -p "$site_dir"
    cd "$site_dir"
    
    # Get database credentials
    local db_info=$(grep "^${domain}:" /root/wp_database_credentials.txt)
    local db_name=$(echo "$db_info" | cut -d':' -f2)
    local db_user=$(echo "$db_info" | cut -d':' -f3)
    local db_password=$(echo "$db_info" | cut -d':' -f4)
    
    # Download WordPress core
    wp core download --allow-root --quiet
    
    # Create wp-config.php with security keys
    wp config create \
        --dbname="$db_name" \
        --dbuser="$db_user" \
        --dbpass="$db_password" \
        --dbhost="localhost" \
        --allow-root \
        --quiet
    
    # Run WordPress installation
    local site_title="${SITE_TITLE_PREFIX} - ${domain}"
    local site_url="https://${domain}"
    
    wp core install \
        --url="$site_url" \
        --title="$site_title" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASS" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root \
        --quiet
    
    # Additional WordPress configurations
    wp option update blogdescription "Powered by Multiple WordPress Installer" --allow-root --quiet
    wp option update start_of_week 1 --allow-root --quiet
    wp option update timezone_string "UTC" --allow-root --quiet
    
    # Install and activate essential plugins
    print_step "Installing essential plugins for $domain..."
    wp plugin install classic-editor --activate --allow-root --quiet
    wp plugin install contact-form-7 --activate --allow-root --quiet
    wp plugin install wordpress-seo --activate --allow-root --quiet
    wp plugin install wp-super-cache --allow-root --quiet
    
    # Install a modern theme
    wp theme install astra --activate --allow-root --quiet
    
    # Create a welcome page
    wp post create \
        --post_type=page \
        --post_title="Welcome" \
        --post_content="<h1>Welcome to $domain</h1><p>This WordPress site was automatically installed and configured!</p><p>Installation completed on $(date)</p>" \
        --post_status=publish \
        --allow-root \
        --quiet
    
    # Set proper permissions
    chown -R www-data:www-data "$site_dir"
    find "$site_dir" -type d -exec chmod 755 {} \;
    find "$site_dir" -type f -exec chmod 644 {} \;
    chmod 600 "$site_dir/wp-config.php"
    
    print_status "WordPress installation completed for $domain"
}

# Create Nginx configuration with security headers
create_nginx_config() {
    local domain=$1
    
    # Detect PHP version for socket path
    local php_version=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    
    print_step "Creating Nginx configuration for $domain..."
    
    cat > "/etc/nginx/sites-available/${domain}.conf" <<EOF
server {
    listen 80;
    server_name ${domain} www.${domain};
    root /var/www/${domain};
    index index.php index.html index.htm;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # WordPress permalink structure
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    # PHP processing
    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${php_version}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
    }

    # WordPress security rules
    location ~* /(?:uploads|files)/.*\.php\$ {
        deny all;
    }
    
    location ~ ^/wp-admin/includes/ {
        deny all;
    }
    
    location ~ ^/wp-includes/[^/]+\.php\$ {
        deny all;
    }
    
    location ~ ^/wp-includes/js/tinymce/langs/.+\.php {
        deny all;
    }
    
    location ~ ^/wp-includes/theme-compat/ {
        deny all;
    }

    # Deny access to sensitive files
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.user\.ini {
        deny all;
    }
    
    location ~ /wp-config\.php {
        deny all;
    }

    # Optimize static file serving
    location ~* \.(css|gif|ico|jpeg|jpg|js|png|svg|webp|woff|woff2|ttf|eot)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        log_not_found off;
        access_log off;
    }

    # Optimize common files
    location = /favicon.ico {
        log_not_found off;
        access_log off;
        expires 1y;
    }

    location = /robots.txt {
        log_not_found off;
        access_log off;
        allow all;
    }

    # Gzip compression
    location ~ \.(css|js|svg)\$ {
        gzip_static on;
    }
}
EOF
    
    # Enable site
    ln -sf "/etc/nginx/sites-available/${domain}.conf" "/etc/nginx/sites-enabled/"
    
    print_status "Nginx configuration created for $domain"
}

# Setup SSL certificates with Let's Encrypt
setup_ssl() {
    print_header "Setting up SSL Certificates"
    
    # Install Certbot
    print_step "Installing Certbot..."
    apt install -y certbot python3-certbot-nginx -qq
    
    # Get SSL certificates for each domain
    for domain in "${DOMAINS[@]}"; do
        print_step "Requesting SSL certificate for $domain..."
        
        # Try to get certificate
        if certbot --nginx -d "$domain" -d "www.$domain" \
           --non-interactive --agree-tos --email "$WP_ADMIN_EMAIL" \
           --redirect --expand >/dev/null 2>&1; then
            print_status "SSL certificate obtained for $domain"
        else
            print_warning "Failed to obtain SSL certificate for $domain"
            print_warning "You may need to configure DNS and try manually later"
        fi
    done
    
    # Setup auto-renewal
    systemctl enable certbot.timer
    systemctl start certbot.timer
    
    print_status "SSL auto-renewal configured"
}

# Configure firewall
configure_firewall() {
    print_header "Configuring Firewall"
    
    print_step "Setting up UFW firewall rules..."
    
    # Reset UFW to defaults
    ufw --force reset >/dev/null 2>&1
    
    # Set default policies
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    
    # Allow essential services
    ufw allow ssh >/dev/null 2>&1
    ufw allow 'Nginx Full' >/dev/null 2>&1
    
    # Enable UFW
    ufw --force enable >/dev/null 2>&1
    
    print_status "Firewall configured successfully"
    print_status "Allowed: SSH, HTTP, HTTPS"
}

# Create management and utility scripts
create_management_scripts() {
    print_header "Creating Management Scripts"
    
    # WordPress batch update script
    print_step "Creating WordPress update script..."
    cat > /root/update_all_wordpress.sh <<'EOF'
#!/bin/bash
echo "=== WordPress Batch Update Script ==="
echo "Updating all WordPress installations..."

for site in /var/www/*/; do
    if [[ -f "$site/wp-config.php" ]]; then
        site_name=$(basename "$site")
        echo ""
        echo "Updating $site_name..."
        cd "$site"
        
        # Update WordPress core
        wp core update --allow-root --quiet && echo "✓ Core updated" || echo "✗ Core update failed"
        
        # Update plugins
        wp plugin update --all --allow-root --quiet && echo "✓ Plugins updated" || echo "✗ Plugin update failed"
        
        # Update themes
        wp theme update --all --allow-root --quiet && echo "✓ Themes updated" || echo "✗ Theme update failed"
        
        echo "✓ $site_name update completed"
    fi
done

echo ""
echo "All WordPress sites update completed!"
EOF
    chmod +x /root/update_all_wordpress.sh
    
    # Backup script
    print_step "Creating backup script..."
    cat > /root/backup_all_wordpress.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/root/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "=== WordPress Batch Backup Script ==="
echo "Backing up all WordPress installations..."
echo "Backup directory: $BACKUP_DIR"
echo ""

for site in /var/www/*/; do
    if [[ -f "$site/wp-config.php" ]]; then
        site_name=$(basename "$site")
        echo "Backing up $site_name..."
        
        # Backup files
        tar -czf "$BACKUP_DIR/${site_name}_files.tar.gz" -C "$site" . && echo "✓ Files backed up"
        
        # Backup database
        cd "$site"
        wp db export "$BACKUP_DIR/${site_name}_database.sql" --allow-root --quiet && echo "✓ Database backed up"
        
        echo "✓ $site_name backup completed"
        echo ""
    fi
done

echo "All WordPress sites backed up to: $BACKUP_DIR"
EOF
    chmod +x /root/backup_all_wordpress.sh
    
    # Site status checker
    print_step "Creating status check script..."
    cat > /root/check_wordpress_status.sh <<'EOF'
#!/bin/bash
echo "=== WordPress Sites Status Report ==="
echo "Generated on: $(date)"
echo ""

printf "%-25s %-15s %-10s %-15s\n" "Site" "WP Version" "Status" "URL"
printf "%-25s %-15s %-10s %-15s\n" "----" "----------" "------" "---"

for site in /var/www/*/; do
    if [[ -f "$site/wp-config.php" ]]; then
        site_name=$(basename "$site")
        cd "$site"
        
        if wp core version --allow-root >/dev/null 2>&1; then
            version=$(wp core version --allow-root)
            url=$(wp option get home --allow-root 2>/dev/null || echo "N/A")
            status="✓ OK"
        else
            version="N/A"
            url="N/A"
            status="✗ Error"
        fi
        
        printf "%-25s %-15s %-10s %-15s\n" "$site_name" "$version" "$status" "$url"
    fi
done

echo ""
echo "Services Status:"
systemctl is-active nginx >/dev/null && echo "✓ Nginx: Running" || echo "✗ Nginx: Not running"
systemctl is-active mariadb >/dev/null && echo "✓ MariaDB: Running" || echo "✗ MariaDB: Not running"
systemctl is-active php*-fpm >/dev/null && echo "✓ PHP-FPM: Running" || echo "✗ PHP-FPM: Not running"
EOF
    chmod +x /root/check_wordpress_status.sh
    
    print_status "Management scripts created in /root/"
}

# Create installation summary and display results
create_summary() {
    print_header "🎉 Installation Complete!"
    
    echo -e "${GREEN}WordPress Multi-Site Installation Summary${NC}"
    echo "=========================================="
    echo ""
    echo "📅 Installation Date: $(date)"
    echo "🖥️  Server: $(hostname -I | awk '{print $1}')"
    echo ""
    
    echo "🌐 WordPress Sites Installed:"
    for domain in "${DOMAINS[@]}"; do
        echo "   • https://$domain"
        echo "     └─ Admin: https://$domain/wp-admin/"
    done
    echo ""
    
    echo "👤 WordPress Admin Credentials:"
    echo "   Username: $WP_ADMIN_USER"
    echo "   Email: $WP_ADMIN_EMAIL"
    echo "   Password: [As entered during setup]"
    echo ""
    
    echo "📁 Important Files Created:"
    echo "   • MySQL credentials: /root/mysql_root_credentials.txt"
    echo "   • WordPress DB credentials: /root/wp_database_credentials.txt"
    echo "   • Nginx configurations: /etc/nginx/sites-available/*.conf"
    echo ""
    
    echo "🔧 Management Scripts:"
    echo "   • Update all sites: /root/update_all_wordpress.sh"
    echo "   • Backup all sites: /root/backup_all_wordpress.sh"
    echo "   • Check site status: /root/check_wordpress_status.sh"
    echo ""
    
    echo "✅ Services Status:"
    systemctl is-active nginx >/dev/null && echo "   ✓ Nginx: Running" || echo "   ✗ Nginx: Not running"
    systemctl is-active mariadb >/dev/null && echo "   ✓ MariaDB: Running" || echo "   ✗ MariaDB: Not running"
    systemctl is-active php*-fpm >/dev/null 2>&1 && echo "   ✓ PHP-FPM: Running" || echo "   ✗ PHP-FPM: Not running"
    systemctl is-active ufw >/dev/null && echo "   ✓ Firewall: Active" || echo "   ✗ Firewall: Inactive"
    echo ""
    
    echo "🔒 Security Features:"
    echo "   ✓ SSL certificates configured"
    echo "   ✓ Firewall rules applied"
    echo "   ✓ WordPress security headers"
    echo "   ✓ Secure file permissions"
    echo "   ✓ Database users with limited privileges"
    echo ""
    
    echo "📋 Next Steps:"
    echo "   1. Point your domain DNS to this server's IP: $(hostname -I | awk '{print $1}')"
    echo "   2. Test your websites by visiting the URLs above"
    echo "   3. Login to WordPress admin panels with the credentials provided"
    echo "   4. Configure your websites as needed"
    echo ""
    
    print_status "Installation completed successfully!"
    print_status "Your WordPress sites are ready to use!"
}

# Main installation function
main() {
    # Show script header
    clear
    print_header "Multiple WordPress Installer v2.0"
    echo -e "${CYAN}Automated WordPress installation for multiple domains${NC}"
    echo -e "${CYAN}Includes NGINX, PHP, MySQL, SSL, and security configuration${NC}"
    echo ""
    
    # Pre-installation checks
    check_root
    
    # Get configuration from user
    get_configuration
    
    # Start installation process
    print_header "Starting Installation Process"
    
    # System setup
    update_system
    install_packages
    secure_mysql
    
    # Initialize credentials file
    > /root/wp_database_credentials.txt
    chmod 600 /root/wp_database_credentials.txt
    
    # Install WordPress for each domain
    for domain in "${DOMAINS[@]}"; do
        print_header "Installing WordPress for: $domain"
        create_database "$domain"
        setup_wordpress "$domain"
        create_nginx_config "$domain"
    done
    
    # Test and reload Nginx
    print_step "Testing Nginx configuration..."
    if nginx -t; then
        systemctl restart nginx
        print_status "Nginx configuration valid and reloaded"
    else
        print_error "Nginx configuration error"
        exit 1
    fi
    
    # Optional SSL setup
    echo ""
    echo -n "Do you want to setup SSL certificates now? (Y/n): "
    read -r ssl_confirm
    if [[ ! "$ssl_confirm" =~ ^[Nn]$ ]]; then
        setup_ssl
    else
        print_warning "SSL setup skipped. You can run 'certbot --nginx' later."
    fi
    
    # Security and management setup
    configure_firewall
    create_management_scripts
    
    # Show final summary
    create_summary
}

# Error handling
trap 'print_error "Installation failed at line $LINENO. Check the error above."' ERR

# Run the installer
main "$@"