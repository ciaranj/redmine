default_run_options[:pty] = true

set :application, "redmine"
set :repository,  "git@github.com:scrumalliance/redmine.git"
set :scm, 'git'

set :deploy_to, "/home/sa_deploy/#{application}"
set :branch, "master"
set :deploy_via, :remote_cache

set :scm_verbose, true

set :user, "sa_deploy"
set :group, "sa_deploy"

role :app, "scrum01.managed.contegix.com"
role :web, "scrum01.managed.contegix.com"
role :db, "scrum01.managed.contegix.com", :primary => true

after "deploy:update_code", :symlink_in_dblogin_yml_file
task :symlink_in_dblogin_yml_file do
  run "ln -fns  #{shared_path}/dblogin.yml #{release_path}/config/dblogin.yml"
end

namespace :deploy do
  task :restart do
    ''
  end
end