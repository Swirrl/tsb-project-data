rails_env = ENV['RAILS_ENV'] || 'production'
no_of_unicorns = ENV['UNICORNS'] || 4
worker_processes no_of_unicorns.to_i
timeout 60
preload_app true

RAILS_ROOT = '/pmd'

stderr_path RAILS_ROOT + '/log/unicorn.log'
stdout_path RAILS_ROOT + '/log/unicorn.log'

listen 8080 # just listen to a port 
pid RAILS_ROOT + '/tmp/unicorn/pids/unicorn.pid'

before_fork do |server, worker|
  # Close connections that require sockets
  old_pid = RAILS_ROOT + '/tmp/unicorn/pids/unicorn.pid.oldbin'
  if File.exist?(old_pid) && server.pid != old_pid
    begin
      Process.kill('QUIT', File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # Start connections that require sockets (e.g. analytics etc.)
end
