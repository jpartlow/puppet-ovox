source ENV['GEM_SOURCE'] || 'https://rubygems.org'

# These two provide ed25519 key support for net-ssh
gem 'ed25519', ['>= 1.4', '< 2.0']
gem 'bcrypt_pbkdf', ['>= 1.1', '< 2.0']

group :test do
  gem 'voxpupuli-test', '~> 14.0',  :require => false
  gem 'puppet_metadata', '~> 6.1',  :require => false
  gem 'openbolt', '~> 5.0' # provides bolt_spec for tests
end
