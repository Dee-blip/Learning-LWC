/*
Author          :  Sumukh SS/Pinkesh 
Description     :  Apex Trigger for SOCC Car RunBooks
Test Class      :  SC_SOCC_RunBooks_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh                              SOCC CAR 2 - RunBooks 
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_SOCC_InstructionTrigger on Instruction__c (before insert, before update, after insert, after update, before delete, after delete) {
     //Set Contact Created and Last Modified BY fields
     if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
          //Fetching Integration profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt 
        SC_SOC_Passphrase_Access__mdt passPhraseAccess = [Select id, Profile_ID_Text__c  from SC_SOC_Passphrase_Access__mdt where DeveloperName =: 'Passphrase_Access_For_Mulesoft' limit 1];
        if(!passPhraseAccess.Profile_ID_Text__c.contains(Userinfo.getProfileId())){
            //Set of lastModified By Ids coz Created BY ID and Last Modified By ID will be same 
            Set<Id> sLastModifiedById = new Set<Id>();
            for(Instruction__c eachRec : Trigger.new){
                sLastModifiedById.add(eachRec.LastModifiedById);
            }

            //Map of user ids to contact ids to set Created and Last Modified By Contact fields
            Map<Id, String> mUserIdAkamContactId = SC_SOCC_EscalationListCtrl.getAkamContactIds(sLastModifiedById);
            //List to be updated
            List<Instruction__c> lUpdatedRec = new List<Instruction__c>();

            for(Instruction__c eachRec : Trigger.new){
                if(mUserIdAkamContactId.get(eachRec.LastModifiedById) != null){
                    Instruction__c updatedRec = new Instruction__c(Id=eachRec.Id);
                    Contact lastModifiedByContact = new Contact(AKAM_Contact_ID__c = mUserIdAkamContactId.get(eachRec.LastModifiedById));
                    if(Trigger.isInsert)
                        updatedRec.Created_By_Contact__r = lastModifiedByContact;
                    updatedRec.Last_Modified_By_Contact__r = lastModifiedByContact;
                    if(!SC_SOCC_EscalationListCtrl.sEscListIdForRecusrion.contains(updatedRec.Id)){
                        SC_SOCC_EscalationListCtrl.sEscListIdForRecusrion.add(updatedRec.Id);
                        lUpdatedRec.add(updatedRec);
                    }
                }
            }

            if(lUpdatedRec.size()>0){
                try{
                    update lUpdatedRec;
                }catch(Exception e){
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        }
     }

}