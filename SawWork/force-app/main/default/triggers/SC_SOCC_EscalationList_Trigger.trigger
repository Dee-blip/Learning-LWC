/*
Author          :  Sumukh SS/Pinkesh 
Description     :  Apex Trigger for SOCC Car RunBooks
Test Class      :  SC_SOCC_RunBooks_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh                              SOCC CAR 2 - RunBooks 
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_SOCC_EscalationList_Trigger on SC_SOCC_Escalation_List__c (before insert, before update, after insert, after update, before delete, after delete) {
     //Check if Escalation List with the same name on that PD exists
     if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
          Set<String> lDuplicateELNames = new Set<String>();

          //Finding duplicates in the incoming records
          List<SC_SOCC_Escalation_List__c> lIncomingEL = new List<SC_SOCC_Escalation_List__c>(Trigger.new);
          for(Integer i=0; i<lIncomingEL.size(); i++){
               String ithRec = lIncomingEL[i].Name + lIncomingEL[i].Policy_Domain__c;
               for(Integer j=0; j<lIncomingEL.size(); j++){
               String jthRec = lIncomingEL[j].Name + lIncomingEL[j].Policy_Domain__c;
               if(ithRec.equalsIgnoreCase(jthRec) && i!=j)
                    lDuplicateELNames.add(lIncomingEL[i].Name);
               }
          }

          //Get List of Incoming PD Ids
          Set<Id> lIncomingPDs = new Set<Id>();
          //Get List of new Incoming EL names
          Set<String> lIncomingELNames = new Set<String>();
          for(SC_SOCC_Escalation_List__c eachrec : lIncomingEL){
               lIncomingPDs.add(eachrec.Policy_Domain__c);
               lIncomingELNames.add(eachrec.Name);
          }

          //Set of Parent Account Ids to check if the User SSP and has access
          Set<Id> sAccId = new Set<Id>();
          for(Policy_Domain__c eachPD : [SELECT Id, Account_Name__c FROM Policy_Domain__c WHERE Id IN :lIncomingPDs])
               sAccId.add(eachPD.Account_Name__c);
          
          //Check if User is SSP and has access
          Boolean hasAccess = SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(sAccId);
          if(!hasAccess){
               Trigger.new[0].addError('Only SSPs are allowed to create/edit the record.');
          }

          //List of Existing Escalation List with Selected EL names and PD
          List<SC_SOCC_Escalation_List__c> lExistingEL = new List<SC_SOCC_Escalation_List__c>();
          if(Trigger.isUpdate){
               Set<Id> lIncomingElIds = new Set<Id>();
               for(SC_SOCC_Escalation_List__c eachrec : lIncomingEL)
                    lIncomingElIds.add(eachrec.Id);
               lExistingEL = [Select Id, Name, Policy_Domain__c, Policy_Domain__r.Name from SC_SOCC_Escalation_List__c where Id NOT IN : lIncomingElIds AND Policy_Domain__c IN :lIncomingPDs AND Name IN :lIncomingELNames ORDER BY Name];
          }
          else
               lExistingEL = [Select Id, Name, Policy_Domain__c, Policy_Domain__r.Name from SC_SOCC_Escalation_List__c where Policy_Domain__c IN :lIncomingPDs AND Name IN :lIncomingELNames ORDER BY Name];
          for(SC_SOCC_Escalation_List__c eachExistingRec : lExistingEL){
               String existingRec = eachExistingRec.Name + eachExistingRec.Policy_Domain__c;
               for(SC_SOCC_Escalation_List__c eachIncomingRec : lIncomingEL){
                    String incomingRec = eachIncomingRec.Name + eachIncomingRec.Policy_Domain__c;

                    if(existingRec.equalsIgnoreCase(incomingRec))
                         lDuplicateELNames.add(eachIncomingRec.Name);
               }
          }


          String errorMessage = '';
          if(lDuplicateELNames.size()>0){
               for(String eachRec : lDuplicateELNames)
                    errorMessage += eachRec + ', ';
               errorMessage = errorMessage.removeEnd(', ');
               errorMessage = 'The Escalation Lists : [' + errorMessage + '] are mentioned more than once for the same Policy Domain! Please select a different name.';
          }


          if(String.isNotBlank(errorMessage))
               Trigger.new[0].addError(errorMessage);
     }

     //Set Contact Created and Last Modified BY fields
     if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
          //Fetching Integration profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt 
        SC_SOC_Passphrase_Access__mdt passPhraseAccess = [Select id, Profile_ID_Text__c  from SC_SOC_Passphrase_Access__mdt where DeveloperName =: 'Passphrase_Access_For_Mulesoft' limit 1];
        if(!passPhraseAccess.Profile_ID_Text__c.contains(Userinfo.getProfileId())){
            //Set of lastModified By Ids coz Created BY ID and Last Modified By ID will be same 
            Set<Id> sLastModifiedById = new Set<Id>();
            for(SC_SOCC_Escalation_List__c eachEL : Trigger.new){
                sLastModifiedById.add(eachEL.LastModifiedById);
            }

            //Map of user ids to contact ids to set Created and Last Modified By Contact fields
            Map<Id, String> mUserIdAkamContactId = SC_SOCC_EscalationListCtrl.getAkamContactIds(sLastModifiedById);
            //List of EL to be updated
            List<SC_SOCC_Escalation_List__c> lUpdatedEL = new List<SC_SOCC_Escalation_List__c>();

            for(SC_SOCC_Escalation_List__c eachEL : Trigger.new){
                if(mUserIdAkamContactId.get(eachEL.LastModifiedById) != null){
                    SC_SOCC_Escalation_List__c updatedEL = new SC_SOCC_Escalation_List__c(Id=eachEL.Id);
                    Contact lastModifiedByContact = new Contact(AKAM_Contact_ID__c = mUserIdAkamContactId.get(eachEL.LastModifiedById));
                    if(Trigger.isInsert)
                        updatedEL.Created_By_Contact__r = lastModifiedByContact;
                    updatedEL.Last_Modified_By_Contact__r = lastModifiedByContact;
                    if(!SC_SOCC_EscalationListCtrl.sEscListIdForRecusrion.contains(updatedEL.Id)){
                        SC_SOCC_EscalationListCtrl.sEscListIdForRecusrion.add(updatedEL.Id);
                        lUpdatedEL.add(updatedEL);
                    }
                }
            }

            if(lUpdatedEL.size()>0){
                try{
                    update lUpdatedEL;
                }catch(Exception e){
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        }
     }

}