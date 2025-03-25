FROM debian:bullseye-slim
LABEL maintainer="Juju>"
LABEL description="Database client tools for PostgreSQL, MongoDB, Redis and AWS CLI"

# Installation des dépendances de base
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    curl \
    wget \
    lsb-release \
    procps \
    vim \
    nano \
    less \
    netcat \
    iputils-ping \
    dnsutils \
    telnet \
    net-tools \
    jq \
    unzip \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Ajout des dépôts PostgreSQL avec la méthode sécurisée
RUN install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Ajout des dépôts MongoDB
RUN curl -fsSL https://pgp.mongodb.com/server-6.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg] http://repo.mongodb.org/apt/debian $(lsb_release -cs)/mongodb-org/6.0 main" > /etc/apt/sources.list.d/mongodb-org-6.0.list

# Installation des clients de bases de données
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client-15 \
    mongodb-mongosh \
    mongodb-org-tools \
    redis-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installation d'AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws awscliv2.zip

# Création d'un utilisateur non-root
RUN useradd -u 1000 -ms /bin/bash dbuser

# Préparation des dossiers pour les volumes
RUN mkdir -p /tmp /var/tmp /home/dbuser/.cache /home/dbuser/.config /home/dbuser/.aws && \
    chown -R dbuser:dbuser /home/dbuser /tmp /var/tmp

# Passage à l'utilisateur non-root
USER dbuser
WORKDIR /home/dbuser

# Ajout d'un script de bienvenue avec information AWS CLI
RUN echo '#!/bin/bash\necho "=== DB Tools ===" \necho "PostgreSQL: psql -h host -U username -d database" \necho "MongoDB: mongosh --host host --username username" \necho "Redis: redis-cli -h host -p 6379"\necho "AWS CLI: aws --version"\necho "====================="' > /home/dbuser/welcome.sh && \
    chmod +x /home/dbuser/welcome.sh

# Exécution du script de bienvenue au démarrage
ENTRYPOINT ["/bin/bash", "-c", "/home/dbuser/welcome.sh && exec /bin/bash"]

# Commande par défaut si aucune n'est spécifiée
CMD ["sleep", "infinity"]