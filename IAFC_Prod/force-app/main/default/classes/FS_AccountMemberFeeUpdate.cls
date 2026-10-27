/***********************************************************************************************
 This class for updating Account New Member Fee on Account object.

************************************************************************************************/

public class FS_AccountMemberFeeUpdate {
    //Insert method
    public static void afterInsertingAccount(List<OrderApi__Subscription__c> subscriptions){
            set<id> ids=new set<id>();
                for(OrderApi__Subscription__c sub: subscriptions){
                        OrderApi__Subscription__c subscrip=[select OrderApi__Account__c from OrderApi__Subscription__c
                                                      where id=:sub.id and  OrderApi__Account__c!=null limit 1];
                            ids.add(subscrip.OrderApi__Account__c);
                        }
                Map<id,Account> accountRecords=new Map<id,Account>([select id,FS_Account_New_Member_Fee__c,
                             (select id,OrderApi__Is_Active__c,OrderApi__Item__r.name,OrderApi__Account__c 
                             from OrderApi__Subscriptions__r)from Account where id in:ids]);
                     for(Account a:accountRecords.values()){
                             if(a.OrderApi__Subscriptions__r.size()>0){
                                 for(OrderApi__Subscription__c sub:a.OrderApi__Subscriptions__r){ 
                                     if(sub.OrderApi__Is_Active__c==true && sub.OrderApi__Item__r.name==System.Label.Membership){
                                        a.FS_Account_New_Member_Fee__c=false;
                                     }else{
                                         if(sub.OrderApi__Item__r.name!=System.Label.Membership)
                                             a.FS_Account_New_Member_Fee__c=true; 
                                     }
                                 }
                             }
                         } 
                         update accountRecords.values();                  
                     }
                     
     //Update method       
     public static void afterUpdatingAccount(List<OrderApi__Subscription__c> subscriptions,Map<id,OrderApi__Subscription__c> oldmap){
         set<id> ids=new set<id>();
            Map<id,OrderApi__Subscription__c> subMap=new Map<id,OrderApi__Subscription__c>([select id,OrderApi__Item__r.name,Subscription_Item_Name__c from 
                                                                                            OrderApi__Subscription__c where id in:oldmap.keyset()]);
            for(OrderApi__Subscription__c sub: subscriptions){
                    OrderApi__Subscription__c subscrip=[select OrderApi__Account__c from OrderApi__Subscription__c
                                                           where id=:sub.id and OrderApi__Account__c!=null limit 1];
                    ids.add(subscrip.OrderApi__Account__c); 
                }
                
             Map<id,Account> accountRecords=new Map<id,Account>([select id,FS_Account_New_Member_Fee__c,
                         (select id,OrderApi__Is_Active__c,OrderApi__Item__r.name,OrderApi__Account__c,OrderApi__Item__c,Subscription_Item_Name__c
                          from OrderApi__Subscriptions__r)from Account where id in:ids]);
                 for(Account a:accountRecords.values()){
                     if(a.OrderApi__Subscriptions__r.size()>0){
                         for(OrderApi__Subscription__c sub :a.OrderApi__Subscriptions__r){                      
                             if(sub.Subscription_Item_Name__c==System.Label.Membership){
                                 if(sub.OrderApi__Is_Active__c==true){
                                     a.FS_Account_New_Member_Fee__c=false;
                                 }else{
                                     if(sub.OrderApi__Is_Active__c==false){ 
                                        a.FS_Account_New_Member_Fee__c=true;  
                                     }
                                 }
                             }else{
                                 if(sub.OrderApi__Item__r.name!=System.Label.Membership){
                                    a.FS_Account_New_Member_Fee__c=true;                              
                                 }
                             }
                         }
                     }
                 }   
                 update    accountRecords.values();           
             }     
          }