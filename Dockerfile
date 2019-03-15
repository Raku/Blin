FROM rakudo-star:2018.10
LABEL maintainer="Kane Valentine <kane@cute.im>"

RUN set -ex; \
        \
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		build-essential \
		libfann-dev \
		libimage-magick-perl \
		libarchive13 \
		libmp3lame0 \
		libshout3 \
		libogg-dev \
		libvorbis-dev \
		libtagc0-dev \
		libcairo2-dev \
		libsnappy-dev \
		libodbc1 \
		libnotify4 \
		libusb-dev \
		libnotmuch-dev \
		libfreetype6 \
		libgd-dev \
		libgdbm-dev \
		libgtk-3-dev \
		libglfw3 \
		libsdl1.2-dev \
		libgumbo-dev \
		fonts-liberation \
		libexif12 \
		libqrencode3 \
		libgd-dev \
		libimlib2-dev \
		libperl-dev \
		libzmq3-dev \
		python-jupyter-core \
		python3-jupyter-core \
		liblmdb-dev \
		libcurl4-openssl-dev \
		libyaml-dev \
		libmagickwand-dev \
		libprimesieve-dev \
		libmsgpack-dev \
		libidn11-dev \
		libzmq3-dev \
		libopencv-dev \
		g++ \
		libssl1.0-dev \
		libreadline7 \
		libsdl1.2-dev \
		libsdl-mixer1.2-dev \
		libsdl-image1.2-dev \
		libssh-dev \
		libtcc-dev \
		golang-toml-dev \
		libtagc0-dev \
		libmarkdown2-dev \
		libtcc-dev \
		libnotify4 \
		fonts-dejavu-core \
		libgtk-3-dev \
		lrzip \
		zstd \
	; \
	\
	rm -rf /var/lib/apt/lists/*

WORKDIR /opt/perl6/blin
ADD $PWD /opt/perl6/blin

RUN zef install --deps-only $PWD

ARG rakudo_old=2018.10
ARG rakudo_new=HEAD

ENV RAKUDO_OLD $rakudo_old
ENV RAKUDO_NEW $rakudo_new

CMD PERL6LIB=lib bin/blin.p6 --old=$RAKUDO_OLD --new=$RAKUDO_NEW $MODULES; \
    cat output/overview*
