@isTest
public class IAFC_SectionAndDivisionProcessesTest {
    @testSetup 
    static void loadTestData() { 
        List<Contact> contacts = [Select ID from Contact Limit 1];
        string contactid = contacts[0].ID;
        List<PagesApi__Community_Group__c> comgrps = [Select ID from PagesApi__Community_Group__c Limit 1];
        string communityid = comgrps[0].ID;
        List<PagesApi__Community_Group_Member__c> comgrpmbrs = [Select ID from PagesApi__Community_Group_Member__c Limit 1];
        string cgmId = comgrpmbrs[0].ID;
    }


    static void  UpsertCGMByBadgeTest(string contactid, string communityid, date termstart, date termend, string salesorderline){
         Test.startTest();
         IAFC_SectionAndDivisionProcesses.UpsertCGMByBadge(new List<OrderApi__Badge__c>()); 
         Test.stopTest();  
    }

	static PagesApi__Community_Group_Member__c  UpsertCGMTest(string contactid, string communityid, date termstart, date termend, string salesorderline){
         Test.startTest();
         PagesApi__Community_Group_Member__c results = IAFC_SectionAndDivisionProcesses.UpsertCGM(contactid,communityid,date.parse('01/21/2019'),date.parse('01/21/2020'),null);
         system.assert(results.ID != null);
         Test.stopTest(); 
         return results;
    }

    static Community_Group_Member_History__c UpsertCGMHistoryTest(string cgmId, date termstart, date termend, string salesorderline){
         Test.startTest();
         Community_Group_Member_History__c results = IAFC_SectionAndDivisionProcesses.UpsertCGMHistory(cgmId,date.parse('01/21/2019'),date.parse('01/21/2020'),null);
         system.assert(results.ID != null);
         Test.stopTest(); 
         return results;
    }
}