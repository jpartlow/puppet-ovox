module Ovox
  module SpecTools
    def inventory
      @spec_tools_inventory ||= Bolt::Inventory.empty
    end

    def a_target(name)
      Bolt::Target.from_hash(
        { 'name' => name },
        inventory
      )
    end
  end
end
