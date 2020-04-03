FROM debian:buster as re2o_base
COPY ./apt_requirements.txt /var/www/re2o/apt_requirements.txt
COPY ./pip_requirements.txt /var/www/re2o/pip_requirements.txt
COPY ./install_utils/db.ldiff /var/www/re2o/install_utils/db.ldiff
COPY ./install_utils/schema.ldiff /var/www/re2o/install_utils/schema.ldiff
WORKDIR /var/www/re2o

# Install dependancies
RUN apt-get update && apt-get upgrade -y
RUN cat apt_requirements.txt | xargs apt-get -y install
RUN pip3 install -r pip_requirements.txt

# Install DB requirements
RUN apt-get install -y postgresql-client python3-psycopg2

# Install local LDAP
FROM re2o_base as re2o_ldap
ARG LDAP_PASSWORD=plopiplop
ARG LDAP_DN="dc=example,dc=net"

ENV LDAP_ROOTPASS plopiplop
ENV LDAP_ORGANISATION Re2o
ENV LDAP_DOMAIN example.net

RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y slapd
RUN hashed_ldap_passwd="$(slappasswd -s $LDAP_PASSWORD)" && sed 's|dc=example,dc=net|'"$LDAP_DN"'|g' /var/www/re2o/install_utils/db.ldiff | sed 's|FILL_IT|'"$hashed_ldap_passwd"'|g' > /tmp/db
RUN hashed_ldap_passwd="$(slappasswd -s $LDAP_PASSWORD)" && sed 's|dc=example,dc=net|'"$LDAP_DN"'|g' /var/www/re2o/install_utils/schema.ldiff | sed 's|FILL_IT|'"$hashed_ldap_passwd"'|g' > /tmp/schema
RUN service slapd stop
RUN rm -rf /etc/ldap/slapd.d/*
RUN rm -rf /var/lib/ldap/*
RUN slapadd -n 0 -l /tmp/schema -F /etc/ldap/slapd.d/
RUN slapadd -n 1 -l /tmp/db
RUN chown -R openldap:openldap /etc/ldap/slapd.d
RUN chown -R openldap:openldap /var/lib/ldap
RUN service slapd start

# Install apache
FROM re2o_ldap as re2o_apache
RUN apt-get -y install apache2 libapache2-mod-wsgi-py3
RUN a2enmod ssl
RUN a2enmod wsgi
RUN a2enconf javascript-common
COPY ./install_utils/apache2/re2o.conf /etc/apache2/sites-available/re2o.conf
RUN rm /etc/apache2/sites-enabled/000-default.conf
RUN sed -i 's|URL_SERVER|'"re2o.example.net"'|g' /etc/apache2/sites-available/re2o.conf
RUN sed -i 's|PATH|'"$(pwd)"'|g' /etc/apache2/sites-available/re2o.conf
RUN a2ensite re2o

# HERE WE GO
FROM re2o_apache as re2o
COPY ./re2o-dev.sh /var/www/re2o/
CMD bash re2o-dev.sh
