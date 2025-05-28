require 'rails_helper'

RSpec.describe Team do
  subject(:team) { build(:team) }

  it { should be_valid }

  describe "associations" do
    it { should have_many(:users) }
  end

  describe "validations" do
    context "for siret" do
      it { should allow_value("86043616100852").for(:siret) }
      it { should_not allow_value("").for(:siret) }
    end
  end
end
