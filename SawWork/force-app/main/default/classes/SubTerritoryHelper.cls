public without sharing class SubTerritoryHelper {
	private List<String> keyValues;
	private List<String> subTerritories;
	private Map<String,Id> anaplanSTtoSpecialsitUser;
    private Map<String,Id> userTypeToSpecialsitUser;
    private Map<String,String> keyValueToUserType;
	private Map<Id,Id> userIdTospecialistCompTeam;
	private Map<Id,String> userIdToEmail;
	private Map<String,String> keyValueToOpptyFieldName;
	public SubTerritoryHelper (List<String> keyValues, List<String> subTerritories) {
		this.keyValues = keyValues;
		this.subTerritories = subTerritories;
        this.anaplanSTtoSpecialsitUser = new Map<String,Id>();
        this.userTypeToSpecialsitUser = new Map<String,Id>();
        this.keyValueToUserType = new Map<String,String>();
        this.userIdTospecialistCompTeam = new Map<Id,Id>();
        this.userIdToEmail = new Map<Id,String>();
        this.keyValueToOpptyFieldName = new Map<String,String>();
		this.init(this.keyValues,this.subTerritories);
	}

	public void init (List<String> keyValues, List<String> subTerritories) {
		List<Specialist_Territory_Mapping__c> specialistUserQueryResults = new List<Specialist_Territory_Mapping__c>();
        List<Id> specialsitUserIds = new List<Id>();
        List<Specialist_Comp_Team__c> specialistCompTeamUsers = new List<Specialist_Comp_Team__c>();
        List<String> userTypes = new List<String>();
        List<String> specialsitProductTypes = new List<String>();
        Map <String, Object> jsonObject = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('PrimaryCampaignDivisionMap'));

        for (String keyValue: keyValues) {
            if (jsonObject.containsKey(keyValue)) {
                Object jsonValueForKey = jsonObject.get(keyValue);
                Map <String, Object> innerJsonObjectForKey = (Map <String, Object>)jsonValueForKey;
                if (innerJsonObjectForKey.containsKey('userType')){
                    userTypes.add(String.valueOf(innerJsonObjectForKey.get('userType')));
                    keyValueToUserType.put(keyValue,String.valueOf(innerJsonObjectForKey.get('userType')));
                }
                if (innerJsonObjectForKey.containsKey('Type'))
                    specialsitProductTypes.add(String.valueOf(innerJsonObjectForKey.get('Type')));
                this.keyValueToOpptyFieldName.put(keyValue,String.valueOf(innerJsonObjectForKey.get('OpportunityFieldName')));
            }
        }
        
        if (subTerritories.size() > 0) {
            specialistUserQueryResults = [select  Sub_Territory_Name__c,Specialist_User__r.Email,User_Type__c  from Specialist_Territory_Mapping__c where (Sub_Territory_Name__c in :subTerritories AND User_Type__c in : userTypes) AND Specialist_User__r.IsActive = true];
            
            for (Specialist_Territory_Mapping__c specialsitUserResult: specialistUserQueryResults) {
                specialsitUserIds.add(specialsitUserResult.Specialist_User__c);
                this.userIdToEmail.put(specialsitUserResult.Specialist_User__c,specialsitUserResult.Specialist_User__r.Email);
                this.anaplanSTtoSpecialsitUser.put(specialsitUserResult.Sub_Territory_Name__c,specialsitUserResult.Specialist_User__c);
                this.userTypeToSpecialsitUser.put(specialsitUserResult.User_Type__c,specialsitUserResult.Specialist_User__c);
            }
        }

        if (specialsitUserIds.size() > 0) {
            specialistCompTeamUsers = [select Id,Product_Specialist__c from Specialist_Comp_Team__c where (Product_Specialist__c in :specialsitUserIds AND Type__c in : specialsitProductTypes)];
            for (Specialist_Comp_Team__c compTeam: specialistCompTeamUsers) {
                this.userIdTospecialistCompTeam.put(compTeam.Product_Specialist__c,compTeam.Id);
            }       
        }
	}

	public Map<String,Id> getAnaplanSTtoSpecialsitUser () {
		return this.anaplanSTtoSpecialsitUser;
	}

	public Map<Id,Id> getUserIdTospecialistCompTeam () {
		return this.userIdTospecialistCompTeam;
	}

	public Map<Id,String> getUserIdToEmail () {
		return this.userIdToEmail;
	}
	public Map<String,String> getKeyValueToOpptyFieldName () {
		return this.keyValueToOpptyFieldName;
	}
     public Map<String,Id> getUserTypeToSpecialsitUser() {
        return this.userTypeToSpecialsitUser;
    }
    public Map<String,String> getKeyValueToUserType(){
        return this.keyValueToUserType;
    }
}