FactoryBot.define do
  factory :page do
    sequence(:url) { |n| "https://www.example-#{n}.com/" }
    root { url }

    transient do
      title { nil }
      links { [] }
      headings { [] }
      body { nil }
    end

    initialize_with do
      html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>#{title ? "<title>#{title}</title>" : ""}</head>
        <body>
          #{headings.map { |h| "<h1>#{h}</h1>" }.join("\n")}
          #{links.map do |link|
            case link
            when String
              %(<a href="#{link}">#{link}</a>)
            when Array
              %(<a href="#{link[0]}">#{link[1]}</a>)
            end
          end.join("\n")}
          #{body}
        </body>
        </html>
      HTML

      new(url:, root:, html:)
    end
  end
end
