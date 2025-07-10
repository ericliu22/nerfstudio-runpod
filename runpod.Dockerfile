# -------------------------------------------------------------------------------
# RunPod + Nerfstudio SSH-able Template
# -------------------------------------------------------------------------------
ARG BASE_IMAGE=ghcr.io/nerfstudio-project/nerfstudio:latest
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# —————————————————————————————————————————————————————————————————————————————
# 1) Environment & workspace
# —————————————————————————————————————————————————————————————————————————————
ENV DEBIAN_FRONTEND=noninteractive \
    SHELL=/bin/bash \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

WORKDIR /workspace
VOLUME /workspace

# —————————————————————————————————————————————————————————————————————————————
# 2) Install system packages (SSH, Nginx, etc.)
# —————————————————————————————————————————————————————————————————————————————
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
      git \
      wget \
      curl \
      bash \
      libgl1 \
      software-properties-common \
      openssh-server \
      nginx && \
    rm -rf /var/lib/apt/lists/*

# Configure SSH for root login with a default password (you should override in production)
RUN mkdir -p /var/run/sshd && \
    echo 'root:runpod' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config

# —————————————————————————————————————————————————————————————————————————————
# 3) Python tooling (Jupyter, widgets, etc.)
# —————————————————————————————————————————————————————————————————————————————
ENV PATH=/opt/conda/bin:$PATH

RUN python3 -m pip install --upgrade --no-cache-dir \
      pip \
      jupyterlab \
      notebook==7.3.3 \
      ipywidgets \
      jupyter-archive

# —————————————————————————————————————————————————————————————————————————————
# 4) Nginx config & entrypoint script
# —————————————————————————————————————————————————————————————————————————————
# (place your nginx.conf next to this Dockerfile)
COPY proxy/nginx.conf /etc/nginx/nginx.conf
COPY proxy/readme.html /usr/share/nginx/html/readme.html

# startup script (see below)
COPY start.sh /start.sh
RUN chmod +x /start.sh

# —————————————————————————————————————————————————————————————————————————————
# 5) Expose ports
# —————————————————————————————————————————————————————————————————————————————
EXPOSE 22
EXPOSE 80
EXPOSE 8888

# —————————————————————————————————————————————————————————————————————————————
# 6) Default command
# —————————————————————————————————————————————————————————————————————————————
CMD ["/start.sh"]
