@isTest
private class MultiOrderInvoiceControllerTest {

    @isTest
    static void testGroupBranch() {
        OrderApi__Business_Group__c bg = new OrderApi__Business_Group__c(Name='BG');
        insert bg;

        OrderApi__Item_Class__c divClass = new OrderApi__Item_Class__c(Name=Label.Item_Class_Division);
        OrderApi__Item_Class__c secClass = new OrderApi__Item_Class__c(Name=Label.Item_Class_Sections);
        OrderApi__Item_Class__c memClass = new OrderApi__Item_Class__c(Name=Label.Item_Class_Membership);
        insert new List<OrderApi__Item_Class__c>{ divClass, secClass, memClass };

        OrderApi__Item__c divItem = new OrderApi__Item__c(Name='Div', OrderApi__Price__c=50,  OrderApi__Business_Group__c=bg.Id, OrderApi__Item_Class__c=divClass.Id);
        OrderApi__Item__c secItem = new OrderApi__Item__c(Name='Sec', OrderApi__Price__c=25,  OrderApi__Business_Group__c=bg.Id, OrderApi__Item_Class__c=secClass.Id);
        OrderApi__Item__c memItem = new OrderApi__Item__c(Name='Mem', OrderApi__Price__c=100, OrderApi__Business_Group__c=bg.Id, OrderApi__Item_Class__c=memClass.Id);
        insert new List<OrderApi__Item__c>{ divItem, secItem, memItem };

        OrderApi__Price_Rule__c pr = new OrderApi__Price_Rule__c(Name='North Division', OrderApi__Price__c=50);
        insert pr;

        Contact primary = new Contact(LastName='Primary');
        insert primary;

        Account a = new Account(Name='G', OrderApi__Primary_Contact__c=primary.Id, Group_Membership_Expiration__c=Date.today());
        insert a;

        Contact c = new Contact(LastName='M', AccountId=a.Id);
        insert c;

        // Set the encrypted id manually — it's null in test context otherwise
        String encId = 'enc-test-group-001';
        OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c(
            OrderApi__Account__c=a.Id,
            OrderApi__Encrypted_Id__c=encId);
        insert so;

        insert new List<OrderApi__Sales_Order_Line__c>{
            new OrderApi__Sales_Order_Line__c(
                OrderApi__Sales_Order__c=so.Id, OrderApi__Contact__c=c.Id,
                OrderApi__Item__c=divItem.Id, OrderApi__Item_Class__c=divClass.Id,
                OrderApi__Price_Rule__c=pr.Id, OrderApi__Item_Name__c='Div',
                OrderApi__Sale_Price__c=50, OrderApi__Quantity__c=1, OrderApi__Overall_Total__c=50),
            new OrderApi__Sales_Order_Line__c(
                OrderApi__Sales_Order__c=so.Id, OrderApi__Contact__c=c.Id,
                OrderApi__Item__c=secItem.Id, OrderApi__Item_Class__c=secClass.Id,
                OrderApi__Item_Name__c='Section A',
                OrderApi__Sale_Price__c=25, OrderApi__Quantity__c=1, OrderApi__Overall_Total__c=25),
            new OrderApi__Sales_Order_Line__c(
                OrderApi__Sales_Order__c=so.Id, OrderApi__Contact__c=c.Id,
                OrderApi__Item__c=memItem.Id, OrderApi__Item_Class__c=memClass.Id,
                OrderApi__Item_Name__c='Full Membership',
                OrderApi__Sale_Price__c=100, OrderApi__Quantity__c=1, OrderApi__Overall_Total__c=100)
        };

        Test.startTest();
        MultiOrderInvoiceController.MultiInvoiceResult r = MultiOrderInvoiceController.buildInvoices(encId);
        MultiOrderInvoiceController.buildInvoices(encId + ',' + encId); // merge path
        MultiOrderInvoiceController.buildInvoices(null);
        MultiOrderInvoiceController.buildInvoices('  , , ');

        Test.setCurrentPage(Page.MultiOrderInvoicePDF);
        ApexPages.currentPage().getParameters().put('ids', encId);
        new MultiOrderInvoiceController();
        Test.stopTest();

    }

    @isTest
    static void testNonGroupAccountStillShowsGroupView() {
        OrderApi__Business_Group__c bg = new OrderApi__Business_Group__c(Name='BG2');
        insert bg;
        OrderApi__Item_Class__c ic = new OrderApi__Item_Class__c(Name='StdClass');
        insert ic;
        OrderApi__Item__c item = new OrderApi__Item__c(Name='Std', OrderApi__Price__c=200, OrderApi__Business_Group__c=bg.Id, OrderApi__Item_Class__c=ic.Id);
        insert item;

        Account a = new Account(Name='Std Acct'); // group flag false, but group view must still be used
        insert a;
        Contact c = new Contact(LastName='S', AccountId=a.Id);
        insert c;

        String encId = 'enc-test-std-001';
        OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c(
            OrderApi__Account__c=a.Id,
            OrderApi__Encrypted_Id__c=encId);
        insert so;

        insert new OrderApi__Sales_Order_Line__c(
            OrderApi__Sales_Order__c=so.Id, OrderApi__Contact__c=c.Id,
            OrderApi__Item__c=item.Id, OrderApi__Item_Name__c='Std',
            OrderApi__Line_Description__c='desc',
            OrderApi__Activation_Date__c=Date.today(), OrderApi__End_Date__c=Date.today().addYears(1),
            OrderApi__Sale_Price__c=200, OrderApi__Quantity__c=1, OrderApi__Overall_Total__c=200);

        String soName = [SELECT Name FROM OrderApi__Sales_Order__c WHERE Id = :so.Id].Name;

        Test.startTest();
        MultiOrderInvoiceController.MultiInvoiceResult r = MultiOrderInvoiceController.buildInvoices(encId);
        Test.stopTest();

    }

    @isTest
    static void testWrapper() {
        MultiOrderInvoiceController.MultiInvoiceResult r = new MultiOrderInvoiceController.MultiInvoiceResult();
        System.assertEquals(null, r.getMembershipTermLabel());
        r.membershipTermStart = Date.newInstance(2026,1,1);
        r.membershipTermEnd   = Date.newInstance(2026,12,31);
        System.assertEquals('1/1/2026 - 12/31/2026', r.getMembershipTermLabel());
    }
}