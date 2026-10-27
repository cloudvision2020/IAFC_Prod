@RestResource(urlMapping='/AccountSearchBasic')
global class IAFC_AccountSearchBasic {
    
    @HttpGet
    global static list<Account> searchAccounts(){
//        RestContext.response.addHeader('Content-Type', 'application/json');
        String searchHint = RestContext.request.params.get('term');
        string searchHintF = '%' + searchHint + '%';
        list<Account> accountList = [select ID, Name, BillingStateCode, BillingCity, BillingCountryCode from Account where Name like :searchHintF order by Name limit 50 ];
        
        System.debug(accountList);
        return accountList;
    }
}