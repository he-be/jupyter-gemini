# JupyterHub Configuration
import os
import sys

# Basic JupyterHub configuration
c.JupyterHub.ip = '0.0.0.0'
c.JupyterHub.port = 8000

# Hub IP configuration for Docker network
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.hub_connect_ip = 'jupyterhub'

# Database configuration
# Read password from file if available
db_password_file = os.environ.get('POSTGRES_PASSWORD_FILE', '/run/secrets/db_password')
if os.path.exists(db_password_file):
    with open(db_password_file, 'r') as f:
        db_password = f.read().strip()
else:
    db_password = os.environ.get('POSTGRES_PASSWORD', 'jupyterhub')

c.JupyterHub.db_url = f'postgresql://jupyterhub:{db_password}@db:5432/jupyterhub'

# Docker spawner configuration
c.JupyterHub.spawner_class = 'dockerspawner.DockerSpawner'

# Docker image for user containers
c.DockerSpawner.image = os.environ.get('DOCKER_NOTEBOOK_IMAGE', 'jupyter-user-gemini:latest')

# Docker network settings
c.DockerSpawner.network_name = os.environ.get('DOCKER_NETWORK_NAME', 'jupyterhub_network')
c.DockerSpawner.use_internal_ip = True

# Remove containers when they stop
c.DockerSpawner.remove = True

# User container naming
c.DockerSpawner.name_template = 'jupyter-{username}'

# CPU and memory limits
c.DockerSpawner.cpu_limit = float(os.environ.get('USER_CPU_LIMIT', '2.0'))
c.DockerSpawner.mem_limit = os.environ.get('USER_MEM_LIMIT', '4G')

# User volume configuration
notebook_dir = '/home/jovyan/work'
c.DockerSpawner.notebook_dir = notebook_dir

# Volume mounts for user data persistence
c.DockerSpawner.volumes = {
    'jupyterhub-user-{username}': {
        'bind': notebook_dir,
        'mode': 'rw'
    }
}

# Environment variables for user containers
c.DockerSpawner.environment = {
    'JUPYTER_ENABLE_LAB': 'yes',
    'GRANT_SUDO': 'yes'
}

# Security settings
c.JupyterHub.cookie_secret_file = '/run/secrets/jupyterhub_cookie_secret'

# Proxy auth token from secret file
proxy_token_file = '/run/secrets/proxy_auth_token'
if os.path.exists(proxy_token_file):
    with open(proxy_token_file, 'r') as f:
        c.ConfigurableHTTPProxy.auth_token = f.read().strip()
else:
    c.ConfigurableHTTPProxy.auth_token = os.environ.get('JUPYTERHUB_PROXY_AUTH_TOKEN', '')

# Authentication configuration
c.JupyterHub.authenticator_class = 'nativeauthenticator.NativeAuthenticator'

# Email-based authentication settings
c.NativeAuthenticator.check_common_password = True
c.NativeAuthenticator.minimum_password_length = 8
c.NativeAuthenticator.allowed_failed_logins = 3
c.NativeAuthenticator.ask_email_on_signup = True
c.NativeAuthenticator.allow_2fa = False  # Cloudflare handles primary authentication

# Admin users
admin_users = os.environ.get('JUPYTERHUB_ADMIN_USERS', 'admin@example.com').split(',')
c.Authenticator.admin_users = set(admin_users)

# Allow users to sign up (controlled by admin approval)
c.NativeAuthenticator.open_signup = os.environ.get('OPEN_SIGNUP', 'false').lower() == 'true'
c.NativeAuthenticator.enable_signup = True

# Allowed users (email addresses)
allowed_users = os.environ.get('ALLOWED_USERS', '').split(',')
if allowed_users and allowed_users[0]:  # Check if list is not empty
    c.Authenticator.allowed_users = set(user.strip() for user in allowed_users if user.strip())

# Email domain restriction (optional)
allowed_email_domains = os.environ.get('ALLOWED_EMAIL_DOMAINS', '').split(',')
if allowed_email_domains and allowed_email_domains[0]:
    c.NativeAuthenticator.allowed_email_domains = [domain.strip() for domain in allowed_email_domains if domain.strip()]

# Password reset configuration
c.NativeAuthenticator.enable_password_reset = True
c.NativeAuthenticator.password_reset_email_subject = "JupyterHub Password Reset"

# User approval workflow
c.NativeAuthenticator.authorize_existing_users = True  # Auto-approve users in allowed_users list

# Logging configuration
c.JupyterHub.log_level = os.environ.get('JUPYTERHUB_LOG_LEVEL', 'INFO')
c.Spawner.debug = os.environ.get('SPAWNER_DEBUG', 'false').lower() == 'true'

# Service configuration
c.JupyterHub.services = []

# Proxy configuration
c.ConfigurableHTTPProxy.debug = os.environ.get('PROXY_DEBUG', 'false').lower() == 'true'

# Idle timeout (optional)
if os.environ.get('IDLE_TIMEOUT'):
    c.NotebookApp.shutdown_no_activity_timeout = int(os.environ.get('IDLE_TIMEOUT'))

# Base URL configuration (for reverse proxy scenarios)
c.JupyterHub.base_url = os.environ.get('JUPYTERHUB_BASE_URL', '/')