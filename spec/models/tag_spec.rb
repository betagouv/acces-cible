require "rails_helper"

RSpec.describe Tag do
  subject(:tag) { build(:tag) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:team) }
    it { is_expected.to have_many(:site_tags).dependent(:destroy) }
    it { is_expected.to have_many(:sites).through(:site_tags) }
  end

  describe "#launched_sites" do
    subject(:launched_sites) { tag.launched_sites }

    let(:tag) { create(:tag) }
    let!(:launched_site) { create(:site, team: tag.team, tags: [tag]) }
    let!(:draft_site) { create(:site, :draft, team: tag.team, tags: [tag]) }

    it { is_expected.to contain_exactly(launched_site) }
  end
end
