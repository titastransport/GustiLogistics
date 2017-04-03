namespace :db do  
  desc "Syncs local database with production"
  task :sync do
    puts 'Syncing local database with production...'

    db_config = Rails.configuration.database_configuration
    database_name = db_config['development']['database']

    begin
      `heroku pg:backups:capture`
      `curl -o latest.dump \`heroku pg:backups:url\``
      `pg_restore --verbose --clean --no-acl --no-owner -h localhost -d #{database_name} latest.dump`
    ensure
      `rm latest.dump`
    end
  end

  namespace :seed do
    desc "Upload Unit Activity Reports"
    task :upload_uars => :environment do
      Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| require file }
      PATH_TO_DIR = Rails.root.join('db', 'seeds', 'uar', 'unit_activity_reports')
      dirs = [ PATH_TO_DIR.join('uars2015'), PATH_TO_DIR.join('uars2016'), PATH_TO_DIR.join('uars2017') ]
      dirs.each do |dir|
        Dir.foreach(dir) do |file|
          next if file.start_with? '.'
          file = "#{dir}/#{file}"
          ActivityImport.new(file: file).save
        end
      end
    end

    desc "Upload Items Sold to Customers reports" 
    task :upload_istcs => :environment do
      Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| require file }
      PATH_TO_DIR = Rails.root.join('db', 'seeds', 'items_sold')
      #dirs = [ PATH_TO_DIR.join('purchases_2015'), PATH_TO_DIR.join('purchases_2016'), PATH_TO_DIR.join('purchases_2017') ]
      dirs = [ PATH_TO_DIR.join('purchases_2017') ]
      dirs.each do |dir|
        Dir.foreach(dir) do |file|
          next if file.start_with? '.'
          file = "#{dir}/#{file}"
          PurchaseImport.new(file: file).save
        end
      end
    end
  end
end
