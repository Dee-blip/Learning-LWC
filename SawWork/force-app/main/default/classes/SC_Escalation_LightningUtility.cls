/*
Author          : Pinkesh Rathore
Description     : Apex Controller for Escalation Functionality 
Test Class - SC_Akatec_Lightning_TC

Date                        Developer             JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
08 February 2019        Pinkesh R        ESESP-1900     Akatec Case Lightning Migration
20 July 2019            Sumukh SS        ESESP-2451     Getting Escalation RecordType Name from ID
12 May 2020             Sharath          ESESP-3546     Removing reference to BOCC Stability and adding BOCC Consultancy
------------------------------------------------------------------------------------------------------------------
*/

public class SC_Escalation_LightningUtility {
    //Method-1: For Accept Case button
    @AuraEnabled
    public static String acceptCase(String escId){
        System.debug('-------- escId: ' + escId);
        Engagement_Request__c escRecord = [Select Id, RecordTypeId, RecordType.Name, IsRejected__c, IS_Accept_Case_Clicked__c, Request_Status__c, Assigned_To__c, Accepted_Date__c from Engagement_Request__c where Id = :escId limit 1];
        List<String> recordTypeNames = new List<String>();
        //ESESP-3546: Removing reference to BOCC Stability and adding BOCC Consultancy. Moving the record type names to metadata
        for(SC_Utility__mdt utilRec: [Select id, Value__c  from SC_Utility__mdt where DeveloperName like 'Escalation_Record_Types%' and Active__c = true])
        {
            recordTypeNames.addAll(utilRec.Value__c.split(','));
        }
        System.debug('-------- escRecord: ' + escRecord);
        //if((escRecord.RecordType.Name == 'Stability Engineering' || escRecord.RecordType.Name == 'CCare Technical Escalation' || escRecord.RecordType.Name == 'CCare Mgmt Escalation' || 
        //   escRecord.RecordType.Name == 'BOCC Stability Engineering' || escRecord.RecordType.Name == 'Carrier Escalation' || escRecord.RecordType.Name == 'Enterprise Engineering' || 
        //   escRecord.RecordType.Name == 'Octoshape Engineering')
        //   && escRecord.IsRejected__c == FALSE && escRecord.IS_Accept_Case_Clicked__c == FALSE)
        if( recordTypeNames.contains(escRecord.RecordType.Name) && 
                escRecord.IsRejected__c == FALSE && 
                escRecord.IS_Accept_Case_Clicked__c == FALSE)
            
        {
               escRecord.Request_Status__c = 'Accepted'; 
                escRecord.Assigned_To__c = UserInfo.getUserId(); 
                escRecord.IS_Accept_Case_Clicked__c = true; 
                if(escRecord.Accepted_Date__c == null) 
                  escRecord.Accepted_Date__c = System.now();
               
               try{
                   update escRecord;
                   return 'success';
               }catch(Exception e){
                   return e.getMessage();
               }
        }
        else
        {
            return 'Sorry! Cannot accept. This escalation is either already accepted or rejected. If not, please check for the valid Record Type.';
        }
        //return 'Failure';
    }
    
    //Method-2 For Reject Button on Escalation
    @AuraEnabled
    public static String rejectEscalation(String escId, String rejectReason){
        try{
            Engagement_Request__c escRecord = [Select Id, RecordTypeId, RecordType.Name, IsRejected__c, Request_Status__c, Rejection_Reason__c from Engagement_Request__c where Id = :escId limit 1];
            escRecord.Request_Status__c = 'Rejected';
            escRecord.IsRejected__c = TRUE;
            escRecord.Rejection_Reason__c = rejectReason;
            update escRecord;
            return 'success';
        }catch(Exception e){
            return e.getMessage();
        }
        
    }
  
    //Method-3 get parent case Id for ADD LOE button
    @AuraEnabled
    public static String getParentCaseId(String escId){
        String caseId = [Select Id, Case__c from Engagement_Request__c where Id =:escId limit 1].Case__c;
        return caseId;
    }
    
    //method-4 get parent case details for New External Team button
    @AuraEnabled
    public static String getEscDetails(String escId){
        Engagement_Request__c escRec= [Select Id, Case__c, RecordTypeId, Case__r.CaseNumber from Engagement_Request__c where Id =:escId limit 1];
        String externalTeamRecTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId();
        String escDetail = '{"caseId": "'+ escRec.Case__c + '", "caseNumber": "' + escRec.Case__r.CaseNumber + '", "recordTypeId": "' + externalTeamRecTypeId + '"}';
        return escDetail;
    }
    
    //method-5 Getting the Escalation RecordType Name based on ID
    @AuraEnabled
    public static string getEscRecordTypeName(string EscRecordTypeId)
    {
     
        string recordtypename = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosById().get(EscRecordTypeId).getname();
        System.debug('RECORD TYPE NAME : ' + recordtypename);
        return recordtypename;
    }
    
    @AuraEnabled
    public static Id getDefaultEscRecType()
    {
        Schema.DescribeSObjectResult dsr = Engagement_Request__c.SObjectType.getDescribe();
        Schema.RecordTypeInfo defaultRecordType;
        for(Schema.RecordTypeInfo rti : dsr.getRecordTypeInfos()) 
        {
            if(rti.isDefaultRecordTypeMapping()) 
            {
                defaultRecordType = rti;
            }
        }
        System.debug('RECORD TYPE ID : ' + defaultRecordType.getRecordTypeId());
        return defaultRecordType.getRecordTypeId();
    }
    
    
}