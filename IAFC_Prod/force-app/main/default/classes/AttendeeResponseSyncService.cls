/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : AttendeeResponseSyncService
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

public without sharing class AttendeeResponseSyncService {

    @future
    public static void syncResponseToAttendee(
       Set<Id> arIDs
    ) {
        Map<String, String> fieldMappings = FieldMappingService.getMappings(
            'Attendee_Response__c',
            'EventApi__Attendee__c'
        );

        Set<String> sourceFields = new Set<String>(fieldMappings.keySet());

        sourceFields.add('Id');
        sourceFields.add('Attendee__c');
        sourceFields.add('Contact__c');
        sourceFields.add('Event_ID_Text__c');

        String fieldList = String.join(new List<String>(sourceFields), ',');

        String query = 'SELECT ' + fieldList +
                    ' FROM Attendee_Response__c WHERE Id IN :arIDs';

        List<Attendee_Response__c> newList = Database.query(query);

        List<Attendee_Response__c> changedResponses = new List<Attendee_Response__c>();
        Set<Id> attendeeIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<String> eventKeys = new Set<String>();

        for (Attendee_Response__c newResp : newList) {
            
            changedResponses.add(newResp);

            if (newResp.Attendee__c != null) {
                attendeeIds.add(newResp.Attendee__c);
            }

            if (newResp.Contact__c != null) {
                contactIds.add(newResp.Contact__c);
            }

            if (newResp.Event_ID_Text__c != null) {
                eventKeys.add(newResp.Event_ID_Text__c);
            }
        }

        if (changedResponses.isEmpty()) {
            return;
        }

        system.debug('attendeeIds == '+attendeeIds );

        Map<Id, EventApi__Attendee__c> attendeeById = new Map<Id, EventApi__Attendee__c>();

        if (!attendeeIds.isEmpty()) {
            for (EventApi__Attendee__c att : [
                SELECT Id,
                       EventApi__Contact__c,
                       EventApi__Attendee_Event__c,
                       EventApi__Attendee_Event__r.Name,
                       Is_Attendee_Response_Update__c
                FROM EventApi__Attendee__c
                WHERE Id IN :attendeeIds
            ]) {
                attendeeById.put(att.Id, att);
            }
        }

        Map<String, EventApi__Attendee__c> attendeeByContactAndEvent = new Map<String, EventApi__Attendee__c>();

        if (!contactIds.isEmpty() && !eventKeys.isEmpty()) {
            for (EventApi__Attendee__c att : [
                SELECT Id,
                       EventApi__Contact__c,
                       EventApi__Attendee_Event__c,
                       EventApi__Attendee_Event__r.Name,
                       Is_Attendee_Response_Update__c
                FROM EventApi__Attendee__c
                WHERE EventApi__Contact__c IN :contactIds
            ]) {
                String eventIdText = att.EventApi__Attendee_Event__r != null
                    ? String.valueOf(att.EventApi__Attendee_Event__r.Name)
                    : null;

                if (att.EventApi__Contact__c != null && eventIdText != null) {
                    attendeeByContactAndEvent.put(buildKey(att.EventApi__Contact__c, eventIdText), att);
                }
            }
        }

        Map<Id, EventApi__Attendee__c> attendeeUpdatesById = new Map<Id, EventApi__Attendee__c>();

        system.debug('changedResponses == '+ changedResponses);

        for (Attendee_Response__c resp : changedResponses) {
            EventApi__Attendee__c targetAttendee;

            if (resp.Attendee__c != null && attendeeById.containsKey(resp.Attendee__c)) {
                targetAttendee = attendeeById.get(resp.Attendee__c);
            } else {
                String key = buildKey(resp.Contact__c, resp.Event_ID_Text__c);
                if (attendeeByContactAndEvent.containsKey(key)) {
                    targetAttendee = attendeeByContactAndEvent.get(key);
                }
            }

            if (targetAttendee == null) {
                continue;
            }

            EventApi__Attendee__c attendeeToUpdate = attendeeUpdatesById.containsKey(targetAttendee.Id)
                ? attendeeUpdatesById.get(targetAttendee.Id)
                : new EventApi__Attendee__c(Id = targetAttendee.Id);

            Boolean hasAnyFieldAssigned = false;

            system.debug('fieldMappings.keySet() == '+ fieldMappings.keySet());
            for (String sourceField : fieldMappings.keySet()) {
                String targetField = fieldMappings.get(sourceField);
                attendeeToUpdate.put(targetField, resp.get(sourceField));
                hasAnyFieldAssigned = true;
            }

            if (hasAnyFieldAssigned) {
                attendeeToUpdate.Is_Attendee_Response_Update__c = true;
                attendeeUpdatesById.put(attendeeToUpdate.Id, attendeeToUpdate);
            }
        }
        system.debug('attendeeUpdatesById.keySet() == '+ attendeeUpdatesById);
        if (!attendeeUpdatesById.isEmpty()) {
            update attendeeUpdatesById.values();
        }
    }

    private static String buildKey(Id contactId, String eventIdText) {
        return String.valueOf(contactId) + '::' + String.valueOf(eventIdText);
    }
}