@IsTest
private class IAFCMembershipCardControllerTest {

    @TestSetup
    static void setupTestData() {

        Account testAccount = new Account(
            Name = 'Test IAFC Account'
        );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            AccountId = testAccount.Id,
            Email = 'john.doe@iafc.org',
            Phone = '555-1234',
         
            Active_Sections__c = 'Fire Service Section; Emergency Medical Services Section; Volunteer & Combination Officers Section',
           
            Membership_Expiration__c = Date.today().addYears(1)
        );
        insert testContact;

        Contact testContact2 = new Contact(
            FirstName = 'Jane',
            LastName = 'Smith',
            AccountId = testAccount.Id,
            Email = 'jane.smith@iafc.org',
            Phone = '555-5678',
            Active_Sections__c = 'Metro Chiefs Section, Training Section',
            Membership_Expiration__c = Date.today().addMonths(-6)
        );
        insert testContact2;

        Contact testContact3 = new Contact(
            FirstName = 'Bob',
            LastName = 'Johnson',
            AccountId = testAccount.Id,
            Email = 'bob.johnson@iafc.org',
            Active_Sections__c = 'Wildland Fire Policy Committee',
            Membership_Expiration__c = null
        );
        insert testContact3;

        Contact testContact4 = new Contact(
            FirstName = 'Mary',
            LastName = 'Williams',
            AccountId = testAccount.Id,
            Email = 'mary.williams@iafc.org',
            Active_Sections__c = null,
            Membership_Expiration__c = Date.today().addDays(30)
        );
        insert testContact4;

        OrderApi__Subscription__c activeSub = new OrderApi__Subscription__c(
            
            OrderApi__Contact__c = testContact.Id,
            OrderApi__Activated_Date__c = Date.today().addYears(-1),
            OrderApi__Current_Term_Start_Date__c = Date.today().addMonths(-6),
            OrderApi__Current_Term_End_Date__c = Date.today().addMonths(6)
        );
        insert activeSub;

        OrderApi__Subscription__c expiredSub = new OrderApi__Subscription__c(
            
            OrderApi__Contact__c = testContact2.Id,
            OrderApi__Activated_Date__c = Date.today().addYears(-2),
            OrderApi__Current_Term_Start_Date__c = Date.today().addYears(-1),
            OrderApi__Current_Term_End_Date__c = Date.today().addMonths(-3)
        );
        insert expiredSub;
    }

    @IsTest
    static void testConstructor_WithActiveSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'johndoe');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
        }
        Test.stopTest();
    }

    @IsTest
    static void testConstructor_WithExpiredSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'jane.smith@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'janesmith');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
        }
        Test.stopTest();
    }

    @IsTest
    static void testConstructor_NoSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'bob.johnson@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'bobjohnson');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
        }
        Test.stopTest();
    }

    @IsTest
    static void testConstructor_NoSections() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'mary.williams@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'marywilliams');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetterMethods_ActiveSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'johndoetest');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getMembershipExpiration();
            controller.getFormattedActivatedDate();
            controller.getFormattedExpiredDate();
            controller.getFormattedPaidThroughDate();
            controller.getMemberSince();
            controller.getMemberName();
            controller.getFormattedDivision();
            controller.getFormattedLegacyId();
            controller.getStatusBadgeClass();
            controller.getHasActiveSections();
            controller.getIsActive();
            controller.getIsExpired();
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetterMethods_ExpiredSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'jane.smith@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'janesmithtest');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getMembershipExpiration();
            controller.getStatusBadgeClass();
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetterMethods_NoSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'bob.johnson@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'bobjohnsontest');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getMembershipExpiration();
            controller.getStatusBadgeClass();
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetterMethods_NullValues() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'mary.williams@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'marywilliamstest');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getFormattedDivision();
            controller.getFormattedLegacyId();
            controller.getHasActiveSections();
        }
        Test.stopTest();
    }

    @IsTest
    static void testActiveSectionsParsing_Semicolons() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'johndoesections');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getHasActiveSections();
        }
        Test.stopTest();
    }

    @IsTest
    static void testActiveSectionsParsing_Commas() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'jane.smith@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'janesmithsections');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getHasActiveSections();
        }
        Test.stopTest();
    }

    @IsTest
    static void testActiveSectionsParsing_SingleValue() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'bob.johnson@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'bobjohnsonsections');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getHasActiveSections();
        }
        Test.stopTest();
    }

    @IsTest
    static void testMembershipStatusCalculation_ActiveWithSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'johndoestatus');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getStatusBadgeClass();
        }
        Test.stopTest();
    }

    @IsTest
    static void testMembershipStatusCalculation_ActiveWithoutSubscription() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'mary.williams@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'marywilliamsstatus');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getStatusBadgeClass();
        }
        Test.stopTest();
    }

    @IsTest
    static void testMembershipStatusCalculation_Expired() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'jane.smith@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'janesmithstatus');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getStatusBadgeClass();
        }
        Test.stopTest();
    }

    @IsTest
    static void testMembershipStatusCalculation_Unknown() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'bob.johnson@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'bobjohnsonstatus');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getStatusBadgeClass();
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetMemberName_FirstLastName() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@iafc.org' LIMIT 1];
        User testUser = createCommunityUser(testContact.Id, 'johndoename');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
            controller.getMemberName();
        }
        Test.stopTest();
    }

    @IsTest
    static void testErrorHandling_UserWithoutContact() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE UserType = 'Standard' LIMIT 1];

        String uniq = String.valueOf(System.currentTimeMillis());
        User userNoContact = new User(
            FirstName = 'No',
            LastName = 'Contact',
            Email = 'nocontact' + uniq + '@test.com',
            Username = 'nocontact' + uniq + '@test.com',
            Alias = ('noctc' + uniq).left(8),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert userNoContact;

        Test.startTest();
        System.runAs(userNoContact) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
        }
        Test.stopTest();
    }

    @IsTest
    static void testMultipleSubscriptions() {
        Contact testContact = [SELECT Id FROM Contact WHERE Email = 'john.doe@iafc.org' LIMIT 1];

        OrderApi__Subscription__c olderSub = new OrderApi__Subscription__c(
            
            OrderApi__Contact__c = testContact.Id,
            OrderApi__Activated_Date__c = Date.today().addYears(-3),
            OrderApi__Current_Term_Start_Date__c = Date.today().addYears(-2),
            OrderApi__Current_Term_End_Date__c = Date.today().addYears(-1)
        );
        insert olderSub;

        User testUser = createCommunityUser(testContact.Id, 'johndoemultisub');

        Test.startTest();
        System.runAs(testUser) {
            IAFCMembershipCardController controller = new IAFCMembershipCardController();
        }
        Test.stopTest();
    }

    private static User createCommunityUser(Id contactId, String uniqueAlias) {
        // IMPORTANT:
        // Do NOT fall back to Standard User if your org enforces "only portal users can be associated to a contact"
        // Replace 'Customer Community User' with your actual Experience profile name if needed.

        Profile communityProfile;
        List<Profile> profiles = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Fonteva Customer Community Login User'
            LIMIT 1
        ];

        if (profiles.isEmpty()) {
            communityProfile = [SELECT Id FROM Profile WHERE UserType != 'Standard' LIMIT 1];
        } else {
            communityProfile = profiles[0];
        }

        String uniq = String.valueOf(System.currentTimeMillis());

        User communityUser = new User(
            FirstName = 'Test',
            LastName  = 'User ' + uniqueAlias,
            Email     = uniqueAlias + '+' + uniq + '@test.iafc.org',
            Username  = uniqueAlias + '+' + uniq + '@test.iafc.org',
            Alias     = uniqueAlias.left(8),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey   = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = communityProfile.Id,
            ContactId = contactId,
            CommunityNickname = (uniqueAlias + uniq).left(40)
        );
        insert communityUser;
        return communityUser;
    }
}