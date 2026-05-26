# frozen_string_literal: true
# shareable_constant_value: literal
# typed: false

# Patch Goldiloader/SingularAssociation compatibility on Rails 8.
# Ensure positional and keyword args are forwarded through any prepended chain.
module GoldiloaderRails8SingularAssociationPatch
  private

  def find_target(*args, **kwargs, &block)
    load_with_auto_include { super(*args, **kwargs, &block) }
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Associations::SingularAssociation.prepend(GoldiloaderRails8SingularAssociationPatch)
end
