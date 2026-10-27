/**
 * Created by Jason Cookman on 3/21/19.
 */

public with sharing class FS_AllAccountContactsController {
    public class ContactWrapper {
        public Contact relevantContact {get;set;}
        public OrderApi__Renewal__c relevantTerm {get;set;}

        public ContactWrapper(Contact relevantContact, OrderApi__Renewal__c relevantTerm) {
            this.relevantContact = relevantContact;
            this.relevantTerm = relevantTerm;
        }
    }


    public List<ContactWrapper> getContactsOnAccount() {
        String accountId = ApexPages.currentPage().getParameters().get('id');
        List<ContactWrapper> wrappersToReturn = new List<FS_AllAccountContactsController.ContactWrapper>();


        if(!String.isBlank(accountId)) {
            Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name, Title, Division__c,
                                Sections__c, Email, Membership_Type__c
                                        FROM Contact WHERE AccountId = :accountId]);
            Map<Id, OrderApi__Renewal__c> contactIdToTerm = new Map<Id, OrderApi__Renewal__c>();

            for(OrderApi__Renewal__c currTerm : [SELECT Id, OrderApi__Subscription__r.OrderApi__Contact__c,
                    FS_Purchased_via_Group_Membership__c, OrderApi__Term_Start_Date__c,
                    OrderApi__Term_End_Date__c,OrderApi__Subscription__r.OrderApi__Paid_Through_Date__c
            FROM OrderApi__Renewal__c
            WHERE OrderApi__Subscription__r.OrderApi__Contact__c IN :contactMap.keySet()
            AND OrderApi__Is_Active__c = TRUE]) {
                contactIdToTerm.put(currTerm.OrderApi__Subscription__r.OrderApi__Contact__c, currTerm);
            }

            for(Contact currContact : contactMap.values()) {
                OrderApi__Renewal__c toAdd = new OrderApi__Renewal__c();
                if(contactIdToTerm.get(currContact.Id) != null) {
                    toAdd = contactIdToTerm.get(currContact.Id);
                }

                wrappersToReturn.add(new ContactWrapper(currContact, toAdd));
            }
        }

        return wrappersToReturn;
    }


    public String getAccountName() {
        String accountName = '';
        String accountId = ApexPages.currentPage().getParameters().get('id');

        if (!String.isBlank(accountId)) {
            Account relevantAccount = getAccount(accountId);
            accountName = relevantAccount.Name;
        }

        return accountName;
    }

    public String getFooterLabel() {

        String footerLabel = Label.FS_AllAccountContactsFooter;
        
        footerLabel = footerLabel.replace('{!DivisionName}', getDivisionName());
        return footerLabel;
    }


    private String divisionName;
    private String getDivisionName(){
        String accountId = ApexPages.currentPage().getParameters().get('id');

        if(divisionName == null) {
            Account acc = getAccount(accountId);

            if (acc == null || acc.FS_Account_Division__c == null) {
                divisionName = '';
            } else {
                divisionName = acc.FS_Account_Division__c;
            }
        }
System.debug('division::'+divisionName);
        return divisionName;
    }

    Account company;
    private Account getAccount(String accountId) {
        if(company == null) {
            List<Account> relevantAccount = [SELECT Name, FS_Account_Division__c FROM Account WHERE Id = :accountId];

            if(relevantAccount.size() > 0) {
                company = relevantAccount[0];
            }
        }
        System.debug('account:'+company.Name + ':::::'+company.FS_Account_Division__c);

        return company;  

    }
}