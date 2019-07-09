SELECT DISTINCT
        so.increment_id AS OrderNumber,
        ss.increment_id AS PONumber,
        soi.name AS "Item Name",
        ssi.sku AS "PO Item SKU",
        cev.value AS "Member ID",
        so.created_at AS "Order Date",
        web.name AS Client,
        ssi.qty AS Qty,
        dc.iso2_code AS ISO2_Code,
        dc.iso3_code AS ISO3_Code,
        ioie.product_extra_information AS ProductExtraInformation,
        ioie.udropship_vendor_name AS "Vendor Name",
        (ssi.qty * (soi.row_total_incl_tax / soi.qty_ordered)) AS "Number of points redeemed",
        (1 / (so.base_to_order_rate / so.base_to_global_rate)) AS "Points conversion rate to CL rate",
        (1 / so.base_to_global_rate) AS "Exchange rate",
        (1 / so.base_to_order_rate) AS "Points conversion rate to client rate",
        (ssi.qty * (soi.base_row_total_incl_tax / soi.qty_ordered)) AS "Cash equivalent value of the points",
        (ssi.qty * soi.cash_base_price) AS "Net Cash received",
        ((ssi.qty * (soi.base_row_total_incl_tax / soi.qty_ordered)) + (ssi.qty * soi.cash_base_price)) AS "Gross Retail Value",
        so.margin_percentage AS "Cash Margin %",
        /*((ssi.qty * (soi.pc_cash_base_margin_amount + soi.cash_base_tax_amount)) / soi.qty_ordered) AS "Cash margin Amount",*/
        ((ssi.qty * (soi.pc_cash_margin_amount + soi.cash_base_tax_amount)) / soi.qty_ordered) AS "Cash margin Amount",
        /*((ssi.qty * soi.cash_base_price) + ((ssi.qty * (soi.pc_cash_base_margin_amount + soi.cash_base_tax_amount)) / soi.qty_ordered)) AS "Total Cash Received",*/
        ((ssi.qty * soi.cash_base_price) + ((ssi.qty * (soi.pc_cash_margin_amount + soi.cash_base_tax_amount)) / soi.qty_ordered)) AS "Total Cash Received",
        (ssi.qty * (soi.base_discount_amount / soi.qty_ordered)) AS "Discount Amount",
        so.base_currency_code AS Currency,
        (CASE
            WHEN (soi.client_managed_vendor_flag = 0) THEN 'No'
            WHEN (soi.client_managed_vendor_flag = 1) THEN 'Yes'
        END) AS client_managed,
        si.authcode AS "Bank Response",
        soi.base_cost AS "Item Cost",
        soi.pb_netprice_merchant - soi.base_cost AS "Item Buying Margin",
        soi.tax_amount AS "VAT/TAX",
        soi.pb_shipping_merchant AS "Shipping Cost",
        soi.sku AS "Item (SKU) Name"
    FROM
             base_iredeem_iccs_v2.sales_flat_shipment_item ssi
        JOIN base_iredeem_iccs_v2.sales_flat_order_item soi ON ssi.order_item_id = soi.item_id
        JOIN base_iredeem_iccs_v2.sales_flat_shipment ss ON ssi.parent_id = ss.entity_id
        JOIN base_iredeem_iccs_v2.sales_flat_order so ON soi.order_id = so.entity_id
        JOIN base_iredeem_iccs_v2.sales_flat_invoice AS si ON soi.order_id = si.order_id
        LEFT JOIN base_iredeem_iccs_v2.core_store sto ON sto.store_id = soi.store_id
        LEFT JOIN base_iredeem_iccs_v2.core_website web ON web.website_id = sto.website_id
        /*LEFT JOIN base_iredeem_iccs_v2.iredeem_vendor_information VI ON VI.entity_id = ssi.vendor_id*/
        LEFT JOIN base_iredeem_iccs_v2.sales_flat_order_address soa ON soa.entity_id = ssi.entity_id
        LEFT JOIN base_iredeem_iccs_v2.directory_country dc ON dc.country_id = soa.country_id
        LEFT JOIN base_iredeem_iccs_v2.iredeem_order_item_extra ioie ON ssi.order_item_id = ioie.item_id
        LEFT JOIN base_iredeem_iccs_v2.customer_entity_varchar cev ON soa.customer_id = cev.entity_id
    WHERE
        (ISNULL(soi.parent_item_id)
            AND (so.status NOT IN ('pending_payment' , 'decline_pointscash')))
            AND cev.attribute_id = 192
            and so.created_at >= '2019'
