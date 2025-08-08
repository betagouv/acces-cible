require "rails_helper"

RSpec.describe ApplicationHelper do
  describe "#time_ago" do
    it "formats past time correctly" do
      result = helper.time_ago(2.hours.ago)

      expect(result).to include("il y a")
    end

    it "formats future time correctly" do
      result = helper.time_ago(2.hours.from_now)

      expect(result).to include("dans")
    end
  end

  describe "#or_separator" do
    it "generates a separator with classes" do
      result = helper.or_separator

      expect(result).to have_selector("p.fr-hr-or.fr-my-4w", text: "ou")
    end
  end

  describe "#badge" do
    it "renders basic badge" do
      result = helper.badge(:success, "Success message")
      expect(result).to have_selector(".fr-badge.fr-badge--success", text: "Success message")
    end

    it "uses block content when no text provided" do
      result = helper.badge(:warning) { "Block content" }
      expect(result).to have_selector(".fr-badge.fr-badge--warning", text: "Block content")
    end

    it "renders tooltip badge when tooltip: true" do
      result = helper.badge(:info, "Tooltip text", tooltip: true)
      expect(result).to have_selector(".fr-badge.fr-badge--info[role='tooltip']")
      expect(result).to have_selector("[title='Tooltip text']")
    end

    it "renders badge with link when link provided" do
      result = helper.badge(:success, "Link text", link: "/link")
      expect(result).to have_selector(".fr-badge.fr-badge--success")
      expect(result).to have_selector("a[href='/link']", text: "Link text")
    end

    it "renders external link" do
      result = helper.badge(:info, "External link", link: "/external", tooltip: true)
      expect(result).to have_selector("a[href='/external'][target='_blank']")
      expect(result).to have_selector("[role='tooltip']")
    end
  end

  describe "#sortable_header" do
    subject(:sortable_header) { helper.sortable_header("Name", column, **options) }

    let(:column) { :name }
    let(:direction) { :asc }
    let(:options) { {} }
    let(:params) { { page: 2 } }

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
        expect(sortable_header).to have_selector("a[href='/?page=2&sort%5Bname%5D=asc']")
        expect(sortable_header).to have_text("Name")
        expect(sortable_header).not_to include("fr-icon-arrow")
        expect(sortable_header).to have_selector("a[title='Sort by Name ascending']")
      end
    end

    context "when column is currently sorted ascending", :aggregate_failures do
      let(:direction) { :desc }
      let(:params) { { page: 2, sort: { name: "asc" } } }

      it "generates a link to sort descending" do
        expect(sortable_header).to have_selector("a[href*='sort%5Bname%5D=desc']")
        expect(sortable_header).to have_selector("a.icon-class")
        expect(sortable_header).to have_selector("a[title='Sort by Name descending']")
      end
    end

    context "when column is currently sorted descending", :aggregate_failures do
      let(:params) { { page: 2, sort: { name: "desc" } } }

      it "generates a link to sort ascending" do
        expect(sortable_header).to have_selector("a[href*='sort%5Bname%5D=asc']")
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
        sortable_header = helper.sortable_header("Name", :name)
        expect(sortable_header).to have_selector("a[href*='sort%5Bname%5D=desc']")

        sortable_header = helper.sortable_header("Email", :email)
        expect(sortable_header).to have_selector("a[href*='sort%5Bemail%5D=asc']")
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
end
