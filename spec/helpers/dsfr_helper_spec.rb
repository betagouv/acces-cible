require "rails_helper"

RSpec.describe DsfrHelper do
  describe "#dsfr_row_check" do
    let(:site) { build(:site) }

    it "renders checkbox with record data" do
      result = helper.dsfr_row_check(site)

      expect(result).to include("value=\"#{site.id}\"")
      expect(result).to include("id=\"row_check_#{site.id}\"")
    end
  end

  describe "#dsfr_row_check_all" do
    it "renders select all checkbox" do
      result = helper.dsfr_row_check_all

      expect(result).to include('id="row_check_all"')
      expect(result).to include('data-action="table#toggleAll"')
    end
  end

  describe "#dsfr_badge" do
    it "renders badge with status class" do
      result = helper.dsfr_badge(status: "success") { "Content" }

      expect(result).to include('class="fr-badge fr-badge--success"')
      expect(result).to include("Content")
    end
  end
end
