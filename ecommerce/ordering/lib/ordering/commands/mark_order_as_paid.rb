module Ordering
  class MarkOrderAsPaid < Infra::Command
    attribute :order_id, Infra::Types::UUID

    alias aggregate_id order_id
  end
end
