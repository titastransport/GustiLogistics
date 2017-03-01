namespace :db do  
  desc "Syncs local database with production"
  task :sync do
    puts 'Syncing local database with production...'

    db_config = Rails.configuration.database_configuration
    database_name = db_config['development']['database']

    begin
      `heroku pg:backups:capture`
      `curl -o latest.dump \ heroku pg:backups:url`
      `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d #{database_name} latest.dump`
    ensure
      `rm latest.dump`
    end
  end

  namespace :seed do
    desc "Upload Unit Activity Reports"
    task :upload_uars => :environment do
      Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| require file }
      # Specify which producer by director that their UAR's are located
      PATH_TO_DIR = "#{Rails.root}/db/seeds/uar/unit_activity_reports/santeustachio2015"
      Dir.foreach(PATH_TO_DIR) do |file|
        next if file.start_with? '.'
        file = "#{PATH_TO_DIR}/#{file}"
        ActivityImport.new(file: file).save
      end
    end
  end
end
