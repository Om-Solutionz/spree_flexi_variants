module Spree
  LineItem.class_eval do
    has_many :ad_hoc_option_values_line_items, dependent: :destroy
    has_many :ad_hoc_option_values, through: :ad_hoc_option_values_line_items
    has_many :product_customizations, dependent: :destroy
    money_methods :base_price

    alias_method :old_ad_hoc_option_values, :ad_hoc_option_values

    def options_text
      str = Array.new
      unless self.ad_hoc_option_values.empty?

        #TODO: group multi-select options (e.g. toppings)
        str << self.ad_hoc_option_values.each { |pov|
          "#{pov.option_value.option_type.presentation} = #{pov.option_value.presentation}"
        }.join(',')
      end # unless empty?

      unless self.product_customizations.empty?
        self.product_customizations.each do |customization|
          price_adjustment = (customization.price == 0) ? "" : " (#{Spree::Money.new(customization.price).to_s})"
          str << "#{customization.product_customization_type.presentation}#{price_adjustment}"
          customization.customized_product_options.each do |option|
            next if option.empty?

            if option.customization_image?
              str << "#{option.customizable_product_option.presentation} = #{File.basename option.customization_image.url}"
            else
              str << "#{option.customizable_product_option.presentation} = #{option.value}"
            end
          end # each option
        end # each customization
      end # unless empty?

      str.join('\n')
    end

    def copy_price
      if variant
        update_price if price.nil? || base_price.nil?
        self.cost_price = variant.cost_price if cost_price.nil?
        self.currency = variant.currency if currency.nil?
      end
    end

    def update_price
      self.price = variant.price_including_vat_for(tax_zone: tax_zone)+ self.ad_hoc_option_values.map(&:cost_price).inject(0, :+)
      self.base_price = variant.price_including_vat_for(tax_zone: tax_zone)
    end

    # def cost_price
    #   (variant.cost_price || 0) + ad_hoc_option_values.map(&:cost_price).inject(0, :+)
    # end

    # def cost_money
    #   Spree::Money.new(cost_price, currency: currency)
    # end
    
    # Sort by the product ad hoc option types position
    def ad_hoc_option_values
      product_ad_hoc_option_types = {}
      product.ad_hoc_option_types.map do |ad_hoc_option_type|
        product_ad_hoc_option_types[ad_hoc_option_type.id] = ad_hoc_option_type.position
      end
  
      new_order_ad_hoc_option_values = old_ad_hoc_option_values.sort do |a, b|
        product_ad_hoc_option_types[a.ad_hoc_option_type_id] <=> product_ad_hoc_option_types[b.ad_hoc_option_type_id]
      end
      
      return new_order_ad_hoc_option_values
    end
  end
end
