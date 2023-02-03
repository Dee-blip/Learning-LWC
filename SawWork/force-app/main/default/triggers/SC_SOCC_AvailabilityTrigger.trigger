/*

History :

Name           Date       Jira        Comments
--------------------------------------------------------------------------------------------------------------------------
Pinkesh/Sumukh                        Initial Development
Tejaswini          04/Aug/2021    ESESP-5132        Updating the Timezone offset of the Availability record while inserting
*/
trigger SC_SOCC_AvailabilityTrigger on SC_SOCC_Availability__c (before insert) {
    
    /*if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
          System.debug('calling before trigger');
          Set<Id> sConId = new Set<Id>();
          for(SC_SOCC_Availability__c eachRec : Trigger.new)
               sConId.add(eachRec.Contact__c);
          
          //Set of Parent Account Ids to check if the User SSP and has access
          Set<Id> sAccId = new Set<Id>();
          for(Contact eachCon : [SELECT Id, AccountId FROM Contact WHERE Id IN :sConId])
               sAccId.add(eachCon.AccountId);
          
          //Check if User is SSP and has access
          Boolean hasAccess = SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(sAccId);
          if(!hasAccess){
               //Trigger.new[0].addError('Only SSPs are allowed to create/edit the record.');
          }
                
          //Update Timezone offset in the Availability record
          /*System.debug('Update Timezone offset in the Availability record');
          for(SC_SOCC_Availability__c eachRec : Trigger.new)
          {
             if(eachRec.TZ_Name__c !=null)
             {
                 String tzName = eachRec.TZ_Name__c;
                 System.debug('Timezone name'+tzName);
                 Timezone tz = Timezone.getTimeZone(tzName);
               System.debug('Timezone tz'+tz);
                 DateTime dt = DateTime.now();
                 Long ms = tz.getOffset(dt);
                 System.debug('Offset miliseconds: ' + ms);
                 Integer curTzOffset = (ms/3600000).intValue();
                 System.debug('curTzOffset curTzOffset'+curTzOffset);
                 
                 eachRec.Timezone_Name__c = tzName;
                 eachRec.Timezone_offset__c = curTzOffset;
                 System.debug(eachRec);
             }
          }        
     }*/

     /*Set Contact Created and Last Modified BY fields
     if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
          //Fetching Integration profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt 
        SC_SOC_Passphrase_Access__mdt passPhraseAccess = [Select id, Profile_ID_Text__c  from SC_SOC_Passphrase_Access__mdt where DeveloperName =: 'Passphrase_Access_For_Mulesoft' limit 1];
        if(!passPhraseAccess.Profile_ID_Text__c.contains(Userinfo.getProfileId())){
            //Set of lastModified By Ids coz Created BY ID and Last Modified By ID will be same 
            Set<Id> sLastModifiedById = new Set<Id>();
            for(SC_SOCC_Availability__c eachRec : Trigger.new){
                sLastModifiedById.add(eachRec.LastModifiedById);
            }

            //Map of user ids to contact ids to set Created and Last Modified By Contact fields
            Map<Id, String> mUserIdAkamContactId = SC_SOCC_EscalationListCtrl.getAkamContactIds(sLastModifiedById);
            //List to be updated
            List<SC_SOCC_Availability__c> lUpdatedRec = new List<SC_SOCC_Availability__c>();

            for(SC_SOCC_Availability__c eachRec : Trigger.new){
                if(mUserIdAkamContactId.get(eachRec.LastModifiedById) != null){
                    SC_SOCC_Availability__c updatedRec = new SC_SOCC_Availability__c(Id=eachRec.Id);
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
                    //update lUpdatedRec;
                }catch(Exception e){
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        }
     }*/
    
    //Changes for ESESP-5132
    //Update Timezone offset and Timezone Name in the Availability record
    /*if(Trigger.isBefore && (Trigger.isInsert)){
        System.debug('Update Timezone offset in the Availability record');
        DateTime dt = DateTime.now();
        for(SC_SOCC_Availability__c eachRec : Trigger.new)
        {
           if(eachRec.Contact_Timezone_Name__c !=null)
             {
                 String tzName = eachRec.Contact_Timezone_Name__c;
                 System.debug('Timezone name'+tzName);
                 Timezone tz = Timezone.getTimeZone(tzName);
               System.debug('Timezone tz'+tz);
                 
                 Double ms = tz.getOffset(dt);
                 System.debug('Offset miliseconds: ' + ms);
                 Double curTzOffset = (ms/3600000);
                 System.debug('curTzOffset curTzOffset'+curTzOffset);
                 
                 //eachRec.Timezone_Name__c = tzName;
                 eachRec.Timezone_offset__c = curTzOffset;
                 System.debug(eachRec);
             }
        }  
    }*/
 
    //For default records if we have to set Created By Contact , Last Modified By Contact then that Trigger code
    
}