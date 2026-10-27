@isTest
private class ItemTriggerHandler2Test {
    @isTest 
    static void handleItemChangeTest(){
        // Record Types
        Id boothRecordId = Schema.SObjectType.s7e__Item__c.getRecordTypeInfosByName().get('Exhibit Space').getRecordTypeId();
        Id otherRecordId = Schema.SObjectType.s7e__Item__c.getRecordTypeInfosByName().get('Sponsorship').getRecordTypeId();

        // Account and Contact
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        Contact con = new Contact(FirstName = 'Test', LastName = 'User', Email = 'test@example.com', AccountId = acc.Id);
        insert con;

        // Insert Fonteva-required records
        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='Test-1');
        insert businessGroup;
        
        // Insert Sales Orders - one posted and one not posted
        OrderApi__Sales_Order__c salesOrder = new OrderApi__Sales_Order__c(
            OrderApi__Business_Group__c = businessGroup.Id,
            OrderApi__Is_Posted__c = false,
            OrderApi__Is_Closed__c = false,
            OrderApi__Overall_Total__c = 150
        );
        insert salesOrder;
        
        OrderApi__Sales_Order__c salesOrder1 = new OrderApi__Sales_Order__c(
            OrderApi__Business_Group__c = businessGroup.Id,
            OrderApi__Is_Posted__c = true,
            OrderApi__Is_Closed__c = false,
            OrderApi__Overall_Total__c = 150
        );
        insert salesOrder1;
        
        // Insert Show
        s7e__Show_Type__c showType = new s7e__Show_Type__c(Name = 'Test Type');
        insert showType;

        s7e__Show__c show = new s7e__Show__c(
            Name = 'Test Show',
            s7e__Financials__c = true,
            s7e__Financial_System__c = 'Fonteva',
            Fonteva_Business_Group__c = businessGroup.Id,
            s7e__Initial_Payment__c = 10,
            s7e__X1st_Payment__c = 20,
            s7e__X1st_Payment_Due_Date__c = System.today().addDays(30),
            s7e__X2nd_Payment__c = 30,
            s7e__X2nd_Payment_Due_Date__c = System.today().addDays(60),
            s7e__X3rd_Payment__c = 40,
            s7e__X3rd_Payment_Due_Date__c = System.today().addDays(90),
            s7e__Show_Time_Zone__c = 'GMT+09:00 Yakutsk Standard Time',
            s7e__Show_Abbreviation__c = 'TST1',
            s7e__Show_Type_Lookup__c = showType.Id
        );
        insert show;
        
        // Opportunities and OCRs for both sales orders
        Opportunity opp = new Opportunity(
            Name = 'Opp', 
            s7e__Show__c = show.Id, 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = acc.Id, 
            s7e__Ext_Sales_Order_ID__c = salesOrder.Id
        );
        insert opp;
        
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp.Id, 
            ContactId = con.Id, 
            IsPrimary = true
        );
        insert ocr;
        
        Opportunity opp1 = new Opportunity(
            Name = 'Opp1', 
            s7e__Show__c = show.Id, 
            StageName = 'Prospecting', 
            CloseDate = Date.today(), 
            AccountId = acc.Id
            //, 
            //s7e__Ext_Sales_Order_ID__c = salesOrder1.Id
        );
        insert opp1;
        
        OpportunityContactRole ocr1 = new OpportunityContactRole(
            OpportunityId = opp1.Id, 
            ContactId = con.Id, 
            IsPrimary = true
        );
        insert ocr1;

        // Fonteva Item Classes
        OrderApi__Item_Class__c fontevaItemClass = new OrderApi__Item_Class__c(
            Name = 'Exhibit Space', 
            OrderApi__Business_Group__c = businessGroup.Id
        );
        insert fontevaItemClass;
        
        OrderApi__Item_Class__c fontevaSponsorItemClass = new OrderApi__Item_Class__c(
            Name = 'Sponsorship', 
            OrderApi__Business_Group__c = businessGroup.Id
        );
        insert fontevaSponsorItemClass;
        
        // Fonteva Items
        OrderApi__Item__c fontevaItem = new OrderApi__Item__c(
            Name = 'Fonteva Item', 
            OrderApi__Price__c = 100, 
            OrderApi__Item_Class__c = fontevaItemClass.Id
        );
        insert fontevaItem;
        
        OrderApi__Item__c fontevaCornerItem = new OrderApi__Item__c(
            Name = 'Fonteva Corner Item', 
            OrderApi__Price__c = 100, 
            OrderApi__Item_Class__c = fontevaItemClass.Id
        );
        insert fontevaCornerItem;
        
        OrderApi__Item__c fontevaSponsorItem = new OrderApi__Item__c(
            Name = 'Fonteva Sponsor Item', 
            OrderApi__Price__c = 100, 
            OrderApi__Item_Class__c = fontevaSponsorItemClass.Id
        );
        insert fontevaSponsorItem;
        
        // Fonteva Price Rules
        OrderApi__Price_Rule__c priceRule = new OrderApi__Price_Rule__c(
            Name = 'DEFAULT',
            OrderApi__Price__c = 100,
            OrderApi__Item__c = fontevaItem.Id, 
            OrderApi__Item_Class__c = fontevaItemClass.Id
        );
        insert priceRule;
        
        OrderApi__Price_Rule__c priceRule1 = new OrderApi__Price_Rule__c(
            Name = 'DEFAULT',
            OrderApi__Price__c = 100,
            OrderApi__Item__c = fontevaCornerItem.Id, 
            OrderApi__Item_Class__c = fontevaItemClass.Id
        );
        insert priceRule1;
        
        OrderApi__Price_Rule__c priceRule2 = new OrderApi__Price_Rule__c(
            Name = 'DEFAULT',
            OrderApi__Price__c = 100,
            OrderApi__Item__c = fontevaSponsorItem.Id, 
            OrderApi__Item_Class__c = fontevaSponsorItemClass.Id
        );
        insert priceRule2;
        
        // Fonteva Sales Order Line Items
        OrderApi__Sales_Order_Line__c soli = new OrderApi__Sales_Order_Line__c(
            OrderApi__Account__c = acc.Id, 
            OrderApi__Business_Group__c = businessGroup.Id, 
            OrderApi__Contact__c = con.Id, 
            OrderApi__Sales_Order__c = salesOrder.Id
        );
        
        OrderApi__Sales_Order_Line__c soli1 = new OrderApi__Sales_Order_Line__c(
            OrderApi__Account__c = acc.Id, 
            OrderApi__Business_Group__c = businessGroup.Id, 
            OrderApi__Contact__c = con.Id, 
            OrderApi__Sales_Order__c = salesOrder.Id
        ); 
        
        OrderApi__Sales_Order_Line__c soli2 = new OrderApi__Sales_Order_Line__c(
            OrderApi__Account__c = acc.Id, 
            OrderApi__Business_Group__c = businessGroup.Id, 
            OrderApi__Contact__c = con.Id, 
            OrderApi__Sales_Order__c = salesOrder1.Id
        );        
        
        insert new List<OrderApi__Sales_Order_Line__c>{soli, soli1, soli2};
        
        // Create different scenarios of Items
        List<s7e__Item__c> items = new List<s7e__Item__c>{
            // Booth item on Hold without Line Item ID
            new s7e__Item__c(
                RecordTypeId = boothRecordId,
                s7e__Status__c = 'Hold',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp.Id,
                s7e__Ex_ProductId__c = fontevaItem.Id,
                s7e__Show__c = show.Id,
                s7e__No_of_Open_Corners__c = 0,
                s7e__Item_Quantity__c = 1
            ),
            
            // Booth item with empty status without Line Item ID
            new s7e__Item__c(
                RecordTypeId = boothRecordId,
                s7e__Status__c = '',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp.Id,
                s7e__Ex_ProductId__c = fontevaCornerItem.Id,
                s7e__Show__c = show.Id,
                s7e__No_of_Open_Corners__c = 0,
                s7e__Item_Quantity__c = 1
            ),
            
            // Sponsorship item Confirmed for posted order
            new s7e__Item__c(
                RecordTypeId = otherRecordId,
                s7e__Status__c = 'Confirmed',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp1.Id,
                s7e__Ex_ProductId__c = fontevaSponsorItem.Id,
                s7e__Show__c = show.Id,
                s7e__Item_Quantity__c = 1
            ),
            
            // Booth item on Hold with Line Item ID and open corners
            new s7e__Item__c(
                RecordTypeId = boothRecordId,
                s7e__Status__c = 'Hold',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp.Id,
                s7e__Ex_ProductId__c = fontevaItem.Id,
                s7e__Show__c = show.Id,
                s7e__No_of_Open_Corners__c = 2,
                s7e__Item_Quantity__c = 1,
                s7e__Ext_Line_Item_ID__c = soli.Id
            ),
            
            // Booth item Confirmed with Line Item ID
            new s7e__Item__c(
                RecordTypeId = boothRecordId,
                s7e__Status__c = 'Confirmed',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp.Id,
                s7e__Ex_ProductId__c = fontevaCornerItem.Id,
                s7e__Show__c = show.Id,
                s7e__No_of_Open_Corners__c = 0,
                s7e__Item_Quantity__c = 1,
                s7e__Ext_Line_Item_ID__c = soli1.Id
            ),
            
            // Booth item Confirmed with Line Item ID and open corners
            new s7e__Item__c(
                RecordTypeId = boothRecordId,
                s7e__Status__c = 'Confirmed',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp.Id,
                s7e__Ex_ProductId__c = fontevaCornerItem.Id,
                s7e__Show__c = show.Id,
                s7e__No_of_Open_Corners__c = 2,
                s7e__Item_Quantity__c = 1,
                s7e__Ext_Line_Item_ID__c = soli1.Id
            ),
            
            // Sponsorship item Confirmed with quantity 3 and Line Item ID for posted order
            new s7e__Item__c(
                RecordTypeId = otherRecordId,
                s7e__Status__c = 'Confirmed',
                s7e__Account__c = acc.Id,
                s7e__Opportunity__c = opp1.Id,
                s7e__Ex_ProductId__c = fontevaSponsorItem.Id,
                s7e__Show__c = show.Id,
                s7e__Item_Quantity__c = 3,
                s7e__Ext_Line_Item_ID__c = soli2.Id
            )
        };
        
        // Insert all items at once to ensure single trigger execution
        Test.startTest();
        insert items;
        
        // Prepare updates to items to test different scenarios
        List<s7e__Item__c> updatedItems = new List<s7e__Item__c>();
        for(s7e__Item__c item : items){
            // For Sponsorship items, test quantity changes
            if(item.RecordTypeId == otherRecordId){
                if (item.s7e__Item_Quantity__c > 2) {
                    item.s7e__Item_Quantity__c -= 1; // Decrease quantity if > 2
                } else {
                    item.s7e__Item_Quantity__c += 1; // Increase quantity if <= 2
                }
            } 
            // For Booth items, test status changes
            else {
                if (item.s7e__Status__c == 'Confirmed') {
                    // Reset confirmed items to available (empty status)
                    item.s7e__Status__c = '';
                    item.s7e__Account__c = null;
                    item.s7e__Opportunity__c = null;
                    item.s7e__Ex_ProductId__c = null;
                } else {
                    // Set available/hold items to confirmed
                    item.s7e__Status__c = 'Confirmed';
                }
            }
            
            updatedItems.add(item);
        }
        
        // Update all items to trigger the handler
        update updatedItems;
        
        ItemTriggerHandler2.logError('Test error');
        ItemTriggerHandler2.insertLog('Test insert log');
        
        Test.stopTest();
    }
    
}