require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#or_separator" do
    it "generates a separator with classes" do
      result = helper.or_separator

      expect(result).to have_selector("p.fr-hr-or.fr-my-4w", text: "ou")
    end
  end

  describe "#badge" do
    it "colours the badge from a system status" do
      result = helper.badge(status: :success, text: "Fait")
      expect(result).to have_selector("p.fr-badge.fr-badge--success", text: "Fait")
    end

    it "drops the status icon on request" do
      result = helper.badge(status: :success, text: "Fait", no_icon: true)
      expect(result).to have_selector("p.fr-badge.fr-badge--success.fr-badge--no-icon", text: "Fait")
    end

    it "links the label" do
      result = helper.badge(status: :success, text: "Voir la page", link: "/page")
      expect(result).to have_selector("p.fr-badge--success a[href='/page']", text: "Voir la page")
    end

    it "keeps the label for hover and screen readers only" do
      result = helper.badge(status: :info, text: "En attente", hover: true)
      expect(result).to have_selector("p.fr-badge--info[role='tooltip'][title='En attente']")
      expect(result).to have_selector(".fr-sr-only", text: "En attente")
    end

    it "renders a hovered linked badge as an external link" do
      result = helper.badge(status: :info, text: "Voir la page", link: "/page", hover: true)
      expect(result).to have_selector("a.fr-badge.fr-badge--info[href='/page'][target='_blank'][role='tooltip']")
    end
  end

  describe "#sortable_header" do
    subject(:sortable_header) { helper.sortable_header("Name", column, **options) }

    let(:column) { :name }
    let(:direction) { :asc }
    let(:options) { {} }
    let(:params) { { page: 2 } }
    let(:decoded_href) { CGI.unescape(Capybara.string(sortable_header).find("a")[:href]) }

    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(**params))
      allow(helper).to receive(:url_for) { |options| "/?#{options[:params].to_query}" }

      allow(helper).to receive(:t).with("shared.asc").and_return("ascending")
      allow(helper).to receive(:t).with("shared.desc").and_return("descending")
      allow(helper).to receive(:t).with("shared.sort_by", any_args).and_return("Sort by #{column.capitalize} #{helper.t("shared.#{direction}")}")

      allow(helper).to receive(:icon_class).with(any_args).and_return("icon-class")
    end

    context "when no current sort exists", :aggregate_failures do
      it "generates a link with ascending sort parameter" do
        expect(decoded_href).to eq("/?page=2&sort[name]=asc")
        expect(sortable_header).to have_text("Name")
        expect(sortable_header).not_to include("fr-icon-arrow")
        expect(sortable_header).to have_selector("a[title='Sort by Name ascending']")
      end
    end

    context "when column is currently sorted ascending", :aggregate_failures do
      let(:direction) { :desc }
      let(:params) { { page: 2, sort: { name: "asc" } } }

      it "generates a link to sort descending" do
        expect(decoded_href).to include("sort[name]=desc")
        expect(sortable_header).to have_selector("a.icon-class")
        expect(sortable_header).to have_selector("a[title='Sort by Name descending']")
      end
    end

    context "when column is currently sorted descending", :aggregate_failures do
      let(:params) { { page: 2, sort: { name: "desc" } } }

      it "generates a link to sort ascending" do
        expect(decoded_href).to include("sort[name]=asc")
        expect(sortable_header).to have_selector("a.icon-class")
        expect(sortable_header).to have_selector("a[title='Sort by Name ascending']")
      end
    end

    context "with custom options", :aggregate_failures do
      let(:params) { { sort: { name: "asc" } } }
      let(:options) { { id: "sort-name", title: "Custom sort title", data: { test: "value" } } }

      it "adds HTML attributes to the link" do
        expect(sortable_header).to have_selector("a#sort-name")
        expect(sortable_header).to have_selector("a[title='Custom sort title']")
        expect(sortable_header).to have_selector("a[data-test='value']")
      end
    end

    context "when the page is currently sorted by a column", :aggregate_failures do
      let(:params) { { sort: { name: "asc", email: "desc" } } }

      it "allows sorting by another column" do
        name_header = helper.sortable_header("Name", :name)
        name_href = CGI.unescape(Capybara.string(name_header).find("a")[:href])
        expect(name_href).to include("sort[name]=desc")

        email_header = helper.sortable_header("Email", :email)
        email_href = CGI.unescape(Capybara.string(email_header).find("a")[:href])
        expect(email_href).to include("sort[email]=asc")
      end
    end

    context "when filter and limit params are present", :aggregate_failures do
      let(:params) { { page: 2, filter: { tag_id: 5, q: "test" }, limit: 20 } }

      it "preserves filter and limit params in the sort link" do
        expect(decoded_href).to include("filter[tag_id]=5")
        expect(decoded_href).to include("filter[q]=test")
        expect(decoded_href).to include("limit=20")
        expect(decoded_href).to include("sort[name]=asc")
      end
    end
  end

  describe "#set_focus" do
    it 'generates a hidden div with selector attribute' do
      result = helper.set_focus('my-input')

      expect(result).to have_selector('div[hidden][data-controller="focus"][data-focus-selector-value="#my-input"]', visible: false)
    end
  end

  describe "#aria_sort" do
    it 'returns nil when no sort param exists' do
      allow(helper).to receive(:params).and_return({})

      expect(helper.aria_sort(:name)).to be_nil
    end

    it 'returns descending when current sort is asc' do
      allow(helper).to receive(:params).and_return({ sort: { name: 'asc' } })

      expect(helper.aria_sort(:name)).to eq('aria-sort=descending')
    end

    it 'returns ascending when current sort is descending' do
      allow(helper).to receive(:params).and_return({ sort: { name: 'desc' } })

      expect(helper.aria_sort(:name)).to eq('aria-sort=ascending')
    end
  end

  describe "#flatten_params" do
    let(:params) do
      {
        sort: { name: :asc },
        filter: { tag_id: 2, q: ".gouv" },
        page: 1,
        other: "ignored"
      }
    end

    before do
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(**params))
    end

    it "flattens single nested hash param" do
      result = helper.flatten_params(:sort)

      expect(result).to eq({ "sort[name]" => :asc })
    end

    it "flattens multiple nested hash params" do
      result = helper.flatten_params(:sort, :filter)

      expect(result).to eq({
                             "sort[name]" => :asc,
                             "filter[tag_id]" => 2,
                             "filter[q]" => ".gouv"
                           })
    end

    it "handles non-nested params" do
      result = helper.flatten_params(:page)

      expect(result).to eq({ "page" => 1 })
    end

    context "with deeply nested params" do
      let(:params) { { filter: { user: { profile: { age: 25 } } } } }

      it "handles deeply nested params" do
        result = helper.flatten_params(:filter)

        expect(result).to eq({ "filter[user][profile][age]" => 25 })
      end
    end

    it "returns empty hash when no keys match" do
      result = helper.flatten_params(:nonexistent)

      expect(result).to eq({})
    end

    it "ignores unpermitted keys" do
      result = helper.flatten_params(:sort)

      expect(result).not_to have_key("other")
    end
  end
end
