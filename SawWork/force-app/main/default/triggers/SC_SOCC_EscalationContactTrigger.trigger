trigger SC_SOCC_EscalationContactTrigger on SC_SOCC_Escalation_Contact__c (before insert, before update, after insert, after update, before delete, after delete) {
    //On deletion Reorder related Escalation Contacts on parent Escalation List
    if(Trigger.isBefore && Trigger.isDelete){
        Set<Id> sEscConId = new Set<Id>();
        Set<Id> sParentEscListId = new Set<Id>();
        for(SC_SOCC_Escalation_Contact__c eachrec : Trigger.old){
            sEscConId.add(eachrec.Id);
            sParentEscListId.add(eachrec.Escalation_List__c);
        }
        
        //Get all the related Escalation Contacts
        List<SC_SOCC_Escalation_Contact__c> lRelatedEscCon = [SELECT Id, Escalation_List__c, Escalation_List__r.Policy_Domain__r.Account_Name__c, Order_Number__c FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__c IN :sParentEscListId ORDER BY Order_Number__c];

        //Set of Parent Account Ids to check if the User SSP and has access
        Set<Id> sAccId = new Set<Id>();

        //Map of EL to List Esc Con records
        Map<Id, List<SC_SOCC_Escalation_Contact__c>> mEscListIdLEscCon = new Map<Id, List<SC_SOCC_Escalation_Contact__c>>();

        for(SC_SOCC_Escalation_Contact__c eachrec : lRelatedEscCon){
            sAccId.add(eachrec.Escalation_List__r.Policy_Domain__r.Account_Name__c);

            if(!mEscListIdLEscCon.containsKey(eachrec.Escalation_List__c))
                mEscListIdLEscCon.put(eachrec.Escalation_List__c, new List<SC_SOCC_Escalation_Contact__c>());
            List<SC_SOCC_Escalation_Contact__c> lEscCon = mEscListIdLEscCon.get(eachrec.Escalation_List__c);
            lEscCon.add(eachrec);
            mEscListIdLEscCon.put(eachrec.Escalation_List__c, lEscCon);
        }

        //Check if User is SSP and has access
        Boolean hasAccess = SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(sAccId);
        if(!hasAccess){
            Trigger.old[0].addError('Only SSPs are allowed to delete the record.');
        }


        //List of Escalation Contacts to be updated
        List<SC_SOCC_Escalation_Contact__c> lUpdateEscCon = new List<SC_SOCC_Escalation_Contact__c>();
        //Rectify the Order
        for(Id eachEL : mEscListIdLEscCon.keySet()){
            Integer orderNumber = 1;
            for(SC_SOCC_Escalation_Contact__c eachEC : mEscListIdLEscCon.get(eachEL)){
                if(!sEscConId.contains(eachEC.Id)){
                    SC_SOCC_Escalation_Contact__c updateEscCon = new SC_SOCC_Escalation_Contact__c(Id=eachEC.Id, Order_Number__c=orderNumber++);
                    lUpdateEscCon.add(updateEscCon);
                }
            }
        }

        if(lUpdateEscCon.size()>0)
            update lUpdateEscCon;
    }

    //Before Insert and before update
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
        //Set on Escalation List Ids for the incoming ECs
        Set<Id> sELId = new Set<Id>();
        //Set on Authotized Contact Ids for the incoming ECs
        Set<Id> sACId = new Set<Id>();
        //Map on Authotized Contact Ids to Contact Name
        Map<Id, String> mACIdContactName = new Map<Id, String>();
        //Map of EL to parent PD Id used to check if the authorized contact is under the PD of the parent Escalation List
        Map<Id, Id> mElIdPdId = new Map<Id,Id>();
        //Map of Auth Con to parent PD Id used to check if the authorized contact is under the PD of the parent Escalation List
        Map<Id, Id> mAcIdPdId = new Map<Id,Id>();
        //Map of EL id to corresponding EC's set of AC ids of existing queried values. Map used to find duplicate AC being inserted/updated as EC.
        Map<Id, Set<Id>> mElIdsAuthConId = new Map<Id, Set<Id>>();
        //Map of EL id to corresponding incoming EC's Order Number. Used to validate the order number on EC.
        Map<Id, Set<Integer>> mElIdsSOrderNumber = new Map<Id, Set<Integer>>();
        //Map of EL id to number of EC. Used to validate the order number range on EC.
        Map<Id, Integer> mElIdOrderNumberRange = new Map<Id, Integer>();
        //Map of EL id to corresponding existing EC. Used to validate the order number on EC.
        Map<Id, List<SC_SOCC_Escalation_Contact__c>> mElIdLExistingEC = new Map<Id, List<SC_SOCC_Escalation_Contact__c>>();

        for(SC_SOCC_Escalation_Contact__c eachEC : Trigger.new){
            eachEC.Order_Number__c = eachEC.Order_Number__c.intValue();
            sELId.add(eachEC.Escalation_List__c);
            sACId.add(eachEC.Authorized_Contact__c);
            
            // Setting map mElIdsSOrderNumber
            if(mElIdsSOrderNumber.get(eachEC.Escalation_List__c) == null){
                mElIdsSOrderNumber.put(eachEC.Escalation_List__c, new Set<Integer>());
            }
            if(! mElIdsSOrderNumber.get(eachEC.Escalation_List__c).add(eachEC.Order_Number__c.intValue())){
                Trigger.new[0].addError('Order Number ' + eachEC.Order_Number__c.intValue() + ' is present more than once on the same Escalation List. Please select a correct Order Number.');
            }
            // Set<Integer> sOrderNumber = mElIdsSOrderNumber.get(eachEC.Escalation_List__c);
            // if(eachEC.Order_Number__c != null){
            //     if(!sOrderNumber.contains(eachEC.Order_Number__c.intValue())){
            //         sOrderNumber.add(eachEC.Order_Number__c.intValue());
            //     }
            //     else
            //         Trigger.new[0].addError('Order Number ' + eachEC.Order_Number__c.intValue() + ' is present more than once on the same Escalation List. Please select a correct Order Number.');
            // }
            //mElIdsSOrderNumber.put(eachEC.Escalation_List__c, sOrderNumber);
            
            //Setting map mElIdOrderNumberRange
            if(Trigger.isInsert){
                if(mElIdOrderNumberRange.get(eachEC.Escalation_List__c) == null)
                    mElIdOrderNumberRange.put(eachEC.Escalation_List__c, 1);
                else{
                    Integer orderNumberRange = mElIdOrderNumberRange.get(eachEC.Escalation_List__c);
                    mElIdOrderNumberRange.put(eachEC.Escalation_List__c, ++orderNumberRange);
                }
            }
        }

        //Query to get all the related ECs
        List<SC_SOCC_Escalation_Contact__c> lEC = [SELECT Id, Escalation_List__c, Escalation_List__r.Policy_Domain__c, Authorized_Contact__c, Order_Number__c FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__c IN :sELId ORDER BY Order_Number__c];

        for(SC_SOCC_Escalation_Contact__c eachEC : lEC){
            //Setting map mElIdPdId
            //mElIdPdId.put(eachEC.Escalation_List__c, eachEC.Escalation_List__r.Policy_Domain__c);

            //Setting map mElIdsAuthConId
            if(mElIdsAuthConId.get(eachEC.Escalation_List__c) == null)
                mElIdsAuthConId.put(eachEC.Escalation_List__c, new Set<Id>());
            Set<Id> sAuthConId = mElIdsAuthConId.get(eachEC.Escalation_List__c);
            sAuthConId.add(eachEC.Authorized_Contact__c);
            mElIdsAuthConId.put(eachEC.Escalation_List__c, sAuthConId);

            //Setting map mElIdLExistingEC
            if(mElIdLExistingEC.get(eachEC.Escalation_List__c) == null)
                mElIdLExistingEC.put(eachEC.Escalation_List__c, new List<SC_SOCC_Escalation_Contact__c>());
            List<SC_SOCC_Escalation_Contact__c> lExistingEC = mElIdLExistingEC.get(eachEC.Escalation_List__c);
            lExistingEC.add(eachEC);
            mElIdLExistingEC.put(eachEC.Escalation_List__c, lExistingEC);

            //setting map mElIdOrderNumberRange
            if(mElIdOrderNumberRange.get(eachEC.Escalation_List__c) == null)
                mElIdOrderNumberRange.put(eachEC.Escalation_List__c, 1);
            else{
                Integer orderNumberRange = mElIdOrderNumberRange.get(eachEC.Escalation_List__c);
                mElIdOrderNumberRange.put(eachEC.Escalation_List__c, ++orderNumberRange);
            }
        }

        //Check if Duplicate Auth Con are present as EC
        //set to check if same AC is present more than once in Trigger.new
        Map<Id, Set<Id>> mElIdsAuthConIdTriggerNew = new Map<Id, Set<Id>>();
        for(SC_SOCC_Escalation_Contact__c eachEC : Trigger.new){
            if(mElIdsAuthConIdTriggerNew.get(eachEC.Escalation_List__c) == null)
                mElIdsAuthConIdTriggerNew.put(eachEC.Escalation_List__c, new Set<Id>());
            Set<Id> sAuthConIdTriggerNew = mElIdsAuthConIdTriggerNew.get(eachEC.Escalation_List__c);
            if(!sAuthConIdTriggerNew.contains(eachEC.Authorized_Contact__c))
                sAuthConIdTriggerNew.add(eachEC.Authorized_Contact__c);
            else
                Trigger.new[0].addError('Duplicate Authorized Contact found! Please select a different one!');

            //Checking duplicate records from the existing records
            for(Id elId : mElIdsAuthConId.keySet()){
                Set<Id> sAuthConId = mElIdsAuthConId.get(elId);
                if(sAuthConId.contains(eachEC.Authorized_Contact__c) &&(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(eachEC.Id).Authorized_Contact__c != eachEC.Authorized_Contact__c))){
                    Trigger.new[0].addError('Duplicate Authorized Contact found! Please select a different one!');
                }
            }
        }

        if(!SC_SOCC_EscalationListCtrl.checkRecursion){
            //Check if the incoming order number are in correct range
            for(Id eachEL : mElIdsSOrderNumber.keySet()){
                for(Integer orderNumber : mElIdsSOrderNumber.get(eachEL)){
                    Integer maxOrderNumber = mElIdOrderNumberRange.get(eachEL);
                    if(orderNumber<1 || orderNumber>maxOrderNumber)
                        Trigger.new[0].addError('Order Number ' + orderNumber + ' out of range. Please enter Order Number between 1-' + maxOrderNumber + ' for this Escalation Contact.');
                }
            }
        
            //Update the Order Number of the existing records mElIdsSOrderNumber mElIdSEcId
            //List of EC on which Order Number will be updated 
            List<SC_SOCC_Escalation_Contact__c> lECToBeUpdated = new List<SC_SOCC_Escalation_Contact__c>();
            for(Id eachEL : mElIdLExistingEC.keySet()){
                Integer orderNumber = 1;
                for(SC_SOCC_Escalation_Contact__c eachEC : mElIdLExistingEC.get(eachEL)){
                    Set<Integer> sOrderNumber = mElIdsSOrderNumber.get(eachEL);
                    if(sOrderNumber != null)
                        while(sOrderNumber.contains(orderNumber))
                            orderNumber++;
                    //If it is an insert operation or if the record's Order Number is not updated, then change the Order Number Accordingly
                    if(Trigger.isInsert || (Trigger.isUpdate && Trigger.newMap.get(eachEC.Id) == null)){
                        SC_SOCC_Escalation_Contact__c updatedEC = new SC_SOCC_Escalation_Contact__c(Id=eachEC.Id, Order_Number__c=orderNumber++);
                        lECToBeUpdated.add(updatedEC);
                    }
                }
            }

            if(lECToBeUpdated.size()>0){
                SC_SOCC_EscalationListCtrl.checkRecursion = true;
                update lECToBeUpdated;
            }
        }

        //Set of Parent Account Ids to check if the User SSP and has access
        Set<Id> sAccId = new Set<Id>();

        //Set mElIdPdId map, Need this query because there might not be an Escalation Contact created, so it won't return the any record if queried on EC
        for(SC_SOCC_Escalation_List__c eachEL : [SELECT Id, Policy_Domain__c, Policy_Domain__r.Account_Name__c FROM SC_SOCC_Escalation_List__c WHERE Id IN :sELId]){
            sAccId.add(eachEL.Policy_Domain__r.Account_Name__c);
            mElIdPdId.put(eachEL.Id, eachEL.Policy_Domain__c);
        }
        
        //Set mAcIdPdId map
        for(Authorized_Contact__c eachAC : [SELECT Id, Policy_Domain__c, Contact_Name__r.Name FROM Authorized_Contact__c WHERE Id IN :sACId]){
            mAcIdPdId.put(eachAC.Id, eachAC.Policy_Domain__c);
            mACIdContactName.put(eachAC.Id, eachAC.Contact_Name__r.Name);
        }

        for(SC_SOCC_Escalation_Contact__c eachEC : Trigger.new){
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
            for(SC_SOCC_Escalation_Contact__c eachEC : Trigger.new){
                sLastModifiedById.add(eachEC.LastModifiedById);
            }

            //Map of user ids to contact ids to set Created and Last Modified By Contact fields
            Map<Id, String> mUserIdAkamContactId = SC_SOCC_EscalationListCtrl.getAkamContactIds(sLastModifiedById);
            //List of EC to be updated
            List<SC_SOCC_Escalation_Contact__c> lUpdatedEC = new List<SC_SOCC_Escalation_Contact__c>();

            for(SC_SOCC_Escalation_Contact__c eachEC : Trigger.new){
                if(mUserIdAkamContactId.get(eachEC.LastModifiedById) != null){
                    SC_SOCC_Escalation_Contact__c updatedEC = new SC_SOCC_Escalation_Contact__c(Id=eachEC.Id);
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