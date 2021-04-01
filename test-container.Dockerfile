FROM python:3.8
MAINTAINER Carlos Nunez <dev@carlosnunez.me>
ARG cfssl_version=1.4.1
ARG kubectl_version=1.18.6

RUN apt -y update
RUN apt -y install openssh-server && mkdir /var/run/sshd
RUN echo "root:docker" | chpasswd
ENTRYPOINT [ "bash" ]
CMD [ "-c", "sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && service ssh start && sleep infinity" ]

RUN pip install azure-cli
RUN apt -y install curl
RUN for tool in cfssl cfssljson; \
    do \
      curl -o /usr/local/bin/$tool "https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/$cfssl_version/linux/$tool" && \
      chmod +x /usr/local/bin/$tool; \
    done; \
    curl -Lo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v$kubectl_version/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl
RUN apt -y install jq
RUN pip install yq
