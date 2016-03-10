#!/bin/bash

cd /pmd
source /etc/profile.d/rvm.sh

# copy the public dir back in (so the mounted vol gets it)
rm -r /pmd/public/*
cp -rf /pmd/docker/public /pmd

# unicorn daeomised so we can run nginx
bundle exec unicorn_rails -c ./config/unicorn.rb -E production
