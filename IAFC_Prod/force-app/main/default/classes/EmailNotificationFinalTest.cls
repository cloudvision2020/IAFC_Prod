@isTest
public class EmailNotificationFinalTest {  
    
    public static List<OrderApi__Sales_Order_Line__c> returnedSOL;
    public static decimal returnedtotalvalue;
    public static String ordername;
    public static List<OrderApi__Subscription__c> returnSubscription;


    
    @testSetup static void testRecords(){
  Contact con = new Contact(FirstName='test',
                                  LastName='Con',
                                  email='testcon@gmail.com');
        
        insert con;
        
     OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c(OrderApi__Entity__c='Contact',OrderApi__Status__c = 'closed',OrderApi__Posting_Status__c = 'pending',OrderApi__Contact__c = Con.id);
        insert so;
        
        OrderApi__Sales_Order_Line__c sol = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=so.Id,
                                                                              OrderApi__Quantity__c=1,
                                                                              OrderApi__Sale_Price__c=20);
        insert sol;
        
        OrderApi__Subscription_Plan__c subsPlan = new OrderApi__Subscription_Plan__c(Name='test sub plan',
                                                                                     OrderApi__Type__c='Termed',
                                                                                     OrderApi__Is_Active__c=true,
                                                                                     OrderApi__Initial_Term_Months__c=12);
        insert subsPlan;
        
        OrderApi__Subscription__c ordSubs = new OrderApi__Subscription__c(OrderApi__Entity__c='Contact',
                                                                          OrderApi__Status__c='Active',
                                                                          OrderApi__Subscription_Plan__c=subsPlan.Id,
                                                                         OrderApi__Sales_Order_Line__c=sol.Id,OrderApi__Contact__c=con.Id);
        insert ordSubs;
        
        OrderApi__Renewal__c ordRenewal = new OrderApi__Renewal__c(OrderApi__Sales_Order__c=so.Id,
                                                                   OrderApi__Subscription__c=ordSubs.Id,
                                                                   OrderApi__Is_Active__c=true);
        insert ordRenewal;
    }
    
    @isTest static void validateRecords(){
        
        EmailNotificationFinal enr = new EmailNotificationFinal();
        
        test.startTest();
        
        Contact os = [Select Id from Contact limit 1];
        enr.ContactId = os.Id;
        
        returnedSOL=enr.returnSalesOrderLI;
        returnedtotalvalue=enr.returntotalvalue;
        ordername = enr.ordername;
        returnSubscription = enr.returnSubscription;
        test.stopTest();
        
        system.assertEquals(1, returnedSOL.size());
        system.assertEquals(20.0, returnedtotalvalue);
        
    }
}