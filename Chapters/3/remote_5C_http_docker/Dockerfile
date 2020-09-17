# custom dcoker file for rhel7.3 based httpd
FROM rhel7.3
LABEL description="This is a custom httpd container  image"
MAINTAINER 'chap5_author'
RUN yum -y update && \
    yum install -y httpd && \
    yum clean all
EXPOSE 80
ENV LogLevel "info"
ARG httpd_folder=""
# COPY ./$httpd_folder/  /var/www/html/
# RUN echo "ServerName 127.0.0.1" >> /var/www/httpd.conf
# USER apache
# ENTRYPOINT ["/usr/sbin/httpd"]
CMD ["httpd","-C","ServerName 127.0.0.1", "-D", "FOREGROUND"]