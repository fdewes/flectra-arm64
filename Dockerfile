FROM ubuntu:18.04

EXPOSE 7073

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN adduser --system --quiet --shell=/bin/bash --home=/opt/flectra --gecos 'flectra' --group flectra
RUN mkdir /etc/flectra &&  mkdir /var/log/flectra/

RUN apt-get update &&  apt-get upgrade -y &&  apt-get install -y wget postgresql postgresql-contrib postgresql-server-dev-10 build-essential \
    python3-pil python3-lxml python-ldap3 python3-dev python3-pip python3-setuptools npm nodejs git gdebi libldap2-dev libsasl2-dev  \
    libxml2-dev libxslt1-dev libjpeg-dev 

RUN git clone --depth=1 --branch=1.0 https://gitlab.com/flectra-hq/flectra.git /opt/flectra/server
RUN chown flectra:flectra /opt/flectra/ -R &&  chown flectra:flectra /var/log/flectra/ -R && cd /opt/flectra/server
RUN cd /opt/flectra/server && pip3 install -r requirements.txt
RUN npm install -g less@3.0.4 less-plugin-clean-css -y 
RUN ls -lah /usr/bin 

RUN cd /tmp && wget http://launchpadlibrarian.net/233197537/libpng12-0_1.2.54-1ubuntu1_arm64.deb &&  dpkg -i libpng12-0_1.2.54-1ubuntu1_arm64.deb 
RUN cd /tmp && wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_arm64.deb && gdebi -n wkhtmltox_0.12.6-1.bionic_arm64.deb && rm wkhtmltox_0.12.6-1.bionic_arm64.deb

RUN /etc/init.d/postgresql start && \
    su - postgres -c "createuser -s flectra"

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/10/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/10/main/postgresql.conf

RUN su - flectra -c "/opt/flectra/server/flectra-bin --addons-path=/opt/flectra/server/addons -s --stop-after-init"
RUN mv /opt/flectra/.flectrarc /etc/flectra/flectra.conf
RUN sed -i "s,^\(logfile = \).*,\1"/var/log/flectra/flectra-server.log"," /etc/flectra/flectra.conf
RUN sed -i "s,^\(logrotate = \).*,\1"True"," /etc/flectra/flectra.conf
RUN sed -i "s,^\(proxy_mode = \).*,\1"True"," /etc/flectra/flectra.conf
RUN cp /opt/flectra/server/debian/init /etc/init.d/flectra && chmod +x /etc/init.d/flectra
RUN ln -s /opt/flectra/server/flectra-bin /usr/bin/flectra
RUN update-rc.d -f flectra defaults


CMD /etc/init.d/postgresql start && /usr/sbin/service flectra start && sleep infinity
