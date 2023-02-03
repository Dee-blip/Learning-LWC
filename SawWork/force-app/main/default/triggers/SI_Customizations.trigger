/*=====================================================================================================+

|  HISTORY  |   Purpose : All service Incident Related Customization                                                                         

|  DATE             DEVELOPER       CR          DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                
   15-OCT-2014    Himanshu      2797149         1. Send notification when status changed with related JIRA tickets/Bugzilla CRs details
|  22-Oct-2018    Pinkesh       ESESP-630       2. Disable email notifications if any change is made on customer advisory section or status of the incident record
   07-April-2020  Sheena        ESESP-1767      3. Added recursive check for email notifications on Status change
|                                       
                                                       
+=====================================================================================================*/

trigger SI_Customizations on BMCServiceDesk__Incident__c (After Update,Before Update)
{
    // Fetching Service Incident record Type
    String recordTypeId_SI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();

    // List to store all Phase Change Service Incidents(Status = IMPACT MITIGATED/RESOLVED/CLOSED)
    List<BMCServiceDesk__Incident__c> allPhaseChangeSI = new List<BMCServiceDesk__Incident__c>();

    // List to Store all SI for which Case Owner will be Updated
    //List<BMCServiceDesk__Incident__c> CaseOwnerUpdateSI = new List<BMCServiceDesk__Incident__c>();

    // Loop to iterate all Incidents
    for(integer recVar = 0; recVar < Trigger.New.size(); recVar++){

        if(trigger.isBefore){
            if( Trigger.New[recVar].recordTypeId == recordTypeId_SI){
                // Calling SI_TriggerClass for calculating Account Tier on Incident Page.
                SI_TriggerClass SI_Acus = new SI_TriggerClass();

                SI_Acus.getAccountTierCount(Trigger.New);
            }
        }

        // Commenting as part of ESESP-630: Disable email notifications if any change is made on customer advisory section or status of the incident record
        if(trigger.isAfter){
            // Condition for Checking SI RecordType
            if( Trigger.New[recVar].recordTypeId == recordTypeId_SI){

                // Calculation#1 - Condition for Checking Status change
                if(Trigger.New[recVar].BMCServiceDesk__FKStatus__c <> Trigger.Old[recVar].BMCServiceDesk__FKStatus__c &&
                        SI_Status__c.getInstance('SIStatus').Status__c.contains(Trigger.New[recVar].BMCServiceDesk__Status_ID__c )){

                    // Adding Status Change SI to PahseChange List and CaseOwnerUpdate List
                    allPhaseChangeSI.add(Trigger.New[recVar]);
                    //CaseOwnerUpdateSI.add(Trigger.New[recVar]);
                }

                // Calculation#2 - Condition for checking Customer Advisory Change
                //else if(Trigger.New[recVar].Customer_Advisory__c <> Trigger.Old[recVar].Customer_Advisory__c){
                //
                //    CaseOwnerUpdateSI.add(Trigger.New[recVar]);
                //}
            }
        }
    }

     //Commenting as part of ESESP-630: Disable email notifications if any change is made on customer advisory section or status of the incident record
    // By Akhila - Calling SendUpdatetoCaseOwner Method
   // if(CaseOwnerUpdateSI.size()>0)
   //     SI_TriggerClass.SendUpdatetoCaseOwner(CaseOwnerUpdateSI,Trigger.OldMap);

    // Call to sendEmailStatusChange method
    // Changes for ESESP-1767: Added recursive check for email notifications on Status change
    if(allPhaseChangeSI.size() > 0 && SI_TriggerClass.statusRecursiveCheck){

        // Calling allPhaseChangeSI Method for sending Email
        SI_TriggerClass SI_Acus = new SI_TriggerClass();
        SI_Acus.sendEmailStatusChange(allPhaseChangeSI);
    }
    

}