@isTest
public class SentReceiptTest {  
    
    public static List<OrderApi__Receipt_Line__c> returnedRecL;
    public static decimal returnedtotalvalue;
    
    @testSetup static void testRecords(){
        Contact con = new Contact(FirstName='test',
                                  LastName='Con',Has_Group_Membership__c = False);
        
        insert con;
        
        OrderApi__Sales_Order__c so = new OrderApi__Sales_Order__c(OrderApi__Entity__c='Contact',OrderApi__Status__c = 'closed',OrderApi__Posting_Status__c = 'Posted',OrderApi__Contact__c = Con.id);
        insert so;
        
        OrderApi__Sales_Order_Line__c sol = new OrderApi__Sales_Order_Line__c(OrderApi__Sales_Order__c=so.Id,
                                                                              OrderApi__Quantity__c=1,
                                                                              OrderApi__Sale_Price__c=20);
        insert sol;
        
        OrderApi__Receipt__c Receipt = new OrderApi__Receipt__c(OrderApi__Sales_Order__c=so.Id,orderapi__contact__c=con.Id);
        
        insert Receipt;
        
        OrderApi__Receipt_Line__c Receiptline = new OrderApi__Receipt_Line__c(OrderApi__Receipt__c=Receipt.Id,
                                                                              OrderApi__Quantity__c=1,
                                                                              OrderApi__Sale_Price__c=20,OrderApi__Line_Description__c='ABC');
        insert Receiptline;
        
        
        OrderApi__Subscription__c ordSubs = new OrderApi__Subscription__c(OrderApi__Entity__c='Contact',
                                                                          OrderApi__Status__c='Active',
                                                                          OrderApi__Sales_Order_Line__c=sol.Id,OrderApi__Contact__c=con.Id);
        insert ordSubs;
        
    }
    
    @isTest static void validateRecords(){
        
        SentReceipt enr = new SentReceipt();
        
        test.startTest();
        
        OrderApi__Receipt__c os = [Select Id from OrderApi__Receipt__c limit 1];
        enr.OReceiptId = os.Id;
        
        Contact ose = [Select Id from Contact limit 1];
        enr.ReceId = ose.Id;
        
        returnedRecL=enr.returnReceiptLI;
        returnedtotalvalue=enr.returntotalval;
       
        test.stopTest();
        
        
        
    }
}