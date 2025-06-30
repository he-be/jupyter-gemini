# User environment Docker image with Gemini CLI
FROM jupyter/scipy-notebook:latest

# Switch to root for system installations
USER root

# Install Node.js and npm (required for Gemini CLI)
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Google AI/Gemini related tools
# Note: There's no official Gemini CLI npm package yet, so we'll prepare the environment
# for users to install Gemini-related tools as needed
RUN npm install -g \
    typescript \
    ts-node \
    @types/node

# Copy requirements file and install Python packages
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    && pip install --no-cache-dir pypdf \
    && rm /tmp/requirements.txt

# Install Jupyter extensions
RUN pip install --no-cache-dir \
    jupyterlab-git \
    jupyterlab-lsp \
    jupyter-ai \
    ipywidgets

# Enable Jupyter extensions
RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

# Create directory for user scripts and configs
RUN mkdir -p /opt/user-scripts /opt/user-configs

# Copy setup scripts
COPY gemini-setup.sh /opt/user-scripts/
RUN chmod +x /opt/user-scripts/gemini-setup.sh

# Set proper permissions
RUN fix-permissions /opt/user-scripts /opt/user-configs

# Switch back to jovyan user
USER ${NB_UID}

# Set environment variables
ENV NODE_PATH=/usr/lib/node_modules
ENV PATH=$PATH:/usr/bin/node:/usr/bin/npm

# Create workspace directory
RUN mkdir -p ${HOME}/work/projects ${HOME}/work/data ${HOME}/work/models

# Set working directory
WORKDIR ${HOME}/work

# Expose JupyterLab port (for standalone testing)
EXPOSE 8888

# Start command (will be overridden by JupyterHub)
CMD ["start-notebook.sh"]