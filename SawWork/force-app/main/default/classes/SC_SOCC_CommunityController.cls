/*
Author          : Vikas R
Description     : Apex Controller for SOCC Community Runbooks

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
14 March 2020        Vikas R									Runbooks	
07 Jan 2021			 Sumukh SS									Qualtrics Survey Code
------------------------------------------------------------------------------------------------------------------
*/

public with sharing class SC_SOCC_CommunityController {
    
    
    //Qualtrics Survey 
    @AuraEnabled(cacheable=true)
	public static string getContactEmailAddress() {    
        
        string emailaddr = [select email from user where id=:userinfo.getUserId()].email;
        
        return emailaddr;
    }

    public class PDWrapper
    {
        @AuraEnabled public Policy_Domain__c PDRec{get;set;}
        @AuraEnabled public Id PDRecId{get;set;}
        @AuraEnabled public String PDRecName{get;set;}
        @AuraEnabled public String PDRecAccountName{get;set;}
        @AuraEnabled public String PDRecProduct{get;set;}
        @AuraEnabled public String PDRecAdditionalProduct{get;set;}
        @AuraEnabled public String PDAKAMId{get;set;}
        @AuraEnabled public String pdId{get;set;}
    }
    public class InstructionWrapper
    {
        @AuraEnabled public Instruction__c instructionRec{get;set;}
        @AuraEnabled public Id instructionRecId{get;set;}
        @AuraEnabled public String instructionRecDisplayName{get;set;}
        @AuraEnabled public String instructionRecName{get;set;}
        @AuraEnabled public String instructionRecUrl{get;set;}
        @AuraEnabled public String instructionRecCaseId{get;set;}
        @AuraEnabled public String instructionRecCaseNumber{get;set;}
        @AuraEnabled public String instructionRecAKAMCaseNumber{get;set;}
        @AuraEnabled public String instructionRecCaseUrl{get;set;}
        @AuraEnabled public String instructionRecType{get;set;}
        @AuraEnabled public String instructionRecStatus{get;set;}
        @AuraEnabled public String instructionRecCreatedBy{get;set;}
        @AuraEnabled public String instructionRecCreatedDate{get;set;}
        @AuraEnabled public String instructionRecValue{get;set;}
        @AuraEnabled public String instructionRecValueDisplay{get;set;}
        @AuraEnabled public String instructionHandlerRecName{get;set;}
    }
    @AuraEnabled(cacheable=true)
    public static List<PDWrapper> getPDList() {
        List<id> PDIdList = new List<id>();
        List<String> employeeEmailList = new List<String>();
        List<Id> employeeIdList = new List<Id>();
        List<Id> communityContactIdList = new List<Id>();
        PDWrapper pdWrapperRec;
        List<PDWrapper> PDWrapperList = new List<PDWrapper>();
        for(User thisUser : [Select id,contactId,email from User where id =: userinfo.getUserId()]){
            if(thisUser.email.contains('@akamai.com'))
                employeeIdList.add(thisUser.id);
            	//employeeEmailList.add(thisUser.email);
            if(thisUser.contactId != null)
            	communityContactIdList.add(thisUser.contactId);
        }
        for(Policy_Domain__c thisPD : [Select id from Policy_Domain__c where Account_Name__c in (Select PD_Account__c from SOCC_User_Account_Mapping__c where Internal_User__c in : employeeIdList and Internal_User__r.IsActive = true and Active__c = true)]){
            PDIdList.add(thisPD.id);
        }
        for(Authorized_Contact__c thisAC : [Select Policy_Domain__c from Authorized_Contact__c where Contact_Name__c in: communityContactIdList /*OR Contact_Name__r.Email in: employeeEmailList*/]){
            PDIdList.add(thisAC.Policy_Domain__c);
        }
        for(Policy_Domain__c thisPD : [SELECT Id, Name, Account_Name__r.Name,Additional_Product__c, Product__c,AKAM_Policy_Domain_ID__c  FROM Policy_Domain__c where id in:(PDIdList)]){
            pdWrapperRec = new PDWrapper();
            pdWrapperRec.PDRec = thisPD;
            pdWrapperRec.PDRecId = thisPD.Id;
            pdWrapperRec.PDRecName = thisPD.Name;
            pdWrapperRec.PDRecAccountName = thisPD.Account_Name__r.Name;
            pdWrapperRec.PDRecProduct = thisPD.Product__c;
            pdWrapperRec.PDRecAdditionalProduct = thisPD.Additional_Product__c;
            pdWrapperRec.PDAKAMId = thisPD.AKAM_Policy_Domain_ID__c;
            pdWrapperRec.pdId = encryptPDId(thisPD.AKAM_Policy_Domain_ID__c);
            PDWrapperList.add(pdWrapperRec);
        }
        system.debug('PDWrapperList : '+PDWrapperList);

        return PDWrapperList;
    }

    public static String encryptPDId(String pdId) {
        List<SC_Utility__mdt> lMetadata = [SELECT Id, DeveloperName, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c=true AND DeveloperName IN ('Encryption_Key_for_PD_on_Community', 'IV_for_PD_Encryption_on_Community') ORDER BY DeveloperName ASC];
        Blob key = EncodingUtil.base64Decode(lMetadata[0].Value_Text__c);
        Blob iv = Blob.valueOf(lMetadata[1].Value_Text__c);
        Blob data = Blob.valueOf(pdId);
        Blob encrypted = Crypto.encrypt('AES128', key, iv, data);
        String encryptedString = EncodingUtil.urlEncode(EncodingUtil.base64Encode(encrypted), 'UTF-8');
        return encryptedString;
    }
    
    @AuraEnabled
    public static List<InstructionWrapper> fetchInstructions(String pdId) {
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT CustomerProfileId__c,PartnerProfileId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];

        String decryptedPDId = SC_SOCC_RUN_BOOK.decryptPDId(pdId);
        List<InstructionWrapper> instructionWrapperList = new List<InstructionWrapper>();
        InstructionWrapper instWrapperRec;
        for(Instruction__c eachInst : [select id,name,Case__c,Case__r.CaseNumber,Case__r.AKAM_Case_Id__c,Instructions_Type__c,Status__c,Value__c,
                                       Handler__r.name,createdbyid,createdby.name,createddate from Instruction__c where (createdby.profileId =: communityMdt.CustomerProfileId__c OR createdby.profileId =: communityMdt.PartnerProfileId__c) AND Handler__c IN (Select id from Handler__c where Policy_Domain__r.AKAM_Policy_Domain_ID__c =: decryptedPDId) order by name desc]){
            instWrapperRec = new InstructionWrapper();
            
            instWrapperRec.instructionRecDisplayName = '['+eachInst.Name+'] for ['+eachInst.Handler__r.name+']';
            instWrapperRec.instructionRec = eachInst;
            instWrapperRec.instructionRecId = eachInst.Id;
            instWrapperRec.instructionRecName = eachInst.Name;
            instWrapperRec.instructionRecUrl = '/lightning/r/Instruction__c/' + eachInst.Id + '/view';
            instWrapperRec.instructionRecCaseId = eachInst.Case__c;
            instWrapperRec.instructionRecCaseNumber = eachInst.Case__r.CaseNumber;
            instWrapperRec.instructionRecAKAMCaseNumber = eachInst.Case__r.AKAM_Case_Id__c;
            instWrapperRec.instructionRecCaseUrl = '/lightning/r/Instruction__c/' + eachInst.Case__c + '/view';
            instWrapperRec.instructionRecType = eachInst.Instructions_Type__c;
            instWrapperRec.instructionRecStatus = eachInst.Status__c;
            instWrapperRec.instructionRecCreatedBy = eachInst.Createdby.Name;
            instWrapperRec.instructionRecCreatedDate = String.valueOf((eachInst.CreatedDate).format('MM/dd/yyyy hh:mm a'));
            instWrapperRec.instructionRecValue = eachInst.Value__c;
            instWrapperRec.instructionRecValueDisplay = eachInst.Value__c.stripHtmlTags();
            instWrapperRec.instructionHandlerRecName = eachInst.Handler__r.name;
            instructionWrapperList.add(instWrapperRec);
        }
        return instructionWrapperList;
    }
    
}