namespace :db do  
  desc "Syncs local database with production"
  task :sync do
    puts 'Syncing local database with production...'

    db_config = Rails.configuration.database_configuration
    database_name = db_config['development']['database']

    begin
      `heroku pgbackups:capture`
      `curl -o latest.dump \`heroku pgbackups:url\``
      `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d #{database_name} latest.dump`
    ensure
      `rm latest.dump`
    end
  end
end
