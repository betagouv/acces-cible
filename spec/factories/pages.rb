FactoryBot.define do
  factory :page do
    url { "https://www.example.com/" }
    root { nil }

    transient do
      title { nil }
      links { [] }
      headings { [] }
      body { nil }
      html { nil }
      wrap_in { nil }
    end

    initialize_with do
      page_html = if html
        html
      elsif title || !headings.empty? || !links.empty? || body
        headings_html = headings.map { |h| "<h1>#{h}</h1>" }.join("\n")

        links_html = links.map do |link|
          case link
          when Link
            %(<a href="#{link.href}">#{link.text}</a>)
          when Array
            %(<a href="#{link[0]}">#{link[1]}</a>)
          when String
            %(<a href="#{link}">#{link}</a>)
          end
        end.join("\n")

        opening_tag, closing_tag = case wrap_in
        when Array then wrap_in
        when String then ["<#{wrap_in}>", "</#{wrap_in}>"]
        end

        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>#{title ? "<title>#{title}</title>" : ""}</head>
          <body>
            #{[opening_tag, headings_html, links_html, body, closing_tag].compact_blank.join("\n")}
          </body>
          </html>
        HTML
      else
        nil
      end

      new(url:, root:, html: page_html)
    end
  end
end
