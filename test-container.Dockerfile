FROM python:3.8
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN apt -y update
RUN apt -y install openssh-server && mkdir /var/run/sshd
RUN echo "root:docker" | chpasswd
ENTRYPOINT [ "bash" ]
CMD [ "-c", "sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && service ssh start && sleep infinity" ]

RUN pip install azure-cli
