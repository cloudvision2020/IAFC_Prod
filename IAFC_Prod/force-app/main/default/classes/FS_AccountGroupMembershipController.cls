/**
 * Created by Jason Cookman on 3/21/19.
 */

public with sharing class FS_AccountGroupMembershipController {

    public List<OrderApi__Renewal__c> getRelevantContactRecords() {

        String accountId = ApexPages.currentPage().getParameters().get('id');
        List<OrderApi__Renewal__c> relevantTerms = new List<OrderApi__Renewal__c>();

        if(!String.isBlank(accountId)) {
            relevantTerms = [
                    SELECT Id, OrderApi__Subscription__r.OrderApi__Contact__r.Name,
                            OrderApi__Subscription__r.OrderApi__Contact__r.Title,
                            OrderApi__Subscription__r.OrderApi__Contact__r.Email,
                            OrderApi__Subscription__r.OrderApi__Contact__r.Membership_Type__c,
                            OrderApi__Subscription__r.OrderApi__Contact__r.Division__c,
                            OrderApi__Subscription__r.OrderApi__Contact__r.Sections__c,
                            OrderApi__Term_Start_Date__c, OrderApi__Term_End_Date__c
                    FROM OrderApi__Renewal__c
                    WHERE OrderApi__Subscription__r.OrderApi__Contact__r.AccountId = :accountId
                    AND FS_Purchased_via_Group_Membership__c = TRUE
                    AND OrderApi__Is_Active__c = TRUE
            ];
        }

        return relevantTerms;
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
        String footerLabel = Label.FS_AccountGroupMembershipFooter;

        footerLabel = footerLabel.replace('{!DivisionName}', getDivisionName()); 
        return footerLabel;
    }


    private String divisionName;
    private String getDivisionName(){
        String accountId = ApexPages.currentPage().getParameters().get('id');

//        divisionName='';

        if(divisionName == null) {
            Account acc = getAccount(accountId);

            if (acc == null || acc.FS_Account_Division__c == null) {
                divisionName = '';
            } else {
                divisionName = acc.FS_Account_Division__c;
            }
        }

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

        return company;

    } 

}