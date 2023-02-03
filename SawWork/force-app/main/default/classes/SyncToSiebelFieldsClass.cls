/***
    SyncToSiebelFieldsClass
    @author : Kartikay Nagal <knagal@akamai.com>
    @Description : This class implements the following logic for different triggers :
                    - Generalize the logic to update the Sync_To_Siebel__c on object having this field.
                      The class will take the list of sObject and update the Sync_To_Siebel__c field.
                      The class can be called from any object trigger that have the Sync_To_Siebel__c field and 
                      update the Sync_To_Siebel__c on Insert and Update.
   
    @History
    --Developer           --Date            --Change
    Kartikay Nagal          27/05/2015        Created the class.
***/
public class SyncToSiebelFieldsClass {
    private static Boolean isInsertFlag = false;
    public static void populateSyncToSiebelField(String sObjType)
    {
        SObject newObj,oldObj=null;
        Set<string> fieldsForSiebel = PlatformUtils.getFieldsForSiebel(sObjType, UserInfo.getProfileId());
        if(Trigger.isInsert)
        {
            for(SObject obj: Trigger.new)
            {
                obj.put('Sync_To_Siebel__c',true);
            }
            //isInsertFlag = true;
        }
        else if(!isInsertFlag && Trigger.isUpdate)
        {
            for(Id sobjId: Trigger.newMap.keySet())
            {
                newObj=Trigger.newMap.get(sobjId);

                if(Trigger.oldMap!=null && !Trigger.oldMap.isEmpty())
                    oldObj= Trigger.oldMap.get(sobjId);



                if(fieldsForSiebel.size()>0)
                {
                    if(Util.hasChanges(fieldsForSiebel,oldObj,newObj))
                    {
                        System.debug('hasChanges in field , will update flag');
                        newObj.put('Sync_To_Siebel__c',true);
                    }   
                }

            }
        }

    }
}