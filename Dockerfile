FROM ubuntu:14.04

MAINTAINER Ric Roberts "ric@swirrl.com"

RUN apt-get update
  
# Install rvm/Rails dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install software-properties-common && \
  apt-get update && \
  apt-get install -y tar wget curl nano git nodejs npm automake bison

# for rvm
RUN gpg --allow-non-selfsigned-uid --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 BF04FF17
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c 'rvm requirements'
RUN /bin/bash -l -c 'rvm install 1.9.3-p448'
RUN /bin/bash -l -c 'rvm use 1.9.3-p448 --default'

# No documentation for each gem
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc

# bundler
RUN /bin/bash -l -c 'gem install bundler --no-ri --no-rdoc'

# Copy the Gemfile and Gemfile.lock into the image.
# Temporarily set the working directory to where they are.
RUN mkdir /pmd
WORKDIR /tmp
ADD ./Gemfile Gemfile
ADD ./Gemfile.lock Gemfile.lock
RUN /bin/bash -l -c "bundle install"

# Add start-server script
ADD docker/start-server-production.sh /usr/bin/start-server-production
# Add rails files from current directory
ADD ./ /pmd

# Permissions
RUN chmod +x /pmd
RUN chmod +x /usr/bin/start-server-production

# Make a place for Unicorn pids and sockets to go
RUN mkdir -p /pmd/tmp/unicorn/pids
RUN mkdir /pmd/tmp/unicorn/sockets

# Set working directory
WORKDIR /pmd

# Symlink node and nodejs
RUN /bin/bash -l -c "ln -s /usr/bin/nodejs /usr/bin/node"

# Precompile assets
RUN /bin/bash -l -c "bundle install"
RUN /bin/bash -l -c "bundle exec rake assets:precompile RAILS_ENV=production RAILS_GROUPS=assets"

# copy public dir out, and allow it to be mounted at runtime (the start script moves them back in case we mount a dir)
RUN cp -r /pmd/public /pmd/docker/public

VOLUME ["/pmd/log", "/pmd/public"]

# serve the unicorns
EXPOSE 8080

# Start the unicorn server
CMD ["/usr/bin/start-server-production"]


