@isTest
public class IAFC_MemberInfoDetailsTest {
	 static testMethod void testSearch(){
         Test.startTest();
         Contact testContact = new Contact();
         testContact.LastName = 'Test';
         insert testContact;
         //System.debug(testContact.Id);
         Contact currentContact = IAFC_MemberInfoDetails.getUserDetails(testContact.id);
         Test.stopTest();
     }
}