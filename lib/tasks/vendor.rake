namespace :vendor do
  namespace :update do
    desc "Update axe-core JavaScript library"
    task axe: :environment do
      download_and_update(
        name: "axe-core",
        path: "vendor/javascript/axe.min.js",
        url: "https://cdn.jsdelivr.net/npm/axe-core/axe.min.js",
      )
    end

    desc "Update axe-core French localization"
    task axe_locale: :environment do
      download_and_update(
        name: "axe-core French locale",
        path: "vendor/javascript/axe.fr.json",
        url: "https://cdn.jsdelivr.net/npm/axe-core/locales/fr.json",
      )
    end

    desc "Update Puppeteer stealth evasions"
    task stealth: :environment do
      puts "Updating stealth.min.js..."
      file_path = "vendor/javascript/stealth.min.js"

      Dir.chdir(Rails.root.join("vendor/javascript")) do
        system("npx extract-stealth-evasions > /dev/null 2>&1") || abort("Failed to update stealth.min.js")
      end

      # Check if only the generated date changed
      diff_output = `git diff --unified=0 #{file_path}`.to_s
      changed_lines = diff_output.lines.select { |line| line.start_with?("+", "-") && !line.start_with?("+++", "---") }
      only_date_changed = changed_lines.length == 2 && changed_lines.all? { |line| line.include?("Generated on:") }

      if changed_lines.empty? || only_date_changed
        puts "✓ stealth.min.js is already up-to-date"
        system("git checkout -- #{file_path}") if only_date_changed
      else
        puts "✓ stealth.min.js updated"
      end
    end
  end

  desc "Update all vendored dependencies"
  task update: :environment do
    Rake::Task["vendor:update:axe"].invoke
    Rake::Task["vendor:update:axe_locale"].invoke
    Rake::Task["vendor:update:stealth"].invoke
    puts "\n✓ All vendored dependencies are up-to-date"
  end

  private

  def download_and_update(url:, path:, name:)
    require "open-uri"
    require "digest"

    full_path = Rails.root.join(path)
    puts "Updating #{name}..."

    new_content = URI.open(url).read
    new_digest = Digest::SHA256.hexdigest(new_content)

    if File.exist?(full_path) && new_digest == Digest::SHA256.hexdigest(File.read(full_path))
      puts "✓ #{name} is already up-to-date"
    else
      FileUtils.mkdir_p(File.dirname(full_path))
      File.write(full_path, new_content)
      puts "✓ #{name} updated at #{path}"
    end
  end
end
