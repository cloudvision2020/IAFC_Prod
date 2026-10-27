@istest
Public class FS_AllAccountContactsControllerTest{
    @istest
    static void test(){
    
        //Inserting Account
        Account a=FS_TestUtils.createAccount('test');
        insert a;
        System.debug('=='+a.id);

        //Inserting contact
        contact c=FS_TestUtils.createContact('testrecord','contact@test.com');
        c.accountid=a.id;
        c.Title='Manager';
        c.Membership_Type__c='Prospect';
        c.Sections__c='';
        insert c;
        
        //Inserting Itemclass
        OrderApi__Item_Class__c itemclass=FS_TestUtils.createItemClass('books');
        insert itemclass;
        
        //Inserting item
        OrderApi__Item__c item=FS_TestUtils.createItem('Novel',itemclass.id);
        insert item;
        
        //Inserting subscriptionplan
        OrderApi__Subscription_Plan__c plan=FS_TestUtils.createSubsPlan('2 Year Anniversary Membership');
        insert plan;
        
        //Inserting salesOrder
        OrderApi__Sales_Order__c order=FS_TestUtils.createSalesOrder(c.id,a.id,'Receipt','Closed');
        insert order;
        
        //Inserting salesOrderLine
        OrderApi__Sales_Order_Line__c orderLine=FS_TestUtils.createSalesOrderLine(item.id,order.id,c.id,a.id);
        insert orderLine;
        
        //Inserting subscription
        OrderApi__Subscription__c sub=FS_TestUtils.createSubscription(item.id,plan.id,a.id,c.id,orderLine.id);
        insert sub;


        //Inserting renewal
        OrderApi__Renewal__c renewal=new OrderApi__Renewal__c();
        renewal.OrderApi__Subscription__c=sub.id;
        renewal.OrderApi__Sales_Order__c=order.id;
        renewal.OrderApi__Is_Active__c=true;
        renewal.OrderApi__Term_Start_Date__c=Date.newInstance(2019,01,02);
        renewal.OrderApi__Term_End_Date__c=Date.newInstance(2020,01,02);
        insert renewal;


        List<OrderApi__Renewal__c> renewals=[select id,FS_Purchased_via_Group_Membership__c from OrderApi__Renewal__c where id=:renewal.id];
        System.debug('=='+renewals[0].FS_Purchased_via_Group_Membership__c);
        
        Test.startTest();
        PageReference pageRef = Page.FS_AllAccountContacts; 
        pageRef.getParameters().put('id', String.valueOf(a.Id));
        Test.setCurrentPage(pageRef);
        FS_AllAccountContactsController contr=new FS_AllAccountContactsController();
        contr.getContactsOnAccount();
        contr.getAccountName();
        contr.getFooterLabel();

        Test.stopTest();
        
    }
}