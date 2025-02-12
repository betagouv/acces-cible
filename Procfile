web: RAILS_MAX_THREADS=3 bundle exec puma -C config/puma.rb
worker: bin/jobs
postdeploy: bin/rails db:prepare db:seed
