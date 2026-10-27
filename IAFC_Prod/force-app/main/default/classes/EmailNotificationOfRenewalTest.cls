@isTest
private class EmailNotificationOfRenewalTest {
    
    public static List<OrderApi__Sales_Order_Line__c> returnedSOL;
    public static decimal returnedtotalvalue;
    
    @testSetup static void testRecords(){
        
        Account acc = new Account(Name='test Account');
        insert acc;
        
        Contact con = new Contact(FirstName='test',
                                  LastName='Con',
                                  AccountId=acc.Id);
        insert con;
        
        acc.OrderApi__Primary_Contact__c=con.Id;
        update acc;
        
       	OrderApi__Item_Class__c ic = new OrderApi__Item_Class__c(Name='Test Item class',
                                                                 OrderApi__Is_Active__c=true);
        insert ic;
        
        OrderApi__Item__c it = new OrderApi__Item__c(Name='Test item',
                                                     OrderApi__Item_Class__c=ic.Id,
                                                     OrderApi__Price__c=20.0,
                                                     OrderApi__Is_Active__c=true,
                                                     OrderApi__Is_Subscription__c=true,
                                                     OrderApi__Enable_Assignments__c=true);
        insert it;
 		
        OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c(OrderApi__Account__c=acc.Id,
                                                                   OrderApi__Entity__c='Account');
        insert so;
        
        OrderApi__Sales_Order_Line__c sol = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=so.Id,
                                                                              OrderApi__Item__c=it.Id,
                                                                              OrderApi__Quantity__c=1,
                                                                              OrderApi__Sale_Price__c=20);
        insert sol;
        
        OrderApi__Subscription_Plan__c subsPlan = new OrderApi__Subscription_Plan__c(Name='test sub plan',
                                                                                     OrderApi__Type__c='Termed',
                                                                                     OrderApi__Is_Active__c=true,
                                                                                     OrderApi__Initial_Term_Months__c=12);
        insert subsPlan;
        
        OrderApi__Subscription__c ordSubs = new OrderApi__Subscription__c(OrderApi__Account__c=acc.Id,
                                                                          OrderApi__Entity__c='Account',
                                                                          OrderApi__Status__c='Active',
                                                                          OrderApi__Subscription_Plan__c=subsPlan.Id,
                                                                          OrderApi__Item__c=it.Id,
                                                                          OrderApi__Sales_Order_Line__c=sol.Id);
        insert ordSubs;
        
        OrderApi__Renewal__c ordRenewal = new OrderApi__Renewal__c(OrderApi__Sales_Order__c=so.Id,
                                                                   OrderApi__Subscription__c=ordSubs.Id,
                                                                   OrderApi__Is_Active__c=true);
        insert ordRenewal;
	}
	
    @isTest static void validateRecords(){
        
        EmailNotificationOfRenewal enr = new EmailNotificationOfRenewal();
        
        test.startTest();
        
        OrderApi__Subscription__c os = [Select Id from OrderApi__Subscription__c limit 1];
        enr.subscriptionId = os.Id;
        
        returnedSOL=enr.returnSalesOrderLI;
		returnedtotalvalue=enr.returntotalvalue;
		        
        test.stopTest();
        
        system.assertEquals(1, returnedSOL.size());
        system.assertEquals(20.0, returnedtotalvalue);
                
    }
}