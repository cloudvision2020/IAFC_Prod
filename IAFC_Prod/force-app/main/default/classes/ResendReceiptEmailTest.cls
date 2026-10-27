@isTest
public class ResendReceiptEmailTest {
   // public static List<OrderApi__Receipt__c> Rec;
    
    @istest
    public static void testrecords(){
        
        Contact con = new Contact(FirstName='test',
                                  LastName='Con',email='test@gmail.com');
        
        insert con;
        
       
        OrderApi__Receipt__c Receipt = new OrderApi__Receipt__c(orderapi__contact__c=con.Id);
        
        insert Receipt;
        
        
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Receipt Template'];
        ResendReceiptEmail.ResendEmail(Receipt.id, con.email);
        
     }
    
   /** @isTest static void validateRecords(){
        
        Test.startTest();
        try
        {
            Contact Cont = [select id,email from contact where email !=null limit 1];
            OrderApi__Receipt__c os = [Select Id,orderapi__contact__c from OrderApi__Receipt__c where orderapi__contact__c=:cont.Id];
            ResendReceiptEmail.ResendEmail(os.id, cont.email);
            
        }
        catch(DMLException e) {
            System.assertEquals(e.getMessage(), e.getMessage());
        }
        
        Test.stopTest();
        
    }**/
    
}