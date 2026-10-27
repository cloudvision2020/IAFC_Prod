@RestResource(urlMapping='/ContactSearchBasic')
global class IAFC_ContactSearchBasic {
    @HttpGet
    global static list<Contact> searchContacts(){
        String firstName = RestContext.request.params.get('firstName');
        String lastName = RestContext.request.params.get('lastName');
        String accountId = RestContext.request.params.get('orgId');
        list<Contact> conList = [SELECT Id, FirstName, LastName, AccountId, Account.Name,Email FROM Contact WHERE FirstName=:firstName 
                                     AND LastName=:lastName AND AccountId=:accountId LIMIT 500];
        
        System.debug(conList);
        return conList;
    }
}