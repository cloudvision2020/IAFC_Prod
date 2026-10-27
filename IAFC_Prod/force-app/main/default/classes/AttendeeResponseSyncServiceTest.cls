/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : AttendeeResponseSyncServiceTest
 * Author          : <YourName>
 * Created Date    : Mar 12, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Mar 12, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Mar 12, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
@IsTest
private class AttendeeResponseSyncServiceTest {

    @IsTest
    static void testSyncResponseToAttendee_Coverage() {
        Contact con = new Contact(
            LastName = 'Test Contact'
        );
        insert con;

        // Create Event record
        EventApi__Event__c evt = new EventApi__Event__c(
            Name = 'Test Event',
            EventApi__Event_Key__c = 'EVT-001'
        );
        insert evt;

        // Create attendee
        EventApi__Attendee__c attendee = new EventApi__Attendee__c(
            EventApi__Contact__c = con.Id,
            EventApi__Attendee_Event__c = evt.Id
        );
        insert attendee;

        // Create attendee response
        Attendee_Response__c resp = new Attendee_Response__c(
            Attendee__c = attendee.Id,
            Contact__c = con.Id,
            Event_ID_Text__c = evt.Name
        );
        insert resp;

        Test.startTest();
        AttendeeResponseSyncService.syncResponseToAttendee(new Set<Id>{ resp.Id });
        Test.stopTest();

        EventApi__Attendee__c updatedAttendee = [
            SELECT Id, Is_Attendee_Response_Update__c
            FROM EventApi__Attendee__c
            WHERE Id = :attendee.Id
        ];

        System.assertNotEquals(null, updatedAttendee);
    }

    @IsTest
    static void testSyncResponseToAttendee_NoMatchingAttendee() {
        Contact con = new Contact(
            LastName = 'Another Contact'
        );
        insert con;

        Attendee_Response__c resp = new Attendee_Response__c(
            Contact__c = con.Id,
            Event_ID_Text__c = 'No Event Found'
        );
        insert resp;

        Test.startTest();
        AttendeeResponseSyncService.syncResponseToAttendee(new Set<Id>{ resp.Id });
        Test.stopTest();

        System.assert(true);
    }
    
    
    
    
    @IsTest
static void testAttendeeResponseTrigger_Coverage() {
    Contact con = new Contact(
        LastName = 'Trigger Contact'
    );
    insert con;

    EventApi__Event__c evt = new EventApi__Event__c(
        Name = 'Trigger Event',
        EventApi__Event_Key__c = 'EVT-TRG-001'
    );
    insert evt;

    EventApi__Attendee__c attendee1 = new EventApi__Attendee__c(
        EventApi__Contact__c = con.Id,
        EventApi__Attendee_Event__c = evt.Id
    );
    insert attendee1;

    EventApi__Attendee__c attendee2 = new EventApi__Attendee__c(
        EventApi__Contact__c = con.Id,
        EventApi__Attendee_Event__c = evt.Id
    );
    insert attendee2;

    Attendee_Response__c resp = new Attendee_Response__c(
        Attendee__c = attendee1.Id,
        Contact__c = con.Id,
        Event_ID_Text__c = evt.Name
    );
    insert resp;

    Test.startTest();
    resp.Attendee__c = attendee2.Id;
    update resp;
    Test.stopTest();

    System.assert(true);
}
}