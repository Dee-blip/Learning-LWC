global class GSM_DisabledChimeAccessBatchClass implements Schedulable{

    global void execute(SchedulableContext ctx) 
    {
        validateAndDisableChimeContactAccess();
    }

    public void validateAndDisableChimeContactAccess(){

        List<Contact> conList = new  List<Contact>();
        List<Id> conIdList = new  List<Id>();
        List<CHIME_Contact__c> chimeContactListToUpdate = new List<CHIME_Contact__c>();

        Integer timeIntervalInHoursInteger = -720;
        String timeIntervalInHours = GsmUtilClass.getGSMSettingValue('Time_Interval_For_Chime_Access_Removal'); //720 hrs i.e 30 days
        if(timeIntervalInHours != null)
        {
            timeIntervalInHoursInteger = -1 * Integer.valueof(timeIntervalInHours);
        }

        for(Contact con : [Select id, Remove_Chime_Access_TimeStamp__c from Contact where Remove_Chime_Access_TimeStamp__c != null]){
            if(datetime.now().addHours(timeIntervalInHoursInteger).isSameDay(con.Remove_Chime_Access_TimeStamp__c)){
                con.Has_Chime_Access__c = false;
                conIdList.add(con.id);
                conList.add(con);
            }
        }

        if(conList.size() > 0){
            GsmUtilClass.doDatabaseUpdate(conList,'GSM_DisabledChimeAccessBatchClass','validateAndDisableChimeContactAccess-ContactUpdate');
            ChimeContactClass.removeChimePermission(conIdList);
            for(CHIME_Contact__c chimeContact : [Select id, Chime_access__c from CHIME_Contact__c where Contact__c IN :conList and Chime_access__c = true]){
                chimeContact.Chime_access__c = false;
                chimeContactListToUpdate.add(chimeContact);
            }
        }

        if(chimeContactListToUpdate.size() > 0){
            ByPassAndLimitUtils.disable('ChimeContact');
            GsmUtilClass.doDatabaseUpdate(chimeContactListToUpdate,'GSM_DisabledChimeAccessBatchClass','validateAndDisableChimeContactAccess-ChimeContactUpdate');
        }
    }
}