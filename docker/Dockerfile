FROM ubuntu:20.04
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update
RUN apt install -y git

# Contains envsubst, used to generate the config file
RUN apt install -y gettext

ENV WRAPPER_SCRIPT get-source

COPY  ./git-partial-clone.sh /usr/bin/git-partial-clone
COPY ./docker/git-partial-clone-docker.sh /usr/bin/${WRAPPER_SCRIPT}
COPY ./docker/git-partial-clone.conf /usr/bin/${WRAPPER_SCRIPT}.conf

WORKDIR /home/
ENTRYPOINT ["/bin/sh", "-c" , "${WRAPPER_SCRIPT} && tail -f /dev/null"]
