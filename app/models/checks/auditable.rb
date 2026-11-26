module Checks
  class Auditable < Check
    PRIORITY = 1
    REQUIREMENTS = [:reachable]

    private

    def analyze!
      return unless audit.home_page_snapshot.auditable?

      {}
    end

    def compute_found
      !data.nil?
    end

    def compute_conform
      compute_found
    end
  end
end
