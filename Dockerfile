FROM amazonlinux:2
WORKDIR /amon-todo

RUN yum update -y

# Git
RUN yum install -y git-all

# MySQL
RUN yum -y install yum-utils
RUN yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm -y
RUN yum-config-manager –enable mysql80-community
RUN rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
RUN yum install -y mysql-community-server
RUN yum install -y mysql-devel

# plenv
RUN yum install -y patch 
RUN yum install -y gcc
RUN git clone https://github.com/tokuhirom/plenv.git ~/.plenv
RUN git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
ENV PATH $PATH:~/.plenv/bin
RUN echo 'eval "$(plenv init -)"' >> ~/.bash_profile
RUN eval "$(plenv init -)"

# perl
RUN yum install tar -y
RUN plenv install 5.30.2
RUN plenv rehash
RUN plenv global 5.30.2

# cpanm
RUN plenv install-cpanm
RUN plenv which cpanm

# carton
RUN plenv exec cpanm Carton
RUN plenv rehash

# application
COPY . .
RUN rm -fr local
RUN plenv exec carton install

# entry point
CMD ["sh", "-c", "~/.plenv/bin/plenv exec carton exec -- plackup -Ilib -R ./lib --access-log /dev/null -p 5000 -a ./script/amon-todo-server"]
