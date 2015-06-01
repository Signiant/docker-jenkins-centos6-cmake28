FROM signiant/docker-jenkins-centos-base:centos6
MAINTAINER devops@signiant.com

ENV BUILD_USER bldmgr
ENV BUILD_USER_GROUP users

# Set the timezone
RUN sed -ri '/ZONE=/c ZONE="America\/New York"' /etc/sysconfig/clock
RUN rm -f /etc/localtime && ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

RUN wget http://people.centos.org/tru/devtools-2/devtools-2.repo
RUN mv devtools-2.repo /etc/yum.repos.d/devtools-2.repo

# Install yum packages required for cmake build node
COPY yum-packages.list /tmp/yum.packages.list
RUN chmod +r /tmp/yum.packages.list
RUN yum install -y -q `cat /tmp/yum.packages.list`

#link to where version 4.8.x of GCC is installed for our make scripts

RUN ln -s /opt/rh/devtoolset-2/root/usr/bin/gcc /usr/local/bin/gcc
RUN ln -s /opt/rh/devtoolset-2/root/usr/bin/g++ /usr/local/bin/g++

#Remove native binary for c++ as we need the bin c++ linked to 4.8.2
RUN rm -f /usr/bin/c++
RUN ln -s /opt/rh/devtoolset-2/root/usr/bin/c++ /usr/bin/c++
RUN unlink /usr/lib/gcc/x86_64-redhat-linux/4.4.7
RUN ln -s /opt/rh/devtoolset-2/root/usr/lib/gcc/x86_64-redhat-linux/4.8.2 /usr/lib/gcc/x86_64-redhat-linux/4.4.7


# Install needed perl modules
RUN curl -L http://cpanmin.us | perl - App::cpanminus
COPY perl-modules.list /tmp/perl-modules.list
RUN chmod +r /tmp/perl-modules.list
RUN /bin/bash -l -c "cpanm `cat /tmp/perl-modules.list | tr \"\\n\" \" \"`"

# Install Compass
RUN gem update --system
RUN gem install compass

# Make sure anything/everything we put in the build user's home dir is owned correctly
RUN chown -R $BUILD_USER:$BUILD_USER_GROUP /home/$BUILD_USER  

EXPOSE 22

# This entry will either run this container as a jenkins slave or just start SSHD
# If we're using the slave-on-demand, we start with SSH (the default)

# Default Jenkins Slave Name
ENV SLAVE_ID JAVA_NODE
ENV SLAVE_OS Linux

ADD start.sh /
RUN chmod 777 /start.sh

CMD ["sh", "/start.sh"]
