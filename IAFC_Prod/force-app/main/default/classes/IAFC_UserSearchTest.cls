@isTest
public class IAFC_UserSearchTest {
	 static testMethod void testSearch(){
         Test.startTest();
         list<Contact> results = IAFC_UserSearch.userLoginLookup('','');
         Test.stopTest();
     }
}