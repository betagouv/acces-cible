namespace :db do
  namespace :schema do
    task create: :environment do
      return if Rails.env.test?

      [:cable, :cache, :queue].each do |schema|
        name = "acces_cible_#{schema}"
        ActiveRecord::Base.connection.create_schema(name, if_not_exists: true)
        puts "Created schema: #{name}"
      end
    end
  end

  # Force Rails to create all schemas before loading into them
  task create_and_load_schemas: [:create, "schema:create", "schema:load"]

  # Replace prepare and setup with the fixed task above
  Rake::Task[:prepare].clear.enhance [:create_and_load_schemas, :seed]
  Rake::Task[:setup].clear.enhance [:create_and_load_schemas, :seed]
end
