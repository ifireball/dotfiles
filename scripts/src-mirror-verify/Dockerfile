FROM fedora:43

RUN dnf install -y git jq bash findutils curl tar unzip gnutls && dnf clean all

ARG CHEZMOI_VERSION=2.62.0
ARG GHQ_VERSION=1.8.0
RUN curl -fsSL "https://github.com/twpayne/chezmoi/releases/download/v${CHEZMOI_VERSION}/chezmoi_${CHEZMOI_VERSION}_linux_amd64.tar.gz" \
  | tar -xz -C /usr/local/bin chezmoi \
  && curl -fsSL -o /tmp/ghq.zip "https://github.com/x-motemen/ghq/releases/download/v${GHQ_VERSION}/ghq_linux_amd64.zip" \
  && unzip -p /tmp/ghq.zip ghq_linux_amd64/ghq > /usr/local/bin/ghq \
  && chmod +x /usr/local/bin/ghq \
  && rm -f /tmp/ghq.zip

RUN useradd -m -s /bin/bash testuser
USER testuser
WORKDIR /home/testuser

ENV HOME=/home/testuser
ENV PATH="/home/testuser/.local/bin:${PATH}"

ENTRYPOINT ["/bin/bash"]
