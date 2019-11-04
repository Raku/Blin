# Run with a volume mounted as /Blin/output, e.g:
# docker run -ti -v /var/tmp/blin:/Blin/output ...
#
# The image takes the same parameters as blin.p6, e.g.:
# docker run -ti -v /var/tmp/blin:/Blin/output nxadm:blin SomeModuleHere AnotherModuleHere
FROM debian:buster-slim
LABEL maintainer="Claudio Ramirez <pub.claudio@gmail.com>"

COPY . /Blin/
ENV LANG='C.UTF-8'
ENV DEBIAN_FRONTEND='noninteractive'
ENV TZ='Europe/Brussels'
ENV pkgs_first="gpg ca-certificates"
ENV PATH="/opt/rakudo-pkg/bin:/opt/rakudo-pkg/share/perl6/bin:/mnt/bin:${PATH}"
ENV PERL6LIB="/mnt/lib"

RUN apt-get update && apt-get install -y $pkgs_first && \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 379CE192D401AB61 && \
echo "deb https://dl.bintray.com/nxadm/rakudo-pkg-debs buster main" > \
/etc/apt/sources.list.d/rakudo-pkg.list
RUN mkdir -p /usr/share/man/man1 && apt-get update && set -xv ;\
apt-get install -y $(cat /Blin/docker/pkg-dependencies |grep -v '^#')
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config
RUN cd /Blin && zef install --verbose --deps-only .

ENTRYPOINT [ "/Blin/docker/entrypoint.sh" ]
