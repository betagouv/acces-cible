# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create a team
team = FactoryBot.create(:team, siret: '12345678901234')

# Create tags

tag1 = FactoryBot.create(:tag, name: "Gouv", team:)
tag2 = FactoryBot.create(:tag, name: "Private", team:)
tag3 = FactoryBot.create(:tag, name: "Public", team:)

# Create a user associated with the team
user = FactoryBot.create(:user,
                         provider: 'developer',
                         uid: '123456789',
                         email: 'user@example.com',
                         given_name: 'Test',
                         usual_name: 'User',
                         siret: team.siret
)

# Create sites for the team
sites = [
  FactoryBot.create(:site, team:, url: 'https://beta.gouv.fr', tags: [tag1, tag3]),
  FactoryBot.create(:site, team:, url: 'https://www.example.com', tags: [tag2]),
  FactoryBot.create(:site, team:, url: 'https://www.example-2.com')
]

puts "Created user #{user.email} with team (uid: #{user.uid} siret: #{team.siret}) and #{sites.count} sites"
