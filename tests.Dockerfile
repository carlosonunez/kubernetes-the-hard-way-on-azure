FROM python:3.8
MAINTAINER Carlos Nunez <dev@carlosnunez.me>

RUN pip install ansible ansible[azure]
ENTRYPOINT ["bash" ]
CMD ["-c", "sleep infinity"]
