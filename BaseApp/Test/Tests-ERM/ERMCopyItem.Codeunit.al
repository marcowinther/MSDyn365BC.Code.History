codeunit 134462 "ERM Copy Item"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Item]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryResource: Codeunit "Library - Resource";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        TargetItemNoErr: Label 'Target item number %1 already exists.';
        NoOfRecordsMismatchErr: Label 'Number of target records does not match the number of source records';

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLine()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
        Comment: Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines
        Initialize;

        // [GIVEN] Item "I" with Comment Line
        Comment := CreateItemWithCommentLine(Item);

        // [WHEN] Run "Copy Item" report for item "I" with Comments = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, true, false, false, false, false, false, false, false, false);  // Comments and Unit Of Measure as TRUE.
        CopyItem(Item."No.");

        // [THEN] Comment line copied
        VerifyItemGeneralInformation(TargetItemNo, Item."Base Unit of Measure", Item.Description);
        VerifyCommentLine(TargetItemNo, Comment);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndTranslation()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
        Comment: Text[80];
        Description: Text[50];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines and item translation
        Initialize;

        // [GIVEN] Item "I" with Comment Line and Item Translation
        Comment := CreateItemWithCommentLine(Item);
        Description := CreateItemTranslation(Item."No.");

        // [WHEN] Run "Copy Item" report for item "I" with Comments = "Yes", "Item Translation" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, true, false, false, false, false, false, false, false);  // Comments and Translations as TRUE.
        CopyItem(Item."No.");

        // [THEN] Comment line and item translation copied
        VerifyItemGeneralInformation(TargetItemNo, '', Item.Description);
        VerifyCommentLine(TargetItemNo, Comment);
        VerifyItemTranslation(TargetItemNo, Description);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndDefaultDimension()
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        Comment: Text[80];
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Comments] [Default Dimension]
        // [SCENARIO] Copy item with comment lines and default dimension
        Initialize;

        // [GIVEN] Item "I" with Comment Line and default dimension
        Comment := CreateItemWithCommentLine(Item);
        CreateDefaultDimensionForItem(DefaultDimension, Item."No.");

        // [WHEN] Run "Copy Item" report for item "I" with Comments = "Yes", Dimensions = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, false, true, false, false, false, false, false, false);  // Comments and Dimensions as TRUE.
        CopyItem(Item."No.");

        // [THEN] Comment line and default dimensions copied
        VerifyItemGeneralInformation(TargetItemNo, '', Item.Description);
        VerifyCommentLine(TargetItemNo, Comment);
        VerifyDefaultDimension(DefaultDimension, TargetItemNo);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemErrorAfterCreatingTargetItem()
    var
        Item: Record Item;
        Item2: Record Item;
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Item cannot be copeid if item with target item number already exists
        Initialize;

        // [GIVEN] Create items "I1" and "I2"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        EnqueueValuesForItemCopyRequestPageHandler(
          Item2."No.", false, false, false, false, false, false, false, false, false, false);

        // [WHEN] Run copy item report with target item number "I2"
        asserterror CopyItem(Item."No.");

        // [THEN] Error "Target item I2 already exists"
        Assert.ExpectedError(StrSubstNo(TargetItemNoErr, Item2."No."));
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemErrorWithItemCommentLine()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Item cannot be copeid with same target item number twice
        Initialize;

        // [GIVEN] Create item "I1", copy it to item "I2"
        CreateItemWithCommentLine(Item);
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, false, false, false, false, false, false, false, false);  // Comments as TRUE.
        CopyItem(Item."No.");

        // [WHEN] Run copy item report with target item number "I2" again
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, false, false, false, false, false, false, false, false, false);
        asserterror CopyItem(Item."No.");

        // [THEN] Error "Target item I2 already exists"
        Assert.ExpectedError(StrSubstNo(TargetItemNoErr, TargetItemNo));
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Comment: Text[80];
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines and Item Variant
        Initialize;
        // [GIVEN] Create item with comment and item variant
        Comment := CreateItemWithCommentLine(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Run copy item report with Comments = "Yes", Item Variant = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, false, false, true, false, false, false, false, false);  // Comments and Item Variants as TRUE.
        CopyItem(Item."No.");

        // [THEN] Comment line and item variant copied
        VerifyItemGeneralInformation(TargetItemNo, '', Item.Description);
        VerifyCommentLine(TargetItemNo, Comment);
        VerifyItemVariant(ItemVariant, TargetItemNo);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithGeneralInformation()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Unit of Measure
        Initialize;

        // [GIVEN] Create item with Unit of Measure
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run copy item report with "Unit of Measure" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, true, false, false, false, false, false, false, false, false);  // Unit of Measure as TRUE.
        CopyItem(Item."No.");

        // [THEN] Unit of Measure copied
        VerifyItemGeneralInformation(TargetItemNo, Item."Base Unit of Measure", Item.Description);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndExtendedText()
    var
        Item: Record Item;
        ExtendedTextLine: Record "Extended Text Line";
        TargetItemNo: Code[20];
        Comment: Text[80];
    begin
        // [FEATURE] [Comments] [Extended Text]
        // [SCENARIO] Copy item with comment lines and Extended Text
        Initialize;

        // [GIVEN] Create item with comment and Extended Text
        Comment := CreateItemWithCommentLine(Item);
        CreateExtendedText(ExtendedTextLine, Item."No.");

        // [WHEN] Run copy item report with Comment = "Yes" and "Extended Text" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, false, false, false, true, false, false, false, false);  // Comment and Extended Text as TRUE.
        CopyItem(Item."No.");

        // [THEN] Comment line and Extended Text copied
        VerifyCommentLine(TargetItemNo, Comment);
        VerifyExtendedText(ExtendedTextLine, TargetItemNo);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndBOMComponent()
    var
        ParentItem: Record Item;
        Item: Record Item;
        TargetItemNo: Code[20];
        Comment: Text[80];
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines and BOM Component
        Initialize;

        // [GIVEN] Create item with comment and BOM Component
        QuantityPer := LibraryRandom.RandDec(10, 2);
        Comment := CreateItemWithCommentLine(ParentItem);
        LibraryInventory.CreateItem(Item);
        CreateBOMComponent(Item, ParentItem."No.", QuantityPer);

        // [WHEN] Run copy item report with Comment = "Yes" and "BOM Component" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, false, false, false, true, false, false, false, true);  // Comment and BOM Component as True.
        CopyItem(ParentItem."No.");

        // [THEN] Comment line and BOM Component copied
        VerifyCommentLine(TargetItemNo, Comment);
        VerifyBOMComponent(TargetItemNo, Item."No.", QuantityPer);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithTroubleShootingSetupAndResourceSkill()
    var
        Item: Record Item;
        TroubleshootingSetup: Record "Troubleshooting Setup";
        TroubleshootingSetup2: Record "Troubleshooting Setup";
        ResourceSkill: Record "Resource Skill";
        ResourceSkill2: Record "Resource Skill";
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Troubleshooting Setup and resource skill
        Initialize;

        // [GIVEN] Create item with Troubleshooting Setup
        LibraryInventory.CreateItem(Item);
        CreateTroubleShootingSetup(TroubleshootingSetup, Item."No.");
        CreateResourceSkill(ResourceSkill, Item."No.");

        // [WHEN] Run copy item report with "Troubleshooting Setup" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, false, false, false, false, false, true, false, false, false);  // Service as True.
        CopyItem(Item."No.");

        // [THEN] Troubleshooting Setup and resource skill copied
        ResourceSkill2.Get(ResourceSkill.Type, TargetItemNo, ResourceSkill."Skill Code");
        TroubleshootingSetup2.Get(TroubleshootingSetup.Type, TargetItemNo, TroubleshootingSetup."Troubleshooting No.");
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithSalesPriceAndSalesLineDiscount()
    var
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Sales Price and Sales Line Discount
        Initialize;

        // [GIVEN] Create item with Sales Price and Sales Line Discount
        LibraryInventory.CreateItem(Item);
        CreateSalesPriceWithLineDiscount(SalesPrice, SalesLineDiscount, Item);

        // [WHEN] Run copy item report with "Sales Price" = "Yes" and "Sales Line Discount" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, false, false, false, false, false, false, true, false, false);  // Sales as True.
        CopyItem(Item."No.");

        // [THEN] Sales Price and Sales Line Discount copied
        VerifySalesPrice(SalesPrice, TargetItemNo);
        VerifySalesLineDiscount(TargetItemNo, SalesLineDiscount."Line Discount %");
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithPurchasePriceAndPurchaseLineDiscount()
    var
        Item: Record Item;
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Purchase Price and Purchase Line Discount
        Initialize;

        // [GIVEN] Create item with Purchase Price and Purchase Line Discount
        LibraryInventory.CreateItem(Item);
        CreatePurchasePriceWithLineDiscount(PurchasePrice, PurchaseLineDiscount, Item);

        // [WHEN] Run copy item report with "Purchase Price" = "Yes" and "Purchase Line Discount" = "Yes"
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, false, false, false, false, false, false, false, true, false);  // Purchase as True.
        CopyItem(Item."No.");

        // [THEN] Purchase Price and Purchase Line Discount copied
        VerifyPurchasePrice(PurchasePrice, TargetItemNo);
        VerifyPurchaseLineDiscount(PurchaseLineDiscount, TargetItemNo);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithFullSetup()
    var
        ExtendedTextLine: Record "Extended Text Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        TroubleshootingSetup2: Record "Troubleshooting Setup";
        ResourceSkill: Record "Resource Skill";
        ResourceSkill2: Record "Resource Skill";
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        ItemVariant: Record "Item Variant";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
        TargetItemNo: Code[20];
        Comment: Text[80];
        Description: Text[50];
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with all checkboxes marked
        Initialize;

        // [GIVEN] Create item with comments, translation, item variant, extended text, troubleshooting setup, resource skill, sales and purchase price and discount
        Comment := CreateItemWithCommentLine(Item);
        Description := CreateItemTranslation(Item."No.");
        CreateDefaultDimensionForItem(DefaultDimension, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateExtendedText(ExtendedTextLine, Item."No.");
        CreateTroubleShootingSetup(TroubleshootingSetup, Item."No.");
        CreateResourceSkill(ResourceSkill, Item."No.");
        CreateSalesPriceWithLineDiscount(SalesPrice, SalesLineDiscount, Item);
        CreatePurchasePriceWithLineDiscount(PurchasePrice, PurchaseLineDiscount, Item);

        // [WHEN] Run copy item report with all checkboxes marked
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, true, true, true, true, true, true, true, true, true);
        CopyItem(Item."No.");

        // [THEN] comments, translation, item variant, extended text, troubleshooting setup, resource skill, sales and purchase price and discount copied
        ResourceSkill2.Get(ResourceSkill.Type::Item, TargetItemNo, ResourceSkill."Skill Code");
        TroubleshootingSetup2.Get(TroubleshootingSetup.Type, TargetItemNo, TroubleshootingSetup."Troubleshooting No.");
        VerifyItemGeneralInformation(TargetItemNo, Item."Base Unit of Measure", Item.Description);
        VerifyCommentLine(TargetItemNo, Comment);
        VerifyItemTranslation(TargetItemNo, Description);
        VerifyDefaultDimension(DefaultDimension, TargetItemNo);
        VerifyItemVariant(ItemVariant, TargetItemNo);
        VerifySalesPrice(SalesPrice, TargetItemNo);
        VerifySalesLineDiscount(TargetItemNo, SalesLineDiscount."Line Discount %");
        VerifyPurchasePrice(PurchasePrice, TargetItemNo);
        VerifyPurchaseLineDiscount(PurchaseLineDiscount, TargetItemNo);
        VerifyExtendedText(ExtendedTextLine, TargetItemNo);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyingItemWithSeveralCommentLines()
    var
        Item: Record Item;
        CommentLine: Record "Comment Line";
        TargetItemNo: Code[20];
        Comments: array[3] of Text;
        i: Integer;
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 279990] Several comment lines are copied from the source item to a destination item.
        Initialize;

        // [GIVEN] Source item "S" with several comment lines, destination item "D".
        CreateItemWithSeveralCommentLines(Item, Comments);
        TargetItemNo := LibraryUtility.GenerateGUID;

        // [WHEN] Copy comment lines from item "S" to "D".
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, true, false, false, false, false, false, false, false, false, false); // Comments
        CopyItem(Item."No.");

        // [THEN] All comment lines are successfully copied.
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", TargetItemNo);
        for i := 1 to ArrayLen(Comments) do begin
            CommentLine.Next;
            CommentLine.TestField(Comment, Comments[i]);
        end;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyingItemWithSeveralDefaultDimensions()
    var
        Item: Record Item;
        SourceDefaultDimension: Record "Default Dimension";
        TargetDefaultDimension: Record "Default Dimension";
        TargetItemNo: Code[20];
        NoOfDims: Integer;
        i: Integer;
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO 280964] Several default dimensions are copied from the source item to a destination item.
        Initialize;

        // [GIVEN] Source item "S" with several default dimensions, destination item "D".
        LibraryInventory.CreateItem(Item);
        TargetItemNo := LibraryUtility.GenerateGUID;

        NoOfDims := LibraryRandom.RandIntInRange(2, 4);
        CreateSeveralDefaultDimensionsForItem(Item."No.", NoOfDims);

        // [WHEN] Copy default dimensions from item "S" to "D".
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, false, false, true, false, false, false, false, false, false); // Default dimensions
        CopyItem(Item."No.");

        // [THEN] All default dimensions and their values are successfully copied.
        SourceDefaultDimension.SetRange("Table ID", DATABASE::Item);
        SourceDefaultDimension.SetRange("No.", Item."No.");
        TargetDefaultDimension.CopyFilters(SourceDefaultDimension);
        for i := 1 to NoOfDims do begin
            SourceDefaultDimension.Next;
            TargetDefaultDimension.Next;
            TargetDefaultDimension.TestField("Dimension Code", SourceDefaultDimension."Dimension Code");
            TargetDefaultDimension.TestField("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
        end;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler,ShowCreatedItemsSendNotificationHandler,ModalItemCardHandler')]
    [Scope('OnPrem')]
    procedure OpenTargetItemAfterCopyOnItemListPage()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 224152] Target Item Card opens after copying item
        Initialize;

        // [GIVEN] Source Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Target Item No.
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(
          TargetItemNo, false, false, false, false, false, false, false, false, false, false);

        // [WHEN] Copy Item
        CopyItemOnItemListPage(Item."No.");

        // [THEN] Item Card opens on target Item in modal mode
        Assert.AreEqual(TargetItemNo, LibraryVariableStorage.DequeueText, 'Invalid Item No.');

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyAttributesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithAttributesCopiesAttributesIntoNewItem()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
        NoOfAttributes: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 264720] Item attributes are copied by the "Item Copy" job when the corresponding option is selected
        Initialize;

        // [GIVEN] Item "SRC" with 3 attributes
        LibraryInventory.CreateItem(Item);

        NoOfAttributes := LibraryRandom.RandIntInRange(3, 5);
        for I := 1 to NoOfAttributes do
            CreateItemAttributeMappedToItem(Item."No.");

        // [WHEN] Copy item "SRC" into a new item "DST" with "Copy Attributes" option selected
        TargetItemNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(true);
        CopyItem(Item."No.");

        // [THEN] All attributes are copied from "SRC" to "DST"
        VerifyItemAttributes(Item."No.", TargetItemNo);

        LibraryVariableStorage.AssertEmpty;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyAttributesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithAttributesDoesNotCopyAttributesWithAttrOptionDisabled()
    var
        Item: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 264720] Item attributes are not copied by the "Item Copy" job when the corresponding option is disabled
        Initialize;

        // [GIVEN] Item "SRC" with attribute
        LibraryInventory.CreateItem(Item);
        CreateItemAttributeMappedToItem(Item."No.");

        // [WHEN] Copy item "SRC" into a new item "DST" with "Copy Attributes" option switched off
        TargetItemNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(false);
        CopyItem(Item."No.");

        // [THEN] Item "SRC" is copied to "DST" without attributes
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", TargetItemNo);
        Assert.RecordIsEmpty(ItemAttributeValueMapping);

        LibraryVariableStorage.AssertEmpty;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemUnitsOfMeasureNotCopiedWhenRunItemCopyWithUoMOptionDisabled()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 273790] Report "Copy Item" resets values of item's alternative units of measure if the option "Units of measure" is not selected
        Initialize;

        // [GIVEN] Item with alternative units of measure in the card: "Sales Unit of Measure", "Purch. Unit of Measure" and "Put-away Unit of Measure"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with option "Item General Information" selected. All other options are disabled.
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(TargetItemNo, false, false, false, false, false, false, false, false, false, false);
        CopyItem(Item."No.");

        // [THEN] Item units of measure are not copied. "Base Unit of Measure", "Purch. Unit of Measure", "Sales Unit of Measure", "Put-away Unit of Measure" in the new item are blank
        ItemUnitOfMeasure.SetRange("Item No.", TargetItemNo);
        Assert.RecordIsEmpty(ItemUnitOfMeasure);

        Item.Get(TargetItemNo);
        Item.TestField("Base Unit of Measure", '');
        Item.TestField("Purch. Unit of Measure", '');
        Item.TestField("Sales Unit of Measure", '');
        Item.TestField("Put-away Unit of Measure Code", '');
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemUnitsOfMeasureCopiedWhenRunItemCopyWithUoMOptionEnabled()
    var
        Item: Record Item;
        ItemUnitOfMeasure: array[4] of Record "Item Unit of Measure";
        TargetItemNo: Code[20];
        I: Integer;
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 273790] Report "Copy Item" copies item's alternative units of measure if the option "Units of measure" is selected
        Initialize;

        // [GIVEN] Item with alternative units of measure in the card.
        // [GIVEN] "Purch. Unit of Measure" = "U1", "Sales Unit of Measure" = "U2", "Put-away Unit of Measure" = "U3"
        LibraryInventory.CreateItem(Item);

        for I := 1 to 3 do
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[I], Item."No.", LibraryRandom.RandInt(10));

        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure[1].Code);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure[2].Code);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure[3].Code);
        Item.Modify(true);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with option "Units of measure" selected
        TargetItemNo := LibraryUtility.GenerateGUID;
        EnqueueValuesForItemCopyRequestPageHandler(TargetItemNo, false, true, false, false, false, false, false, false, false, false);
        CopyItem(Item."No.");

        // [THEN] Alternative units of measure are copied to the new item. "Purch. Unit of Measure" = "U1", "Sales Unit of Measure" = "U2", "Put-away Unit of Measure" = "U3"
        Item.Get(TargetItemNo);
        Item.TestField("Purch. Unit of Measure", ItemUnitOfMeasure[1].Code);
        Item.TestField("Sales Unit of Measure", ItemUnitOfMeasure[2].Code);
        Item.TestField("Put-away Unit of Measure Code", ItemUnitOfMeasure[3].Code);

        for I := 1 to 3 do
            VerifyItemUnitOfMeasure(TargetItemNo, ItemUnitOfMeasure[I].Code);
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyGetTargetItemNosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultTargetItemNosValue()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        // [SCENARIO 296337] Report Copy Item has default "Target Item Nos." = InventorySetup."Item Nos."
        Initialize;

        // [GIVEN] Inventory Setup with "Item Nos." = "INOS"
        InventorySetup.Get;
        InventorySetup.Validate("Item Nos.", LibraryERM.CreateNoSeriesCode);
        InventorySetup.Modify;

        // [WHEN] Report "Copy Item" is being run
        Commit;
        REPORT.RunModal(REPORT::"Copy Item");

        // [THEN] "Target Item Nos." = "INOS"
        Assert.AreEqual(InventorySetup."Item Nos.", LibraryVariableStorage.DequeueText, 'Invalid Target Item Nos.');
    end;

    [Test]
    [HandlerFunctions('ItemCopyNumberOfEntriesTargetNoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TargetItemNoCheckWhenNuberOfCopiesGreaterThanOne()
    var
        Item: Record Item;
        NumberOfCopies: Integer;
    begin
        // [SCENARIO 296337] Target Item No must be incrementable when Number of Copies > 1
        Initialize;

        // [GIVEN]
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with Number Of Copies = 5 and Targed Item No. = "ABC"
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue('ABC');
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        asserterror CopyItem(Item."No.");

        // [THEN] Error "Target Item No. contains no number and cannot be incremented."
        Assert.ExpectedError(
          'The value in the Target Item No. field must have a number so that we can assign the next number in the series.');
    end;

    [Test]
    [HandlerFunctions('ItemCopySetTargetItemNosRequestPageHandler,NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemUsingTargetNumberSeries()
    var
        Item: Record Item;
        NoSeriesManagement: Codeunit NoSeriesManagement;
        TargetItemNo: Code[20];
        NoSeriesCode: Code[10];
    begin
        // [SCENARIO 296337] Report Copy Item creates new item using "Target No. Series" parameter
        Initialize;

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Number series "NOS" with next number "ITEM1"
        NoSeriesCode := CreateUniqItemNoSeries;
        TargetItemNo := NoSeriesManagement.GetNextNo(NoSeriesCode, WorkDate, false);

        // [WHEN] Run "Item Copy" report for item "I" with parameter "Target No. Series" = "NOS"
        LibraryVariableStorage.Enqueue(NoSeriesCode);
        CopyItem(Item."No.");

        // [THEN] New item created with "No." = "ITEM1"
        VerifyItemGeneralInformation(TargetItemNo, Item."Base Unit of Measure", Item.Description);

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyNumberOfEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithNumberOfCopiesMoreThanOneUseNumberSeries()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        TargetItemNo: Code[20];
        NumberOfCopies: Integer;
        i: Integer;
    begin
        // [SCENARIO 296337] User is able to create serveral item copies with parameter Number Of Copies and number series
        Initialize;

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);
        // Remember next number from InventorySetup."Item Nos."
        InventorySetup.Get;
        TargetItemNo := NoSeriesManagement.GetNextNo(InventorySetup."Item Nos.", WorkDate, false);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with Number Of Copies = 5
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        CopyItem(Item."No.");

        // [THEN] 5 new items created
        for i := 1 to NumberOfCopies do begin
            if i > 1 then
                TargetItemNo := IncStr(TargetItemNo);
            VerifyItemGeneralInformation(TargetItemNo, Item."Base Unit of Measure", Item.Description);
        end;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyNumberOfEntriesTargetNoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithNumberOfCopiesMoreThanOneUseTargetItemNo()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
        NumberOfCopies: Integer;
        i: Integer;
    begin
        // [SCENARIO 296337] User is able to create serveral item copies with parameter Number Of Copies and manual Target Item No.
        Initialize;

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run "Item Copy" report for item "I" with Number Of Copies = 5
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        TargetItemNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        CopyItem(Item."No.");

        // [THEN] 5 new items created
        for i := 1 to NumberOfCopies do begin
            if i > 1 then
                TargetItemNo := IncStr(TargetItemNo);
            VerifyItemGeneralInformation(TargetItemNo, Item."Base Unit of Measure", Item.Description);
        end;
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyNumberOfEntriesRequestPageHandler,ShowCreatedItemsSendNotificationHandler,ModalItemListHandler')]
    [Scope('OnPrem')]
    procedure OpenCopiedItemsListWhenNumberOfCopiesMoreThanOne()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        FirstItemNo: Code[20];
        LastItemNo: Code[20];
        NumberOfCopies: Integer;
        i: Integer;
    begin
        // [SCENARIO 296337] Report "Copy Item" opens item list with filtered created items
        Initialize;

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);
        // Remember next number from InventorySetup."Item Nos."
        InventorySetup.Get;
        FirstItemNo := NoSeriesManagement.GetNextNo(InventorySetup."Item Nos.", WorkDate, false);
        LastItemNo := FirstItemNo;

        // [GIVEN] Run "Item Copy" report for item "I" with Number Of Copies = 5
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        CopyItem(Item."No.");

        // [WHEN] Select "Show created items" notification action (in the ShowCreatedItemsSendNotificationHandler)
        // [THEN] Item list page opened with filter "ITEM1..ITEM5"
        for i := 1 to NumberOfCopies do
            if i > 1 then
                LastItemNo := IncStr(LastItemNo);
        Assert.AreEqual(
          StrSubstNo('%1..%2', FirstItemNo, LastItemNo),
          LibraryVariableStorage.DequeueText,
          'Invalid item No. filter');

        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [HandlerFunctions('ItemCopyNumberOfEntriesTargetNoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithTargetItemNoAndItemNosManualNo()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        TargetItemNo: Code[20];
    begin
        // [SCENARIO 296337] User should not be able to use target item number if InventorySetup."Item Nos." has Manual Nos. = No
        Initialize;

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] InventorySetup with "Item Nos." = "ITEMNOS" with "Manual Nos." = No
        InventorySetup.Get;
        NoSeries.Get(InventorySetup."Item Nos.");
        NoSeries."Manual Nos." := false;
        NoSeries.Modify;

        // [WHEN] Run "Copy Item" with default "Target Item No." = "ITEM1"
        TargetItemNo := LibraryUtility.GenerateGUID;
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(1);
        asserterror CopyItem(Item."No.");

        // [THEN] Error "You may not enter numbers manually..."
        Assert.ExpectedError('You may not enter numbers manually');
        NotificationLifecycleMgt.RecallAllNotifications;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringSalesLinesUseItemDescriptionTranslation()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Description: Text;
    begin
        // [FEATURE] [Recurring Sales Lines] [Item translation]
        // [SCENARIO 319744] ApplyStdCodesToSalesLines function in table 'Standard Customer Sales Code' uses Item Translation
        Initialize;

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Customer "C1" with Standard Sales Line defned for "I1" and 'Landuage Code' = "X"
        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);
        Customer.Get(StandardCustomerSalesCode."Customer No.");
        Customer.Validate("Language Code", GetRandomLanguageCode);
        Customer.Modify(true);
        // [GIVEN] "I1" has a translation for Landuage Code "X" = "D2"
        Description := CreateItemTranslationWithRecord(StandardSalesLine."No.", Customer."Language Code");

        // [WHEN] Run ApplyStdCodesToSalesLines with Sales Order for "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        StandardCustomerSalesCode.ApplyStdCodesToSalesLines(SalesHeader, StandardCustomerSalesCode);

        // [THEN] Sales Line created, Description = "D2"
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst;
        SalesLine.TestField(Description, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringPurchaseLinesUseItemDescriptionTranslation()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        Description: Text;
    begin
        // [FEATURE] [Recurring Purchase Lines] [Item translation]
        // [SCENARIO 319744] ApplyStdCodesToPurchaseLines function in table 'Standard Vendor Purchase Code' uses Item Translation
        Initialize;

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Vendor "V1" with Standard Purchase Line defned for "I1" and 'Landuage Code' = "X"
        CreateStandardPurchaseLinesWithItemForVendor(StandardPurchaseLine, StandardVendorPurchaseCode);
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        Vendor.Validate("Language Code", GetRandomLanguageCode);
        Vendor.Modify(true);

        // [GIVEN] "I1" has a translation for Landuage Code "X" = "D2"
        Description := CreateItemTranslationWithRecord(StandardPurchaseLine."No.", Vendor."Language Code");

        // [WHEN] Run ApplyStdCodesToPurchaseLines with Purchase Order for "V1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines(PurchaseHeader, StandardVendorPurchaseCode);

        // [THEN] Purchase Line created, Description = "D2"
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
        PurchaseLine.TestField(Description, Description);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear;
        LibrarySetupStorage.Restore;
        if IsInitialized then
            exit;

        IsInitialized := true;
        LibraryERMCountryData.UpdateGeneralPostingSetup;
        Commit;

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
    end;

    local procedure CreateBOMComponent(Item: Record Item; ParentItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryManufacturing.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item, Item."No.", QuantityPer, Item."Base Unit of Measure");
    end;

    local procedure CreateDefaultDimensionForItem(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get;
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateSeveralDefaultDimensionsForItem(ItemNo: Code[20]; NoOfDims: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        for i := 1 to NoOfDims do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    local procedure CreateExtendedText(var ExtendedTextLine: Record "Extended Text Line"; ItemNo: Code[20])
    var
        ExtendedTextHeader: Record "Extended Text Header";
    begin
        LibraryService.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        LibraryService.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CreateItemAttributeMappedToItem(ItemNo: Code[20])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(
          ItemAttributeValue, ItemAttribute.ID,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ItemAttributeValue.Value)), 1, MaxStrLen(ItemAttributeValue.Value)));
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, ItemNo, ItemAttribute.ID, ItemAttributeValue.ID);
    end;

    local procedure CreateItemCommentLine(ItemNo: Code[20]): Text[80]
    var
        CommentLine: Record "Comment Line";
    begin
        LibraryFixedAsset.CreateCommentLine(CommentLine, CommentLine."Table Name"::Item, ItemNo);
        CommentLine.Validate(Comment, LibraryUtility.GenerateGUID);
        CommentLine.Modify(true);
        exit(CommentLine.Comment);
    end;

    local procedure CreateItemTranslation(ItemNo: Code[20]) Description: Text[50]
    var
        Language: Record Language;
        ItemCard: TestPage "Item Card";
        ItemTranslations: TestPage "Item Translations";
    begin
        Language.FindFirst;
        Description := LibraryUtility.GenerateGUID;
        ItemCard.OpenEdit;
        ItemTranslations.Trap;
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemCard.Translations.Invoke;
        ItemTranslations."Language Code".SetValue(Language.Code);
        ItemTranslations.Description.SetValue(Description);
        ItemTranslations.OK.Invoke;
    end;

    local procedure CreateItemTranslationWithRecord(ItemNo: Code[20]; LanguageCode: Code[10]): Text[50]
    var
        ItemTranslation: Record "Item Translation";
    begin
        with ItemTranslation do begin
            Init;
            Validate("Item No.", ItemNo);
            Validate("Language Code", LanguageCode);
            Validate(Description, ItemNo + LanguageCode);
            Insert(true);
            exit(Description);
        end;
    end;

    local procedure CreateItemWithCommentLine(var Item: Record Item) Comment: Text[80]
    begin
        LibraryInventory.CreateItem(Item);
        Comment := CreateItemCommentLine(Item."No.");
    end;

    local procedure CreateItemWithSeveralCommentLines(var Item: Record Item; var Comments: array[3] of Text)
    var
        i: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        for i := 1 to ArrayLen(Comments) do
            Comments[i] := CreateItemCommentLine(Item."No.");
    end;

    local procedure CreateResourceSkill(var ResourceSkill: Record "Resource Skill"; ItemNo: Code[20])
    var
        SkillCode: Record "Skill Code";
    begin
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::Item, ItemNo, SkillCode.Code);
    end;

    local procedure CreatePurchasePriceWithLineDiscount(var PurchasePrice: Record "Purchase Price"; var PurchaseLineDiscount: Record "Purchase Line Discount"; Item: Record Item)
    begin
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, LibraryPurchase.CreateVendorNo, Item."No.", WorkDate, '', '', Item."Base Unit of Measure",
          LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", PurchasePrice."Vendor No.", WorkDate, '', '', Item."Base Unit of Measure",
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesPriceWithLineDiscount(var SalesPrice: Record "Sales Price"; var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item)
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesPrice."Sales Type"::Customer, LibrarySales.CreateCustomerNo, Item."No.", WorkDate,
          '', '', Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer,
          SalesPrice."Sales Code", WorkDate, '', '', Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateTroubleshootingHeader(var TroubleshootingHeader: Record "Troubleshooting Header")
    begin
        TroubleshootingHeader.Init;
        TroubleshootingHeader."No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(TroubleshootingHeader.FieldNo("No."), DATABASE::"Troubleshooting Header"),
            1,
            MaxStrLen(TroubleshootingHeader."No."));
        TroubleshootingHeader.Insert(true);
    end;

    local procedure CreateTroubleShootingSetup(var TroubleshootingSetup: Record "Troubleshooting Setup"; ItemNo: Code[20])
    var
        TroubleshootingHeader: Record "Troubleshooting Header";
    begin
        CreateTroubleshootingHeader(TroubleshootingHeader);
        LibraryService.CreateTroubleshootingSetup(
          TroubleshootingSetup, TroubleshootingSetup.Type::Item, ItemNo, TroubleshootingHeader."No.");
    end;

    local procedure CreateUniqItemNoSeries(): Code[10]
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NumberBase: Code[5];
    begin
        NumberBase := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(5, 0), 1, MaxStrLen(NumberBase));
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, NumberBase + '00001', NumberBase + '99999');

        InventorySetup.Get;
        LibraryUtility.CreateNoSeriesRelationship(InventorySetup."Item Nos.", NoSeries.Code);
        exit(NoSeries.Code);
    end;

    local procedure CreateStandardSalesLinesWithItemForCustomer(var StandardSalesLine: Record "Standard Sales Line"; var StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    var
        StandardSalesCode: Record "Standard Sales Code";
        Customer: Record Customer;
    begin
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);

        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code);
        StandardSalesLine.Type := StandardSalesLine.Type::Item;
        StandardSalesLine.Quantity := LibraryRandom.RandInt(10);
        StandardSalesLine."No." := LibraryInventory.CreateItemNo;
        StandardSalesLine.Modify;

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
    end;

    local procedure CreateStandardPurchaseLinesWithItemForVendor(var StandardPurchaseLine: Record "Standard Purchase Line"; var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code")
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);

        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Type := StandardPurchaseLine.Type::Item;
        StandardPurchaseLine.Quantity := LibraryRandom.RandInt(10);
        StandardPurchaseLine."No." := LibraryInventory.CreateItemNo;
        StandardPurchaseLine.Modify;

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
    end;

    local procedure CopyItem(ItemNo: Code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit;
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        Commit;  // COMMIT is required to handle Item Copy Request page.
        ItemCard.CopyItem.Invoke;
    end;

    local procedure CopyItemOnItemListPage(ItemNo: Code[20])
    var
        ItemList: TestPage "Item List";
    begin
        ItemList.OpenEdit;
        ItemList.FILTER.SetFilter("No.", ItemNo);
        Commit;  // COMMIT is required to handle Item Copy Request page.
        ItemList.CopyItem.Invoke;
    end;

    local procedure GetRandomLanguageCode(): Code[10]
    var
        Language: Record Language;
        RandNum: Integer;
    begin
        Language.Init;
        RandNum := LibraryRandom.RandIntInRange(1, Language.Count);
        Language.Next(RandNum);
        exit(Language.Code);
    end;

    local procedure EnqueueValuesForItemCopyRequestPageHandler(TargetItemNo: Code[20]; Comments: Boolean; UnitsOfMeasure: Boolean; Translations: Boolean; Dimensions: Boolean; ItemVariants: Boolean; ExtendedText: Boolean; Services: Boolean; Sales: Boolean; Purchase: Boolean; BOMComponent: Boolean)
    begin
        LibraryVariableStorage.Enqueue(TargetItemNo);  // Enqueue for Target Item No. on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(Comments);  // Enqueue for Comments on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(UnitsOfMeasure);  // Enqueue for Units of Measure on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(Translations);  // Enqueue for Translations on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(Dimensions);  // Enqueue for Dimensions on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemVariants);  // Enqueue for Item Variants on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(ExtendedText);  // Enqueue for ExtendedText on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(Services);  // Enqueue for Services on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(Sales);  // Enqueue for Sales on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(Purchase);  // Enqueue for Purchase on ItemCopyRequestPageHandler.
        LibraryVariableStorage.Enqueue(BOMComponent);  // Enqueue for BOMComponent on ItemCopyRequestPageHandler.
    end;

    local procedure VerifyBOMComponent(ParentItemNo: Code[20]; ItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.SetRange("No.", ItemNo);
        BOMComponent.FindFirst;
        BOMComponent.TestField("Quantity per", QuantityPer);
    end;

    local procedure VerifyCommentLine(ItemNo: Code[20]; Comment: Text[80])
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", ItemNo);
        CommentLine.FindFirst;
        CommentLine.TestField(Comment, Comment);
    end;

    local procedure VerifyExtendedText(ExtendedTextLine: Record "Extended Text Line"; ItemNo: Code[20])
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine2: Record "Extended Text Line";
    begin
        ExtendedTextHeader.Get(ExtendedTextLine."Table Name", ItemNo, ExtendedTextLine."Language Code", ExtendedTextLine."Text No.");
        ExtendedTextLine2.Get(
          ExtendedTextHeader."Table Name", ItemNo, ExtendedTextHeader."Language Code", ExtendedTextHeader."Text No.",
          ExtendedTextLine."Line No.");
    end;

    local procedure VerifyPurchasePrice(PurchasePrice: Record "Purchase Price"; ItemNo: Code[20])
    var
        PurchasePrice2: Record "Purchase Price";
    begin
        PurchasePrice2.SetRange("Item No.", ItemNo);
        PurchasePrice2.SetRange("Vendor No.", PurchasePrice."Vendor No.");
        PurchasePrice2.FindFirst;
        PurchasePrice2.TestField("Minimum Quantity", PurchasePrice."Minimum Quantity");
    end;

    local procedure VerifyPurchaseLineDiscount(PurchaseLineDiscount: Record "Purchase Line Discount"; ItemNo: Code[20])
    begin
        PurchaseLineDiscount.SetRange("Item No.", ItemNo);
        PurchaseLineDiscount.SetRange("Vendor No.", PurchaseLineDiscount."Vendor No.");
        PurchaseLineDiscount.FindFirst;
        PurchaseLineDiscount.TestField("Minimum Quantity", PurchaseLineDiscount."Minimum Quantity");
    end;

    local procedure VerifySalesLineDiscount(ItemNo: Code[20]; LineDiscount: Decimal)
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.SetRange(Code, ItemNo);
        SalesLineDiscount.FindFirst;
        SalesLineDiscount.TestField("Line Discount %", LineDiscount);
    end;

    local procedure VerifySalesPrice(SalesPrice: Record "Sales Price"; ItemNo: Code[20])
    var
        SalesPrice2: Record "Sales Price";
    begin
        SalesPrice2.SetRange("Item No.", ItemNo);
        SalesPrice2.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice2.SetRange("Sales Code", SalesPrice."Sales Code");
        SalesPrice2.FindFirst;
        SalesPrice2.TestField("Minimum Quantity", SalesPrice."Minimum Quantity");
    end;

    local procedure VerifyItemGeneralInformation(ItemNo: Code[20]; BaseUnitofMeasure: Code[10]; Description: Text[100])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.TestField("Base Unit of Measure", BaseUnitofMeasure);
        Item.TestField(Description, Description);
    end;

    local procedure VerifyItemTranslation(ItemNo: Code[20]; Description: Text[50])
    var
        ItemTranslation: Record "Item Translation";
    begin
        ItemTranslation.SetRange("Item No.", ItemNo);
        ItemTranslation.FindFirst;
        ItemTranslation.TestField(Description, Description);
    end;

    local procedure VerifyItemUnitOfMeasure(ItemNo: Code[20]; UoMCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.SetRange(Code, UoMCode);
        Assert.RecordCount(ItemUnitOfMeasure, 1);
    end;

    local procedure VerifyItemVariant(ItemVariant: Record "Item Variant"; ItemNo: Code[20])
    begin
        ItemVariant.Get(ItemNo, ItemVariant.Code);
        ItemVariant.TestField(Code, ItemVariant.Code);
        ItemVariant.TestField(Description, ItemVariant.Description);
    end;

    local procedure VerifyDefaultDimension(DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    begin
        DefaultDimension.Get(DefaultDimension."Table ID", ItemNo, DefaultDimension."Dimension Code");
        DefaultDimension.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyItemAttributes(SourceItemNo: Code[20]; TargetItemNo: Code[20])
    var
        SourceItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TargetItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        SourceItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        SourceItemAttributeValueMapping.SetRange("No.", SourceItemNo);

        TargetItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        TargetItemAttributeValueMapping.SetRange("No.", TargetItemNo);

        Assert.AreEqual(SourceItemAttributeValueMapping.Count, TargetItemAttributeValueMapping.Count, NoOfRecordsMismatchErr);

        SourceItemAttributeValueMapping.FindSet;
        repeat
            TargetItemAttributeValueMapping.Get(DATABASE::Item, TargetItemNo, SourceItemAttributeValueMapping."Item Attribute ID");
            TargetItemAttributeValueMapping.TestField("Item Attribute Value ID", SourceItemAttributeValueMapping."Item Attribute Value ID");
        until SourceItemAttributeValueMapping.Next = 0;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCopyRequestPageHandler(var ItemCopy: TestRequestPage "Copy Item")
    var
        ExtendedText: Boolean;
        UnitsOfMeasure: Boolean;
        Comments: Boolean;
        Services: Boolean;
        Sales: Boolean;
        Purchase: Boolean;
        Translations: Boolean;
        Dimensions: Boolean;
        ItemVariants: Boolean;
        BOMComponent: Boolean;
    begin
        ItemCopy.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText);
        ItemCopy.GeneralItemInformation.SetValue(true);

        Comments := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.Comments.SetValue(Comments);

        UnitsOfMeasure := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.UnitsOfMeasure.SetValue(UnitsOfMeasure);

        Translations := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.Translations.SetValue(Translations);

        Dimensions := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.Dimensions.SetValue(Dimensions);

        ItemVariants := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.ItemVariants.SetValue(ItemVariants);

        ExtendedText := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.ExtendedTexts.SetValue(ExtendedText);

        Services := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.Troubleshooting.SetValue(Services);
        ItemCopy.ResourceSkills.SetValue(Services);

        Sales := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.SalesPrices.SetValue(Sales);
        ItemCopy.SalesLineDisc.SetValue(Sales);

        Purchase := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.PurchasePrices.SetValue(Purchase);
        ItemCopy.PurchaseLineDisc.SetValue(Purchase);

        BOMComponent := LibraryVariableStorage.DequeueBoolean;
        ItemCopy.BOMComponents.SetValue(BOMComponent);
        ItemCopy.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCopyAttributesRequestPageHandler(var ItemCopy: TestRequestPage "Copy Item")
    begin
        ItemCopy.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText);
        ItemCopy.GeneralItemInformation.SetValue(true);
        ItemCopy.Attributes.SetValue(LibraryVariableStorage.DequeueBoolean);
        ItemCopy.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCopyNumberOfEntriesRequestPageHandler(var ItemCopy: TestRequestPage "Copy Item")
    begin
        ItemCopy.GeneralItemInformation.SetValue(true);
        ItemCopy.NumberOfCopies.SetValue(LibraryVariableStorage.DequeueInteger);
        ItemCopy.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCopyNumberOfEntriesTargetNoRequestPageHandler(var ItemCopy: TestRequestPage "Copy Item")
    begin
        ItemCopy.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText);
        ItemCopy.GeneralItemInformation.SetValue(true);
        ItemCopy.NumberOfCopies.SetValue(LibraryVariableStorage.DequeueInteger);
        ItemCopy.OK.Invoke;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCopyGetTargetItemNosRequestPageHandler(var ItemCopy: TestRequestPage "Copy Item")
    begin
        LibraryVariableStorage.Enqueue(ItemCopy.TargetNoSeries.Value);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemCopySetTargetItemNosRequestPageHandler(var ItemCopy: TestRequestPage "Copy Item")
    begin
        ItemCopy.TargetNoSeries.AssistEdit;
        ItemCopy.OK.Invoke;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalItemCardHandler(var ItemCard: TestPage "Item Card")
    begin
        LibraryVariableStorage.Enqueue(ItemCard."No.".Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalItemListHandler(var ItemList: TestPage "Item List")
    begin
        LibraryVariableStorage.Enqueue(ItemList.FILTER.GetFilter("No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series List")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText);
        NoSeriesList.OK.Invoke;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowCreatedItemsSendNotificationHandler(var Notification: Notification): Boolean
    var
        CopyItem: Codeunit "Copy Item";
    begin
        CopyItem.ShowCreatedItems(Notification);
    end;
}
