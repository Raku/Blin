# Run with a volume mounted as /Blin/output, e.g:
# docker run -ti -v /var/tmp/blin:/Blin/output ...
#
# The image takes the same parameters as blin.p6, e.g.:
# docker run -ti -v /var/tmp/blin:/Blin/output nxadm:blin SomeModuleHere AnotherModuleHere
FROM debian:bookworm-slim
LABEL maintainer="Claudio Ramirez <pub.claudio@gmail.com>"

COPY . /Blin/
ENV LANG='C.UTF-8'
ENV DEBIAN_FRONTEND='noninteractive'
ENV TZ='Europe/Brussels'
ENV pkgs_first="gpg ca-certificates debian-keyring debian-archive-keyring apt-transport-https curl vim"
ENV PATH="/opt/rakudo-pkg/var/zef/bin:/opt/rakudo-pkg/bin:/opt/rakudo-pkg/share/perl6/bin:/mnt/bin:${PATH}"
ENV RAKULIB="/mnt/lib"

RUN apt-get update && apt-get install -y $pkgs_first && \
    curl -1sLf 'https://dl.cloudsmith.io/public/nxadm-pkgs/rakudo-pkg/gpg.0DD4CA7EB1C6CC6B.key' |  gpg --dearmor > /usr/share/keyrings/nxadm-pkgs-rakudo-pkg-archive-keyring.gpg && \
    curl -1sLf 'https://dl.cloudsmith.io/public/nxadm-pkgs/rakudo-pkg/config.deb.txt?distro=debian&codename=bookworm' > /etc/apt/sources.list.d/nxadm-pkgs-rakudo-pkg.list && \
    apt-get update

RUN mkdir -p /usr/share/man/man1 && apt-get update && set -xv ;\
apt-get install -y $(cat /Blin/docker/pkg-dependencies |grep -v '^#')
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN /opt/rakudo-pkg/bin/install-zef

# for zef look
RUN echo export SHELL=/bin/bash >> /etc/bash.bashrc

RUN cd /Blin && zef install --verbose --deps-only .

ENTRYPOINT [ "/Blin/docker/entrypoint.sh" ]
