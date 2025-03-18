namespace :accessibility do
  desc "Update axe-core to the latest version"
  task update_axe: :environment do
    require "open-uri"
    require "digest"

    axe_cdn_url = "https://cdn.jsdelivr.net/npm/axe-core/axe.min.js"
    axe_vendor_path = Rails.root.join("vendor/javascript/axe.min.js")
    axe_locale_url = "https://cdn.jsdelivr.net/npm/axe-core/locales/fr.json"
    axe_locale_path = Rails.root.join("vendor/javascript/axe.fr.json")

    new_content = URI.open(axe_cdn_url).read
    new_digest = Digest::SHA256.hexdigest new_content
    axe_version = new_content.match(/\/\*! axe v?(\d+\.\d+\.\d+)/).to_a&.last || "latest"

    if File.exist?(axe_vendor_path) && new_digest == Digest::SHA256.hexdigest(File.read(axe_vendor_path))
      puts "Axe-core JS is already up-to-date (current version: #{axe_version})"
      next
    else
      FileUtils.mkdir_p File.dirname(axe_vendor_path)
      File.write(axe_vendor_path, new_content)
      File.write(axe_locale_path, URI.open(axe_locale_url).read)
      puts "Added axe-core@#{axe_version} with French locale to #{axe_vendor_path}"
    end

    if system("git diff --name-only --cached --quiet")
      puts "Git staging area already contains changes, skipping commit"
      next
    else
      system("git add #{axe_vendor_path} #{axe_locale_path}")
      system("git commit -m 'chore: Update #{axe_vendor_path.basename} and French locale to #{axe_version}'")
      puts "Committed axe-core update to git"
    end
  end
end
