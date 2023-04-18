codeunit 139606 "Shpfy Shipping Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure UnitTestExportShipment()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        ExportShipments: Codeunit "Shpfy Export Shipments";
        JsonHelper: Codeunit "Shpfy Json Helper";
        FulfillmentRequest: Text;
        JFulfillment: JsonObject;
        JLineItems: JsonArray;
        JLineItem: JsonToken;
        ShopifyOrderId: BigInteger;
        ShopifyFulfillmentOrderId: BigInteger;
        LocationId: BigInteger;
        LocationCode: Code[10];
    begin
        // [SCENARIO] Export a Sales Shipment record into a Json token that contains the shipping info
        // [GIVEN] A random Sales Shipment, a random LocationId, a random LocationCode
        LocationId := Any.IntegerInRange(10000, 99999);
        LocationCode := Any.AlphanumericText(MaxStrLen(LocationCode));
        ShopifyOrderId := CreateRandomShopifyOrder();
        ShopifyFulfillmentOrderId := CreateShopifyFulfillmentOrder(ShopifyOrderId);
        CreateRandomSalesShipment(SalesShipmentHeader, ShopifyOrderId, LocationCode);

        // [WHEN] Invoke the function CreateFulfillmentRequest()
        FulfillmentRequest := ExportShipments.CreateFulfillmentOrderRequest(SalesShipmentHeader, LocationId, LocationCode);

        // [THEN] We must find the correct fulfilment data in the json token
        LibraryAssert.IsTrue(FulfillmentRequest.Contains(Format(ShopifyFulfillmentOrderId)), 'Fulfillmentorder Id Check');
        LibraryAssert.IsTrue(FulFillmentRequest.Contains(SalesShipmentHeader."Package Tracking No."), 'tracking number check');

        // [THEN] We must find the fulfilment lines in the json token
        JsonHelper.GetJsonArray(JFulfillment, JLineItems, 'line_items');
        foreach JLineItem in JLineItems do begin
            SalesShipmentLine.SetRange("Shpfy Order Line Id", JsonHelper.GetValueAsBigInteger(JLineItem, 'id'));
            SalesShipmentLine.FindFirst();
            LibraryAssert.AreEqual(SalesShipmentLine.Quantity, JsonHelper.GetValueAsDecimal(JLineItem, 'quantity'), 'quanity check');
        end;
    end;

    local procedure CreateRandomShopifyOrder(): BigInteger
    var
        OrderHeader: Record "Shpfy Order Header";
        OrderLine: Record "Shpfy Order Line";
    begin
        Clear(OrderHeader);
        OrderHeader."Shopify Order Id" := Any.IntegerInRange(10000, 99999);
        OrderHeader.Insert();

        Clear(OrderLine);
        OrderLine."Shopify Order Id" := OrderHeader."Shopify Order Id";
        OrderLine."Shopify Product Id" := Any.IntegerInRange(10000, 99999);
        OrderLine."Shopify Variant Id" := Any.IntegerInRange(10000, 99999);
        OrderLine."Line Id" := Any.IntegerInRange(10000, 99999);
        OrderLine.Insert();

        exit(OrderHeader."Shopify Order Id");
    end;

    local procedure CreateShopifyFulfillmentOrder(ShopifyOrderId: BigInteger): BigInteger
    var
        OrderLine: Record "Shpfy Order Line";
        FulfillmentOrderHeader: Record "Shpfy FulFillment Order Header";
        FulfillmentOrderLine: Record "Shpfy FulFillment Order Line";
    begin
        Clear(FulfillmentOrderHeader);
        FulfillmentOrderHeader."Shopify Fulfillment Order Id" := Any.IntegerInRange(10000, 99999);
        FulfillmentOrderHeader."Shopify Order Id" := ShopifyOrderId;
        FulfillmentOrderHeader.Insert();

        OrderLine.Reset();
        OrderLine.SetRange("Shopify Order Id", ShopifyOrderId);
        if OrderLine.FindSet() then
            repeat
                Clear(FulfillmentOrderLine);
                FulfillmentOrderLine."Shopify Fulfillment Order Id" := FulfillmentOrderHeader."Shopify Fulfillment Order Id";
                FulfillmentOrderLine."Shopify Fulfillm. Ord. Line Id" := Any.IntegerInRange(10000, 99999);
                FulfillmentOrderLine."Shopify Order Id" := FulfillmentOrderHeader."Shopify Order Id";
                FulfillmentOrderLine."Shopify Product Id" := OrderLine."Shopify Product Id";
                FulfillmentOrderLine."Shopify Variant Id" := OrderLine."Shopify Variant Id";
                FulfillmentOrderLine.Insert();
            until OrderLine.Next() = 0;

        exit(FulfillmentOrderHeader."Shopify Fulfillment Order Id");
    end;

    local procedure CreateRandomSalesShipment(var SalesShipmentHeader: record "Sales Shipment Header"; ShopifyOrderId: BigInteger; LocationCode: Code[10])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        OrderLine: Record "Shpfy Order Line";
    begin
        Clear(SalesShipmentHeader);
        SalesShipmentHeader."No." := Any.AlphanumericText(MaxStrLen(SalesShipmentHeader."No."));
        SalesShipmentHeader."Shpfy Order Id" := ShopifyOrderId;
        SalesShipmentHeader."Package Tracking No." := Any.AlphanumericText(MaxStrLen(SalesShipmentHeader."Package Tracking No."));
        SalesShipmentHeader.Insert();

        OrderLine.Reset();
        OrderLine.SetRange("Shopify Order Id", ShopifyOrderId);
        if OrderLine.FindSet() then
            repeat
                Clear(SalesShipmentLine);
                SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
                SalesShipmentLine.Type := SalesShipmentLine.type::Item;
                SalesShipmentLine."No." := Any.AlphanumericText(MaxStrLen(SalesShipmentLine."No."));
                SalesShipmentLine."Shpfy Order Line Id" := OrderLine."Line Id";
                SalesShipmentLine.Quantity := Any.DecimalInRange(10, 0);
                SalesShipmentLine."Location Code" := LocationCode;
                SalesShipmentLine.Insert();
            until OrderLine.Next() = 0;
    end;
}