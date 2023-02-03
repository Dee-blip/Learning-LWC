/*
Author          :  Pinkesh 
Description     :  Apex Trigger for SOCC Car RunBooks
Test Class      :  SC_SOCC_RunBooks_TC

Date                Developer                JIRA #              Description                                                       
-----------------------------------------------------------------------------------------------------------------
27 July 2020        Pinkesh                  ESESP-3730          SOCC CAR 2 - RunBooks 
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_SOCC_EscalationViaCaseEmail on SC_SOCC_Escalation_via_Case_Email__c (before insert, before update, after insert, after update, before delete, after delete) {
     if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
          //Set on Escalation List Ids for the incoming ECs
          Set<Id> sELId = new Set<Id>();
          //Set on Authotized Contact Ids for the incoming ECs
          Set<Id> sACId = new Set<Id>();

          for(SC_SOCC_Escalation_via_Case_Email__c eachEC : Trigger.new){
               sELId.add(eachEC.Escalation_List__c);
               sACId.add(eachEC.Authorized_Contact__c);
          }

          //Query to get all the related ECs
          List<SC_SOCC_Escalation_via_Case_Email__c> lEC = [SELECT Id, Escalation_List__c, Escalation_List__r.Policy_Domain__c, Authorized_Contact__c FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c IN :sELId ORDER BY Name];

          //Map of EL id to corresponding EC's set of AC ids of existing queried values. Map used to find duplicate AC being inserted/updated as EC.
          Map<Id, Set<Id>> mElIdsAuthConId = new Map<Id, Set<Id>>();
          //Check if duplicate Authorized Contacts are present
          for(SC_SOCC_Escalation_via_Case_Email__c eachEC : lEC){
               if(mElIdsAuthConId.get(eachEC.Escalation_List__c) == null){
                    mElIdsAuthConId.put(eachEC.Escalation_List__c, new Set<Id>());
               }
               mElIdsAuthConId.get(eachEC.Escalation_List__c).add(eachEC.Authorized_Contact__c);
          }

          //Check if Duplicate Auth Con are present as EC
          //set to check if same AC is present more than once in Trigger.new
          Map<Id, Set<Id>> mElIdsAuthConIdTriggerNew = new Map<Id, Set<Id>>();
          for(SC_SOCC_Escalation_via_Case_Email__c eachEC : Trigger.new){
               if(mElIdsAuthConIdTriggerNew.get(eachEC.Escalation_List__c) == null)
                    mElIdsAuthConIdTriggerNew.put(eachEC.Escalation_List__c, new Set<Id>());
               Set<Id> sAuthConIdTriggerNew = mElIdsAuthConIdTriggerNew.get(eachEC.Escalation_List__c);
               if(!sAuthConIdTriggerNew.contains(eachEC.Authorized_Contact__c))
                    sAuthConIdTriggerNew.add(eachEC.Authorized_Contact__c);
               else
                    Trigger.new[0].addError('Duplicate Authorized Contact found! Please select a different one!');

               //Checking duplicate records from the existing records
               Set<Id> sAuthConId = mElIdsAuthConId.get(eachEC.Escalation_List__c);
               if(sAuthConId!=null && sAuthConId.contains(eachEC.Authorized_Contact__c) &&(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(eachEC.Id).Authorized_Contact__c != eachEC.Authorized_Contact__c))){
                    Trigger.new[0].addError('Duplicate Authorized Contact found! Please select a different one!');
               }
          }

          //Set of Parent Account Ids to check if the User SSP and has access
          Set<Id> sAccId = new Set<Id>();
          //Map of EL to parent PD Id used to check if the authorized contact is under the PD of the parent Escalation List
          Map<Id, Id> mElIdPdId = new Map<Id,Id>();

          //Set mElIdPdId map, Need this query because there might not be an EC created, so it won't return the any record if queried on EC
          for(SC_SOCC_Escalation_List__c eachEL : [SELECT Id, Policy_Domain__c, Policy_Domain__r.Account_Name__c FROM SC_SOCC_Escalation_List__c WHERE Id IN :sELId]){
               sAccId.add(eachEL.Policy_Domain__r.Account_Name__c);
               mElIdPdId.put(eachEL.Id, eachEL.Policy_Domain__c);
          }
          
          //Map of Auth Con to parent PD Id used to check if the authorized contact is under the PD of the parent Escalation List
          Map<Id, Id> mAcIdPdId = new Map<Id,Id>();
          //Map on Authotized Contact Ids to Contact Name
          Map<Id, String> mACIdContactName = new Map<Id, String>();
          //Set mAcIdPdId map
          for(Authorized_Contact__c eachAC : [SELECT Id, Policy_Domain__c, Contact_Name__r.Name FROM Authorized_Contact__c WHERE Id IN :sACId]){
               mAcIdPdId.put(eachAC.Id, eachAC.Policy_Domain__c);
               mACIdContactName.put(eachAC.Id, eachAC.Contact_Name__r.Name);
          }

          for(SC_SOCC_Escalation_via_Case_Email__c eachEC : Trigger.new){
               //Setting the Esc Con name to corresponding Contact Name
               if(Trigger.isInsert && String.isBlank(eachEC.Name) && mACIdContactName.get(eachEC.Authorized_Contact__c) != null)
                    eachEC.Name = mACIdContactName.get(eachEC.Authorized_Contact__c);

               //Check if the authorized contact is under the PD of the parent Escalation List
               Id pdId1 = mElIdPdId.get(eachEC.Escalation_List__c);
               Id pdId2 = mAcIdPdId.get(eachEC.Authorized_Contact__c);
               if(pdId1 != null && pdId2 != null && pdId1 != pdId2){
                    Trigger.new[0].addError('The Authorized Contact does not belong to this Policy Domain. Please select a correct Authorized Contact.');
               }
          }

          //Check if User is SSP and has access
          Boolean hasAccess = SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(sAccId);
          if(!hasAccess){
               Trigger.new[0].addError('Only SSPs are allowed to create/edit the record.');
          }

     }


     if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        //Fetching Integration profiles with passphrase permission that are stored in SC_SOC_Passphrase_Access__mdt 
        SC_SOC_Passphrase_Access__mdt passPhraseAccess = [Select id, Profile_ID_Text__c  from SC_SOC_Passphrase_Access__mdt where DeveloperName =: 'Passphrase_Access_For_Mulesoft' limit 1];
        if(!passPhraseAccess.Profile_ID_Text__c.contains(Userinfo.getProfileId())){
            //Set of lastModified By Ids coz Created BY ID and Last Modified By ID will be same 
            Set<Id> sLastModifiedById = new Set<Id>();
            for(SC_SOCC_Escalation_via_Case_Email__c eachEC : Trigger.new){
                sLastModifiedById.add(eachEC.LastModifiedById);
            }

            //Map of user ids to contact ids to set Created and Last Modified By Contact fields
            Map<Id, String> mUserIdAkamContactId = SC_SOCC_EscalationListCtrl.getAkamContactIds(sLastModifiedById);
            //List of EC to be updated
            List<SC_SOCC_Escalation_via_Case_Email__c> lUpdatedEC = new List<SC_SOCC_Escalation_via_Case_Email__c>();

            for(SC_SOCC_Escalation_via_Case_Email__c eachEC : Trigger.new){
                if(mUserIdAkamContactId.get(eachEC.LastModifiedById) != null){
                    SC_SOCC_Escalation_via_Case_Email__c updatedEC = new SC_SOCC_Escalation_via_Case_Email__c(Id=eachEC.Id);
                    Contact lastModifiedByContact = new Contact(AKAM_Contact_ID__c = mUserIdAkamContactId.get(eachEC.LastModifiedById));
                    if(Trigger.isInsert)
                        updatedEC.Created_By_Contact__r = lastModifiedByContact;
                    updatedEC.Last_Modified_By_Contact__r = lastModifiedByContact;
                    if(!SC_SOCC_EscalationListCtrl.sEscConIdForRecusrion.contains(updatedEC.Id)){
                        SC_SOCC_EscalationListCtrl.sEscConIdForRecusrion.add(updatedEC.Id);
                        lUpdatedEC.add(updatedEC);
                    }
                }
            }

            if(lUpdatedEC.size()>0){
                try{
                    update lUpdatedEC;
                }catch(Exception e){
                    System.debug('The following exception has occurred: ' + e.getMessage());
                }
            }
        }

    }
    

}