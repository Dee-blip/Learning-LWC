public class DivisionManager {
	
	/*
		Handling division before insert changes. 
		The method is handling insert of division with user that is already used by some existing divisions. 
		If user already used by existing division then that user can not be used and a error message will be added for that 
		division record.
	*/	
	// Below code comented because Now the user lookup removed form devision
	/*
	public static void handleDivisionBeforeInsert(List<Division__c> newDivisions) {
		if(newDivisions == null || newDivisions.isEmpty()) {
			return;
		}
		
		Set<Id> userIdSet = new Set<Id>();
		for(Division__c div : newDivisions) {
			userIdSet.add(div.User__c);
		}
		
		List<Division__c> divisions = [select Id, Name, User__c from Division__c where User__c IN : userIdSet];
		
		Map<String, Division__c> existinDivisionByUserIdMap = new Map<String, Division__c>();
		for(Division__c div : divisions) {
			existinDivisionByUserIdMap.put(div.User__c, div);
		}
		
		if(!existinDivisionByUserIdMap.isEmpty()) {
			for(Division__c div : newDivisions) {
				if(existinDivisionByUserIdMap.containsKey(div.User__c)) {
					Division__c existingDiv = existinDivisionByUserIdMap.get(div.User__c);
					div.addError('Selected division user already used by other division : '+ existingDiv.Name +' [ '+ existingDiv.Id + ' ]. A user can work with only one division at a time.');
				}
			}
		}
	}
	
	/*
		Handling division before update changes. 
		The method is handling update of division with user that is already used by some existing divisions. 
		If user already used by existing division then that user can not be used and a error message will be added for that 
		division record.
	*/
	// Below code comented because Now the user lookup removed form devision
	/*	
	public static void handleDivisionBeforeUpdate(Map<Id, Division__c> oldDivisionsToUpdateMap, Map<Id, Division__c> newDivisionsToUpdateMap) {
		if(newDivisionsToUpdateMap == null || newDivisionsToUpdateMap.isEmpty()) {
			return;
		}
		
		Set<Id> userIdSet = new Set<Id>();
		for(Division__c newDiv : newDivisionsToUpdateMap.values()) {
			if(newDiv != null && (oldDivisionsToUpdateMap == null || oldDivisionsToUpdateMap.get(newDiv.Id).User__c != newDiv.User__c)) {
				userIdSet.add(newDiv.User__c);
			}
			
		}
		
		List<Division__c> divisions = [select Id, Name, User__c from Division__c where User__c IN : userIdSet];
		
		Map<String, Division__c> existinDivisionByUserIdMap = new Map<String, Division__c>();
		for(Division__c div : divisions) {
			existinDivisionByUserIdMap.put(div.User__c, div);
		}
		
		if(!existinDivisionByUserIdMap.isEmpty()) {
			for(Division__c div : newDivisionsToUpdateMap.values()) {
				Division__c existingDiv = existinDivisionByUserIdMap.get(div.User__c);
				if(existingDiv != null && existingDiv.id != div.id) {
					div.addError('Selected division user already used by other division : '+ existingDiv.Name +' [ '+ existingDiv.Id + ' ]. A user can work with only one division at a time.');
				}
			}
		}
	}
*/
}