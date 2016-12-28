# https://github.com/asosso/maxscale-docker/blob/master/Dockerfile
FROM centos:7

RUN rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB \
    && yum -y install https://downloads.mariadb.com/enterprise/yzsw-dthq/generate/10.0/mariadb-enterprise-repository.rpm \
    && yum -y update \
    && yum -y install maxscale-2.0.1 \
    && yum clean all \
    && rm -rf /tmp/*

RUN mkdir -p /etc/maxscale.d \
    && cp /etc/maxscale.cnf.template /etc/maxscale.d/maxscale.cnf \
    && ln -sf /etc/maxscale.d/maxscale.cnf /etc/maxscale.cnf

COPY maxscale-entrypoint.sh /
COPY ./docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

#temp
# COPY maxscale.cnf /etc/maxscale.cnf

# VOLUME for custom configuration
VOLUME ["/etc/maxscale.d"]

# EXPOSE the MaxScale default ports
EXPOSE 3306 3307 3308 4442 6603

# We define the config creator as entrypoint
ENTRYPOINT ["/maxscale-entrypoint.sh"]

# We startup MaxScale as default command
CMD ["/usr/bin/maxscale","--nodaemon"]