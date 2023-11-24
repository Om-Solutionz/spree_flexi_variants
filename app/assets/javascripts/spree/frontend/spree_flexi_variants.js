//= require jquery.formatCurrency-1.4.0.min
//= require i18n/jquery.formatCurrency.all
// require spree/frontend/product
//= require spree/frontend/cart
//= require_self

Spree.ready(function () {
    // set up the 'reset' functionality on file uploads
    $("#cart-form form input[type=file]").each(function () {
        // make a clone of the original in case the user wants to undo an upload
        var orig = $(this);
        var clone = $(orig).clone();
        attachFileInputSwap(orig, clone);
    });
    // image customizations need multipart
    $("#cart-form form").attr("enctype", "multipart/form-data");
//  $("#cart-form form").validate();
});

// 'replacement' is always a pure, empty file input
function attachFileInputSwap(current, replacement) {
    $(current).siblings("a").click(function (event) {
        event.preventDefault();
        $(current).replaceWith(replacement);
        // need to reattach
        var clone = $(replacement).clone();
        attachFileInputSwap(replacement, clone);
    });
}


//= require spree/api/storefront/cart
//= require spree/frontend/serialize_json


SpreeAPI.Storefront.addToCartWithAdhoc = function (formId, cartBtnId, variantId, quantity, cb, ecb) {
    event.preventDefault()
    let $form = $(formId);
    let adHocOptionValueIds = null;

    if ($form.length) {
        let ser = $(formId).serializeJSON();
        if (ser.ad_hoc_option_values) {
            adHocOptionValueIds = Object.keys(ser.ad_hoc_option_values).map(function(key) { return parseInt(ser.ad_hoc_option_values[key]); });
            
            if (adHocOptionValueIds.length !== adHocOptionValueIds.filter(function(i) { return i; }).length) {
                if (ecb) {
                    ecb('ad_hoc_option_value');
                }
            }
        }
    }

    let addToCartButton = $(cartBtnId);

    Spree.ensureCart(
        function () {
            SpreeAPI.Storefront.addToCart(
                variantId,
                quantity,
                {ad_hoc_option_value_ids: adHocOptionValueIds}, // options hash - you can pass additional parameters here, your backend
                // needs to be aware of those, see API docs:
                // https://github.com/spree/spree/blob/master/api/docs/v2/storefront/index.yaml#L42
                function (res) {
                    // redirect with `variant_id` is crucial for analytics tracking
                    // provided by `spree_analytics_trackers` extension
                    cb(res)

                },
                function (error) {
                    alert(error)
                } // failure callback for 422 and 50x errors
            )
        }
    )


}