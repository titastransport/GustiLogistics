namespace :assets do  
  desc "Reset assets for Heroku"
  task :heroku do
    puts 'Resetting precompiled assets for deployment on Heroku...'
    `rake assets:clean`
    `RAILS_ENV=production rake assets:precompile`
  end
end
