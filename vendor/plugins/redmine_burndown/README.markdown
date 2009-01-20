# Redmine Burndowns

## Installation
The Redmine Burndowns plugin depends on the excellent googlecharts gems by Matt Aimonetti. This can be installed with:

  sudo gem install mattetti-googlecharts --source=http://gems.github.com
  
If you'd like, you may also unpack the gem into your Redmine deploy by adding the following to your environment.rb file:

  config.gem 'mattetti-googlecharts', :lib => 'gchart', :version => ">=1.3.6"

and then running:

  rake gems:unpack