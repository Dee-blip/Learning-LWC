global class ZoffUtilClass {
    // This class would be covered by OpportunityLineItem
    public static Map < String, L2Q_ZOFF_Feature__mdt > zoffmetadatMapping = new Map < String, L2Q_ZOFF_Feature__mdt > ();
    // method to return zoff Account Reassignment Mapping on associated user 
    public static Map < String, Account_Reassignment_Rule__c > getzoffapproverfromArr(Set < Id > userIds) {
        Map < String, Account_Reassignment_Rule__c > retMap = new Map < String, Account_Reassignment_Rule__c > ();
        for (Account_Reassignment_Rule__c acr: [Select Id, Name, Associated_User__c, Zoff_Approver_Email__c, SubTerritory__c, Area__c, Division__c, Zoff_Approver__c, Zoff_Delegated_Approver__c, ZOFF_Approvers_Name__c, Associated_User_RSM__c from Account_Reassignment_Rule__c where Associated_User__c in: userIds order by lastmodifieddate asc limit 50000]) {
            retMap.put(acr.Associated_User__c + acr.SubTerritory__c, acr);
        }
        return retMap;
    }
    // Common utility to send Email for ZOFF Related Changes 
    public static void sendZoffEmail(Map < Id, ZoffUtilClass.emailListwrapper > mailMap) {
        List < Messaging.SingleEmailMessage > listofMailtoSend = new List < Messaging.SingleEmailMessage > ();
        // Prepare Template for ZOFF Related Status Changes 
        Map < String, String > templMap = new Map < String, String > ();
        for (EmailTemplate em: [Select id, developerName from EmailTemplate where developerName in ('ZOFF_Rejection_Email', 'ZOFF_Resubmitted_Request_Email', 'ZOFF_Request_Submitted', 'ZOFF_Approved_Email')]) {
            templMap.put(em.DeveloperName, em.Id);
        }
        String ctId = getZOFFmdtsetting('ZOFF').Default_ContactId__c;
        for (Id str: mailMap.keySet()) {
            String templateId = mailMap.get(str).zoffStatus == 'Submitted' ? templMap.get('ZOFF_Request_Submitted') : (mailMap.get(str).zoffStatus == 'Resubmitted' ? templMap.get('ZOFF_Resubmitted_Request_Email') : (mailMap.get(str).zoffStatus == 'Rejected' ? templMap.get('ZOFF_Rejection_Email') : (mailMap.get(str).zoffStatus == 'Approved' ? templMap.get('ZOFF_Approved_Email') : '')));
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(ctId);
            mail.setToAddresses(mailMap.get(str).toList);
            if (!mailMap.get(str).ccList.isEmpty()) {
                mail.setCcAddresses(mailMap.get(str).ccList);
            }
            mail.setTemplateId(templateId);
            mail.setReplyTo(UserInfo.getUserEmail());
            mail.setSaveAsActivity(false);
            mail.setWhatId(str);
            mail.setTreatTargetObjectAsRecipient(false); //This sfdc property stops sending email to targetobjectId //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_email_outbound_single.htm
            listofMailtoSend.add(mail);
        }
        if (!listofMailtoSend.isEmpty()) {
            Messaging.sendEmail(listofMailtoSend); // limit 10 for single transaction 
        }
    }
    // Email List Wrapper for Sending an Email 
    public class emailListwrapper {
        public List < String > toList;
        public List < String > ccList;
        public String zoffStatus;
        public emailListwrapper() {
            toList = new List < String > ();
            ccList = new List < String > ();
            zoffStatus = '';
        }
    }


    // static caching for ZOFF metadata for single transaction 
    public static L2Q_ZOFF_Feature__mdt getZOFFmdtsetting(String developerName) {
        //getbyName does not work even mentioned in directed document  : https://releasenotes.docs.salesforce.com/en-us/spring15/release-notes/rn_forcecom_development_additional_custom_metadata.htm
        L2Q_ZOFF_Feature__mdt returnValue = null;
        if (zoffmetadatMapping.containsKey(developerName)) {
            returnValue = zoffmetadatMapping.get(developerName);
        } else {
            List < L2Q_ZOFF_Feature__mdt > zoffMdt = [select Id, Field_Details__c, Feature_Enabled__c, Default_Approver__c, Special_Approval_Field_Change_Profiles__c, Mail_Enabled__c, Opportunity_Type_Appr__c, Default_ContactId__c, Default_TemplateId__c, Approval_Text__c, Product2OppotySyncAllowed__c, Product2SyncFilterClause__c, Product2SyncBatchSize__c, WebProduct2List__c, Toggle6SignedValidation__c from L2Q_ZOFF_Feature__mdt where DeveloperName =: developerName limit 1];
            if (!zoffMdt.isEmpty()) {
                returnValue = zoffMdt[0];
                zoffmetadatMapping.put(developerName, zoffMdt[0]);
            }
        }
        return returnValue;
    }
    //this works if both have value and it searches linearly works well for lower list size else needs to implement binary  || KMP search for huge size 
    public static boolean listcontainsIgnorcase(List < String > listOfstring, string stringtoSearch) {
        if (String.isBlank(stringtoSearch) || (listOfstring == null || listOfstring.isEmpty())) {
            return false;
        }
        for (String str: listOfString) {
            if (str.equalsIgnoreCase(stringtoSearch)) {
                return true;
            }
        }
        return false;
    }

    //Begin Rajesh Kumar SFDC-7473
    public static Map < Id, Channel_Mapping__c > findRCMmapping(List < Opportunity > oppList) {
        Map < Id, Channel_Mapping__c > chMap = new Map < Id, Channel_Mapping__c > ();
        set < String > cmList = new set < String > ();
        for (Opportunity opp: oppList) {
            if ('Indirect'.equalsIgnoreCase(opp.deal_type__c) && String.isNotBlank(opp.channel_manager__c)) {
                cmList.add(opp.channel_manager__c);
            }
        }
        System.debug('cmList>>'+cmList);
        if (!cmList.isEmpty()) {
            chMap = new Map < Id, Channel_Mapping__c > ([Select Id, ZOFF_Approvers_Email__c, Comp_Owner1__c from Channel_Mapping__c where Id in: cmList order by lastmodifieddate asc limit 50000]);
        }
        System.debug('chMap>>'+chMap);
        return chMap;
    }
    //End Rajesh Kumar SFDC-7473

}