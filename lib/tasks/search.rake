namespace :search do

  desc 'deletes our index'
  task delete_index: :environment do
    Project.index.delete
  end

  # e.g. DEBUG=true BATCH_SIZE=100 rake search:import_projects
  desc 'imports all the exiting projects in the database into the index. Can be slow.'
  task import_projects: :environment do
    batch_size = ENV['BATCH_SIZE'] || 300

    total = Project.count
    processed = 0

    while processed < total do

      puts "processed #{processed} projects of #{total}..."
      criteria = Project.all.limit(batch_size).offset(processed)

      query_pre_time = Time.now
      resources = criteria.resources.to_a      
      puts "query took #{Time.now - query_pre_time}s"
      
      response = Project.index.import resources
      processed += resources.length

      if response.success?      
        parse_pre_time = Time.now
        body =  JSON.parse(response.body)
        puts "parse took #{Time.now - parse_pre_time}s"

        puts "imported #{body['items'].length} items in #{body['took']}ms"
      else
        puts "fail"
        puts response
      end
      puts response if ENV['DEBUG']
      Project.index.refresh

    end
  end

  # e.g. DEBUG=true rake search:reimport_projects
  desc 'imports all the exiting projects in the database into the index'
  task reimport_projects: :environment do
    Rake::Task['search:delete_index'].invoke
    Rake::Task['search:import_projects'].invoke
  end

end