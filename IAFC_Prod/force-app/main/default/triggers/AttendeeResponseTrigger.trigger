trigger AttendeeResponseTrigger on Attendee_Response__c(after update) {
	

	if(Label.AttendeeResponseTrigger == 'TRUE'){
		Set<Id> attendeeIds = new Set<Id>();
		for(Attendee_Response__c ar : Trigger.New){
			Attendee_Response__c oldResp = Trigger.oldMap.get(ar.Id);
			if (ar.Attendee__c != oldResp.Attendee__c && ar.Attendee__c != null) {
				attendeeIds.add(ar.Id);
			}
		}

		if(attendeeIds.size() > 0){
			AttendeeResponseSyncService.syncResponseToAttendee(attendeeIds);   
		}
	}
	
	
}