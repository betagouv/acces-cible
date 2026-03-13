require "rails_helper"

RSpec.describe Team do
  subject(:team) { build(:team) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:sites) }
    it { is_expected.to have_many(:tags) }
  end

  describe "validations" do
    context "for siret" do
      it { is_expected.to allow_value("86043616100852").for(:siret) }
      it { is_expected.not_to allow_value("").for(:siret) }
    end
  end
end
