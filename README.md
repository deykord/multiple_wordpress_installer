# Multiple WordPress Installer

A powerful bash script for installing multiple WordPress websites on a fresh Ubuntu server with full automation. Includes NGINX, PHP, MySQL, SSL certificates, and security configurations.

## 🚀 Quick Installation (2-3 Commands)

### Method 1: One-Line Installation
```bash
# Install WordPress on multiple domains (replace with your details):
bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \
  -u admin -p MySecurePass123 -e admin@yourdomain.com \
  example.com blog.example.com shop.example.com
```

### Method 2: Clone and Run
```bash
# 1. Clone the repository
git clone https://github.com/deykord/multiple_wordpress_installer.git && cd multiple_wordpress_installer

# 2. Run with your domains and credentials
sudo bash multiple_wordpress_installer.sh -u admin -p MySecurePass123 -e admin@yourdomain.com example.com blog.example.com
```

### Method 3: Manual Download
```bash
# 1. Download the script
wget https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/multiple_wordpress_installer.sh

# 2. Make it executable and run
chmod +x multiple_wordpress_installer.sh
sudo ./multiple_wordpress_installer.sh -u admin -p MySecurePass123 -e admin@yourdomain.com example.com
```

## 📋 Command Line Options

| Option | Description | Required |
|--------|-------------|----------|
| `-u, --admin-user` | WordPress admin username | ✅ |
| `-p, --admin-pass` | WordPress admin password | ✅ |
| `-e, --admin-email` | WordPress admin email | ✅ |
| `-t, --title-prefix` | Site title prefix (default: "WordPress Site") | ❌ |
| `--no-ssl` | Skip SSL certificate setup | ❌ |
| `-h, --help` | Show help message | ❌ |

## 🌟 What Gets Installed

- **Web Server**: NGINX with optimized configurations
- **Database**: MariaDB with secure setup
- **PHP**: Latest available version (8.1/8.3) with required extensions
- **WordPress**: Latest version with essential plugins
- **SSL**: Let's Encrypt certificates (unless `--no-ssl` is used)
- **Security**: UFW firewall, security headers, file permissions
- **Tools**: WP-CLI, management scripts

## 🔧 Essential Plugins Included

- Classic Editor
- Contact Form 7
- Yoast SEO
- WP Super Cache
- Astra Theme (activated)

## 🛡️ Security Features

- ✅ SSL certificates via Let's Encrypt
- ✅ UFW firewall configuration
- ✅ NGINX security headers
- ✅ WordPress security rules
- ✅ Secure file permissions
- ✅ Individual database users per site
- ✅ Strong password generation

## 📁 Management Scripts Created

After installation, you'll find these scripts in `/root/`:

- **`update_all_wordpress.sh`** - Update all WordPress sites (core, plugins, themes)
- **`backup_all_wordpress.sh`** - Backup all sites (files + databases)
- **`check_wordpress_status.sh`** - Check status of all sites and services

## 🌐 Examples

### Single Domain
```bash
bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \
  -u admin -p MyPass123 -e admin@example.com \
  example.com
```

### Multiple Domains
```bash
bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \
  -u admin -p MyPass123 -e admin@example.com \
  site1.com site2.com site3.com
```

### Skip SSL (for testing)
```bash
bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \
  -u admin -p MyPass123 -e admin@example.com --no-ssl \
  example.com
```

### Custom Title Prefix
```bash
bash <(curl -s https://raw.githubusercontent.com/deykord/multiple_wordpress_installer/main/quick_install.sh) \
  -u admin -p MyPass123 -e admin@example.com \
  -t "My Blog" \
  example.com
```

## ⚠️ Prerequisites

- **Fresh Ubuntu Server** (20.04, 22.04, or newer)
- **Root access** (run with `sudo`)
- **Domain DNS** pointed to your server IP
- **Valid email** for SSL certificate registration

## 🔄 Post-Installation

1. **Point DNS**: Ensure your domains point to the server IP
2. **Test Sites**: Visit `https://yourdomain.com` to verify
3. **Admin Access**: Login at `https://yourdomain.com/wp-admin/`
4. **Customize**: Configure your WordPress sites as needed

## 📊 Installation Summary

After completion, you'll see:
- ✅ All installed domains and their admin URLs
- ✅ Admin credentials used
- ✅ Important file locations
- ✅ Management script paths
- ✅ Service status
- ✅ Next steps

## 🆘 Troubleshooting

### SSL Certificate Issues
```bash
# Manually setup SSL for a domain
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

### Check Service Status
```bash
# Run the status check script
/root/check_wordpress_status.sh
```

### Update All Sites
```bash
# Update WordPress core, plugins, and themes
/root/update_all_wordpress.sh
```

### Backup All Sites
```bash
# Create full backup of all sites
/root/backup_all_wordpress.sh
```

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📄 License

This project is open source and available under the [MIT License](LICENSE).
