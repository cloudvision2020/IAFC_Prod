@isTest
public class FS_CommunityGroupMemberRoutingRuleTest {
    @TestSetup
    private static void install() {
        Framework.Installer.install();
        PagesApi.PackageScripts.install();
        OrderApi.PackageScripts.install();
        EventApi.PackageScripts.install();

        Framework.RoutingRule[] rules = new List<Framework.RoutingRule>();
        Framework.RoutingRule communityGroupMemberRule = new Framework.RoutingRule();
        communityGroupMemberRule.apexClass = FS_CommunityGroupMemberRoutingRule.class.getName();
        communityGroupMemberRule.namespace = 'PagesApi';
        communityGroupMemberRule.isEnabled = true;
        communityGroupMemberRule.sObjectName = SObjectType.PagesApi__Community_Group_Member__c.getName();
        communityGroupMemberRule.executionOrder = 10;
        rules.add(communityGroupMemberRule);

        Framework.Config.push(rules);
    }

    @isTest static void test() {
        OrderApi__Business_Group__c businessGroup = new OrderApi__Business_Group__c(Name='test');
        insert businessGroup;

        Account acc = new Account(Name='Test');
        insert acc;

        Contact con1 = new Contact(LastName='Test1', AccountId=acc.Id);
        insert con1;

        PagesApi__Community_Group__c communityGroup = new PagesApi__Community_Group__c(Name='test',
                PagesApi__Type__c='Section');
        insert communityGroup;

        PagesApi__Community_Group_Member__c communityGroupMember = new PagesApi__Community_Group_Member__c(
                PagesApi__Contact__c=con1.Id, PagesApi__Is_Active__c=true,
                PagesApi__Status__c='Active', PagesApi__Community_Group__c=communityGroup.Id);
        insert communityGroupMember;

        Test.startTest();
        System.assertEquals('test', [SELECT Sections__c FROM Contact WHERE Id = :con1.Id].Sections__c);

        PagesApi__Community_Group__c communityGroup1 = new PagesApi__Community_Group__c(Name='test1',
                PagesApi__Type__c='Section');
        insert communityGroup1;

        PagesApi__Community_Group_Member__c communityGroupMember1 = new PagesApi__Community_Group_Member__c(
                PagesApi__Contact__c=con1.Id, PagesApi__Is_Active__c=false,
                PagesApi__Status__c='Deactivated', PagesApi__Community_Group__c=communityGroup1.Id);
        insert communityGroupMember1;

        communityGroupMember1.PagesApi__Is_Active__c = true;
        update communityGroupMember1;

        System.assertEquals('test, test1', [SELECT Sections__c FROM Contact WHERE Id = :con1.Id].Sections__c);

        delete communityGroupMember;
        System.assertEquals('test1', [SELECT Sections__c FROM Contact WHERE Id = :con1.Id].Sections__c);

        Test.stopTest();
    }
}