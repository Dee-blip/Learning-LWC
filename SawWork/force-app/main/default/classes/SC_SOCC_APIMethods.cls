@RestResource(urlMapping='/SOCC/*')
global class SC_SOCC_APIMethods {

    @HttpPost
    global static Response copyEL(String fromEscalationListId,
        String targetPolicyDomainId, String targetEscalationListName,
        String createdByContactId) {
        List<String> lInvalidEC = new List<String>();
        Response response;
        Policy_Domain__c pdRef = new Policy_Domain__c(AKAM_Policy_Domain_ID__c=targetPolicyDomainId);
        Contact createdByContact = new Contact (AKAM_Contact_ID__c = createdByContactId);
        SC_SOCC_Escalation_List__c newEL = new SC_SOCC_Escalation_List__c();
        newEL.Name = targetEscalationListName;
        newEL.Policy_Domain__r = pdRef;
        newEL.Created_By_Contact__r = createdByContact;
        newEl.Last_Modified_By_Contact__r = createdByContact;
        Map<String,String> mContactToAuthContact = new Map<String,String>();
        Savepoint sp = Database.setSavepoint();
        try{
            insert newEL;
        }
        catch(Exception e){
            System.debug('Exception Message ' + e.getCause() + '  ' + e.getDmlMessage(0));
            List<String> errorMessage = new List<String>();
            errorMessage.add(e.getDmlMessage(0));
            response = new Response ('',new List<String>(), false, 400, errorMessage);
            return response;
        }

        //Get list of all the Contact Ids which are present as Authorized Contact on the new Policy Domain
        Set<Id> lConId = new Set<Id>();
        for(Authorized_Contact__c eachRec : [Select Id, Contact_Name__c from Authorized_Contact__c WHERE Policy_Domain__r.AKAM_Policy_Domain_ID__c =:targetPolicyDomainId]){
            lConId.add(eachRec.Contact_Name__c);
            mContactToAuthContact.put(eachRec.Contact_Name__c, eachRec.Id);
        }

        //List of All Escalation Contacts under the Escalation List
        List<SC_SOCC_Escalation_Contact__c> lAllEscalationCon =  [SELECT Id, Escalation_List__c, Order_Number__c, Action_If_Unreachable__c, Akam_Escalation_Contact_Id__c,
                                                                   Authorized_Contact__c, Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
                                                                   FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__r.Akam_Escalation_List_Id__c =:fromEscalationListId
                                                                   ORDER BY Order_Number__c];

        //List to insert all the valid Escalation Contacts
        List<SC_SOCC_Escalation_Contact__c> lValidEscalationCon =  new List<SC_SOCC_Escalation_Contact__c>();
        Integer orderNumber = 1;
        for(SC_SOCC_Escalation_Contact__c eachRec : lAllEscalationCon){
            if(lConId.contains(eachRec.Authorized_Contact__r.Contact_Name__c)){
                //create each Escalation Contacts
                SC_SOCC_Escalation_Contact__c eachValidEscCon = new SC_SOCC_Escalation_Contact__c();
                eachValidEscCon.Escalation_List__c = newEL.Id;
                eachValidEscCon.Name = eachRec.Authorized_Contact__r.Contact_Name__r.Name;
                eachValidEscCon.Authorized_Contact__c = mContactToAuthContact.get(eachRec.Authorized_Contact__r.Contact_Name__c);
                eachValidEscCon.Order_Number__c = orderNumber++;
                eachValidEscCon.Action_If_Unreachable__c = eachRec.Action_If_Unreachable__c != null ? eachRec.Action_If_Unreachable__c : null;
                eachValidEscCon.Last_Modified_By_Contact__r = createdByContact;
                eachValidEscCon.Created_By_Contact__r = createdByContact;
                lValidEscalationCon.add(eachValidEscCon);
             }
             else{
                 lInvalidEC.add(eachRec.Akam_Escalation_Contact_Id__c);
             }
         }
       try{
        insert lValidEscalationCon;
       }
       catch(Exception e){
        Database.rollback(sp);
        System.debug('Exception Message ' + e.getCause() + '  ' + e.getDmlMessage(0));
        List<String> errorMessage = new List<String>();
        errorMessage.add(e.getDmlMessage(0));
        response = new Response ('',new List<String>(), false, 400, errorMessage);
        return response;
    }

       SC_SOCC_Escalation_List__c newCompleteEL = [Select Id, Akam_Escalation_List_Id__c FROM SC_SOCC_Escalation_List__c WHERE Id=:newEL.Id];
        response = new Response (newCompleteEL.Akam_Escalation_List_Id__c,lInvalidEC, true, 201, new List<String>());
       //response = new Object(id = newCompleteEL.Akam_Escalation_List_Id__c); //'{ "id" : ' + newCompleteEL.Akam_Escalation_List_Id__c + ', "invalidEscalationContacts" : ' + lInvalidEC + '}';
       return response;

    }

    global class Response {
        String id;
        List<String> invalidECIds;
        Boolean success;
        Integer status;
        List<String> error;

        Response(String id, List<String> lInvalidECIds,
        Boolean success, Integer status, List<String> error){
            this.id = id;
            this.invalidECIds = lInvalidECIds;
            this.error = error;
            this.success = success;
            this.status = status;
        }
    }
}