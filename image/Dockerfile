FROM osixia/web-baseimage:1.2.0

# Install apache2 from web-baseimage

# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/install-service-available
# https://github.com/osixia/docker-web-baseimage/tree/stable/image/service-available/:apache2
RUN apt-get -y update \
    && /container/tool/add-service-available :apache2 :ssl-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add service directory to /container/service
ADD service /container/service

# Use baseimage install-service script
# https://github.com/osixia/docker-light-baseimage/blob/stable/image/tool/install-service
RUN /container/tool/install-service

# Add default env variables
ADD environment /container/environment/99-default

# Expose apache2 port
EXPOSE 443
