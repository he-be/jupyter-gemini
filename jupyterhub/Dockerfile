FROM jupyterhub/jupyterhub:4.0

# Install system dependencies
USER root
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir \
    dockerspawner==12.1.0 \
    oauthenticator==16.0.7 \
    psycopg2-binary==2.9.7 \
    jupyterhub-nativeauthenticator==1.2.0

# Create jupyterhub user and group
RUN groupadd -r jupyterhub && useradd -r -g jupyterhub jupyterhub

# Create necessary directories
RUN mkdir -p /srv/jupyterhub /var/log/jupyterhub
RUN chown -R jupyterhub:jupyterhub /srv/jupyterhub /var/log/jupyterhub

# Copy configuration files
COPY jupyterhub_config.py /srv/jupyterhub/
RUN chown jupyterhub:jupyterhub /srv/jupyterhub/jupyterhub_config.py

# Switch to jupyterhub user
USER jupyterhub

# Set working directory
WORKDIR /srv/jupyterhub

# Expose port
EXPOSE 8000

# Start JupyterHub
CMD ["jupyterhub", "-f", "/srv/jupyterhub/jupyterhub_config.py"]