FROM ubuntu:20.04

# Update packages
RUN apt-get update

# Install tzdata first to avoid interactive questions
RUN apt-get -y install tzdata

# Install prerequisites
RUN apt-get -y install build-essential g++ openjdk-8-jdk-headless \
    postgresql-client python3 python3-pip cppreference-doc-en-html \
    cgroup-lite libcap-dev zip wget curl python3-dev libpq-dev \
    libcups2-dev libyaml-dev libffi-dev locales

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install go
ENV GO_VERSION=1.19.1
WORKDIR /
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-`dpkg --print-architecture`.tar.gz -O go.tar.gz
RUN rm -rf /usr/local/go \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm -rf go.tar.gz
ENV PATH=${PATH}:/usr/local/go/bin

# Build and install dockerize
RUN apt-get -y install git \
    && git clone https://github.com/jwilder/dockerize.git
WORKDIR /dockerize
COPY arm_linux.patch arm_linux.patch
RUN git apply arm_linux.patch \
    && make dist \
    && cp dist/linux/`dpkg --print-architecture`/dockerize /usr/local/bin/ \
    && rm -rf /dockerize

# Get CMS
WORKDIR /
RUN git clone --recurse-submodules https://github.com/cms-dev/cms.git cms

# Install dependencies
WORKDIR /cms
RUN pip3 install -r requirements.txt

# Build and install CMS
RUN python3 prerequisites.py --as-root build
RUN python3 prerequisites.py --as-root install
RUN python3 setup.py install

# Copy helper scripts
ADD scripts/ /scripts/

# Create an empty config file, we will mount the real one during startup
RUN touch /usr/local/etc/cms.conf

# Expose logs
VOLUME ["/var/local/log/cms"]

# Expose ports
EXPOSE 8888
EXPOSE 8889

# Run 
USER cmsuser
CMD ["/scripts/cms_start.sh"]
