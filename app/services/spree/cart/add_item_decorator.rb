Spree::Cart::AddItem.class_eval do

  def add_to_line_item(order:, variant:, quantity: nil, public_metadata: {}, private_metadata: {}, options: {})
    options ||= {}
    quantity ||= 1

    line_item = Spree::Dependencies.line_item_by_variant_finder.constantize.new.execute(order: order, variant: variant, options: options)

    line_item_created = line_item.nil?
    if line_item.nil?
      opts = ::Spree::PermittedAttributes.line_item_attributes.flatten.each_with_object({}) do |attribute, result|
        result[attribute] = options[attribute]
      end.merge(currency: order.currency).delete_if { |_key, value| value.nil? }

      line_item = order.line_items.new(quantity: quantity,
                                       variant: variant,
                                       options: opts)
    else
      line_item.quantity += quantity.to_i
    end

    line_item.target_shipment = options[:shipment] if options.key? :shipment
    line_item.public_metadata = public_metadata.to_h if public_metadata
    line_item.private_metadata = private_metadata.to_h if private_metadata

    ad_hoc_option_value_ids = ( !!options[:ad_hoc_option_values] ? options[:ad_hoc_option_values] : [] )
    product_option_values = ad_hoc_option_value_ids.map do |cid|
      Spree::AdHocOptionValue.find(cid) if cid.present?
    end.compact
    line_item.ad_hoc_option_values = product_option_values

    return failure(line_item) unless line_item.save

    offset_price = product_option_values.map(&:price_modifier).compact.sum

    if offset_price.present?
      if line_item.currency.present?
        line_item.price    = variant.price_in(line_item.currency).amount + offset_price
      else
        line_item.price    = variant.price + offset_price
      end
    else
      line_item.reload.update_price
    end

    ::Spree::TaxRate.adjust(order, [line_item]) if line_item_created
    success(order: order, line_item: line_item, line_item_created: line_item_created, options: options)
  end

end
