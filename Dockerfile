FROM ubuntu:18.04
MAINTAINER ffdixon@bigbluebutton.org

ENV DEBIAN_FRONTEND noninteractive
ENV container docker

RUN apt-get update && apt-get install  -y netcat

# -- Test if we have apt cache running on docker host, if yes, use it.
RUN nc -zv host.docker.internal 3142 &> /dev/null && echo 'Acquire::http::Proxy "http://159.203.59.145:3142 ";'  > /etc/apt/apt.conf.d/01proxy

# -- Install utils
RUN apt-get update && apt-get install -y wget apt-transport-https

RUN apt-get install -y language-pack-en
RUN update-locale LANG=en_US.UTF-8

# -- Install system utils
RUN apt-get update
RUN apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y wget software-properties-common

# -- Setup tomcat to run under docker
RUN apt-get install -y \
  haveged    \
  net-tools  \
  supervisor \
  sudo       \
  tomcat8

# -- Modify systemd to be able to run inside container
RUN apt-get update \
    && apt-get install -y systemd

# -- Install Dependencies
RUN apt-get install -y mlocate strace iputils-ping telnet tcpdump vim htop

# -- Install dependicies for BigBlueButton packages
RUN wget https://deb.nodesource.com/gpgkey/nodesource.gpg.key -O- | apt-key add -
RUN add-apt-repository -y ppa:rmescandon/yq
RUN add-apt-repository -y ppa:bigbluebutton/support
RUN add-apt-repository -y ppa:libreoffice/ppa
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5AFA7A83
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.0.asc | sudo apt-key add -
RUN echo "deb [arch=amd64,arm64] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN echo "deb [arch=amd64] http://ubuntu.openvidu.io/6.13.0 bionic kms6" > /etc/apt/sources.list.d/kurento.list
RUN echo "deb https://deb.nodesource.com/node_12.x bionic main" > /etc/apt/sources.list.d/nodesource.list
RUN apt-get update

RUN apt-get install -y kurento-media-server nginx-full mongodb-org ffmpeg libreoffice tidy yq tidy h264-gst-plugins-bad-1.5 xmlstarlet git-core build-essential vorbis-tools sox mencoder ruby-dev libxslt1-dev libxml2-dev libncurses5-dev gnuplot zlib1g-dev python3 ruby rsync libsystemd-dev poppler-utils ttf-mscorefonts-installer ghostscript imagemagick psmisc
RUN gem install --no-ri --no-rdoc absolute_time builder fastimage:2.1.5 fnv java_properties journald-logger:2.0.4 jwt locale loofah:2.3.1 nokogiri:1.10.4 open4 rb-inotify:0.10.0 redis:4.1.2 rubocop rubyzip:1.3.0 trollop:2.1.3 ffi:1.11.1 crass:1.0.5 mono_logger  multi_json mustermann rack rack-protection redis-namespace tilt sinatra vegas resque
RUN apt-get install -y libldns2 liblua5.2-0 libopusenc0 libopusfile0 libspeexdsp1 netcat-openbsd python3-bs4 python3-html5lib python3-icu python3-lxml python3-webencodings gir1.2-freedesktop gir1.2-pango-1.0 libcurl4-openssl-dev libpangoxft-1.0-0 python3-attr python3-cairo
RUN apt-get install -y nodejs curl


# -- Install nginx (in order to enable it - to avoid the "nginx.service is not active" error)
#RUN apt-get install -y nginx
RUN systemctl enable nginx

# -- Disable unneeded services
RUN systemctl disable systemd-journal-flush
RUN systemctl disable systemd-update-utmp.service

# -- Install redis (in order to change bind ip before bbb-install)
RUN apt-get install -y redis-server debtree
RUN sed -i 's/bind 127.0.0.1 ::1/bind 127.0.0.1/g' /etc/redis/redis.conf
RUN sed -i 's/^supervised no/supervised systemd/g' /etc/redis/redis.conf
RUN mkdir -p /etc/systemd/system/redis-server.service.d
RUN echo "[Service]\nType=notify" > /etc/systemd/system/redis-server.service.d/override.conf




# Setup for BigBlueButton
RUN wget http://ubuntu.bigbluebutton.org/repo/bigbluebutton.asc -O- | apt-key add -
RUN mkdir -p /etc/nginx/ssl
RUN openssl dhparam -dsaparam -out /etc/nginx/ssl/dhp-4096.pem 4096

# -- Finish startup
#    Add a number there to force update of files on build
RUN echo "Finishing ........ @15"
RUN mkdir /opt/docker-bbb/
#RUN wget https://raw.githubusercontent.com/bigbluebutton/bbb-install/master/bbb-install.sh -O- | sed 's|https://\$PACKAGE_REPOSITORY|http://\$PACKAGE_REPOSITORY|g' > /opt/docker-bbb/bbb-install.sh
RUN wget https://ubuntu.bigbluebutton.org/bbb-install.sh -O- | sed 's|https://\$PACKAGE_REPOSITORY|http://\$PACKAGE_REPOSITORY|g' > /opt/docker-bbb/bbb-install.sh
RUN chmod 755 /opt/docker-bbb/bbb-install.sh
ADD setup.sh /opt/docker-bbb/setup.sh
ADD rc.local /etc/
RUN chmod 755 /etc/rc.local

ADD haveged.service /etc/systemd/system/default.target.wants/haveged.service


ENTRYPOINT ["/bin/systemd", "--system", "--unit=multi-user.target"]
# ENTRYPOINT ["/bin/bash"]
CMD []

