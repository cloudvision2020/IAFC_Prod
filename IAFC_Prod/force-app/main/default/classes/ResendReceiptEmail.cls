public class ResendReceiptEmail {
    @auraEnabled
    public static void ResendEmail(string ReceiptId,string Email){
        OrderApi__Receipt__c r = [select id,OrderApi__Contact__c from OrderApi__Receipt__c where id=:ReceiptId];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(r.OrderApi__Contact__c); 
       
  // message.setSenderDisplayName(‘Company Support’); 
   //message.setReplyTo(‘no-reply@company.com’);
    message.setUseSignature(false); 
    message.setBccSender(false); 
    message.setSaveAsActivity(false); 
        EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'Receipt Template'];
        message.setTemplateID(emailTemplate.Id); 
        message.setWhatId(r.id); //This is important for the merge fields in template to work
        message.toAddresses = new String[] {Email};
            if(!test.isRunningTest()){
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            }
     
}
}