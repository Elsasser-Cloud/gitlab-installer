#!/bin/bash

if [ ! -f /var/lib/gitlab/.first_login_complete ]; then

    clear # Clear the terminal for a clean start

    echo "----------------------------------------"
    echo "  ELSASSER CLOUD - GitLab Setup Wizard  "
    echo "----------------------------------------"

    step=1
    total_steps=5 # Adjust if you add/remove steps

    # 1. Get Domain and Email
    echo "[$step/$total_steps] Gathering information..."
    read -p "Enter your domain name (e.g., gitlab.example.com): " domain
    read -p "Enter your email address (for notifications and Let's Encrypt, if applicable): " email
    ((step++))

    # 2. Ask if SSL certificate is needed
    while true; do
        read -p "Do you want to enable HTTPS using Let's Encrypt? (y/n): " yn
        case $yn in
            [Yy]* ) enable_https=true; break;;
            [Nn]* ) enable_https=false; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
    ((step++))

    # 3. Install GitLab
    echo "[$step/$total_steps] Installing GitLab..."
    curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash >/dev/null 2>&1
    EXTERNAL_URL="http://$domain" # Set the external URL for GitLab
    if $enable_https; then
        EXTERNAL_URL="https://$domain"
    fi
    sudo apt install -y gitlab-ee >/dev/null 2>&1 # Or gitlab-ce for Community Edition
    ((step++))

    if $enable_https; then
        # 4. Request Let's Encrypt Certificate and Configure HTTPS
        echo "[$step/$total_steps] Requesting SSL certificate and configuring HTTPS..."
        sudo gitlab-ctl reconfigure >/dev/null 2>&1
        sudo certbot --nginx -d "$domain" --agree-tos --email "$email" --non-interactive >/dev/null 2>&1
        ((step++))
    fi

    touch /var/lib/gitlab/.first_login_complete

    echo "----------------------------------------"
    echo "  GitLab setup complete!               "
    echo "  Access it at $EXTERNAL_URL           "
    echo "----------------------------------------"
fi
