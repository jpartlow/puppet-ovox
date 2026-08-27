module Ovox
  module SpecTools
    def inventory
      @spec_tools_inventory ||= Bolt::Inventory.empty
    end

    def a_target(name)
      Bolt::Target.from_hash(
        {
          'uri' => name,
          'facts' => {
            'networking' => {
              # sufficiently unique
              'ip' => "10.#{rand(255)}.#{rand(255)}.#{rand(255)}",
            },
          },
        },
        inventory
      )
    end
  end
end
