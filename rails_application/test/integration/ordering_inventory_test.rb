require "test_helper"

class OrderingInventoryTest < Ecommerce::RealRESIntegrationTestCase
  include Infra::TestPlumbing.with(
    event_store: -> { Rails.configuration.event_store },
    command_bus: -> { Rails.configuration.command_bus }
  )

  cover "Ordering::OnSubmitOrder*"

  def test_inventory_error_prevents_order_submission
    aggregate_id = SecureRandom.uuid
    customer_id = SecureRandom.uuid
    product_id = SecureRandom.uuid

    arrange(
      Crm::RegisterCustomer.new(customer_id: customer_id, name: "test"),
      ProductCatalog::RegisterProduct.new(
        product_id: product_id,
        name: "Async Remote"
      ),
      Pricing::SetPrice.new(product_id: product_id, price: 39),
      Ordering::AddItemToBasket.new(
        order_id: aggregate_id,
        product_id: product_id
      ),
      Ordering::AddItemToBasket.new(
        order_id: aggregate_id,
        product_id: product_id
      ),
      Inventory::Supply.new(product_id: product_id, quantity: 1)
    )

    assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
      act(
        Ordering::SubmitOrder.new(
          order_id: aggregate_id,
          customer_id: customer_id
        )
      )
    end
  end
end
