/*---------------------------------------------------------------------------------
    Class name          :   SC_QualityCoaching_RCA_Handler
    Test Class          :   SC_RCA_AllUseCase_TC
    Author              :   Bhavesh
    Created             :   
    JIRA                :   ESESP-3590
    Purpose             :   Quality Coaching Create/Edit
             
    Last Modified         Developer                 Purpose            
    ============= ========================         ==========

* --------------------------------------------------------------------------------*/
public class SC_QualityCoaching_RCA_Handler {
    //Criteria Wrapper
    public class CriteriaWrapper
    {
        @AuraEnabled public SC_KCS_Scorecard_Criteria__c qualityCoachingCriteria;
        @AuraEnabled public Integer maxScore;
        @AuraEnabled public Integer criteriaMet;
    }
    
    
    
    //Wrapper to hold Quality Coaching and Criteria Details
    public class QualityCoachingWrapper
    {
        @AuraEnabled public SC_KCS_Scorecard__c qualityCoaching;
        @AuraEnabled public List<CriteriaWrapper> tableData;
        @AuraEnabled public Boolean isIraptAdmin;
        @AuraEnabled public Boolean isWrongUser;
        @AuraEnabled public Boolean isIRAPTUser;
        @AuraEnabled public Integer maxScore;
         
    }
    
    //Method to take construct values to be displayed for Quality Coaching and Criteria Details in the dashboard  based on the user and parent record id or QC id
    @AuraEnabled
    public static QualityCoachingWrapper getRecords(String sourceId, String sourceType, String parentType){
        //String to store current user id
        String currentUserId=UserInfo.getUserId();
        
        // variable for getting existing Quality Coaching for logged in user if any
        List<SC_KCS_Scorecard__c> existingQCRec = new List<SC_KCS_Scorecard__c>();
        
        //variable for getting existing Quality Coaching Criteria for logged in user if any
        List<SC_KCS_Scorecard_Criteria__c> lExistingQCCriteriaRec = new List<SC_KCS_Scorecard_Criteria__c>();
         
        //Stores the details of latest Quality Coaching fields like notes , etc in case of edit. For first time creation, set with  default values.Used for Insert+Update
        SC_KCS_Scorecard__c latestQCRec = new SC_KCS_Scorecard__c();
        
        
        //Stores the details of table data to be displayed which contains latest Quality theme and Criteria. For first time creation, set with  default values.Used for Insert+Update
        List<CriteriaWrapper> lCriteriaWrapper = new List<CriteriaWrapper>();
        
        //Contains latest return value. Combination of Quality Coaching and List of criteria data returned to Lightning Component
        QualityCoachingWrapper latestQualityCoachingWrapperRec = new QualityCoachingWrapper();
        latestQualityCoachingWrapperRec.isIRAPTUser = False;
        latestQualityCoachingWrapperRec.isWrongUser = False;
        latestQualityCoachingWrapperRec.isIraptAdmin = False;
        //Check whether User is authorized to Create Quality Coaching records
        Id caseOwnerId;
        Boolean isIraptAdmin = False;
        
        try{
            
            User usr = [Select Id, SC_SI_IRAPT_User__c FROM User WHERE Id =: currentUserId];
            if( usr.SC_SI_IRAPT_User__c ){
                latestQualityCoachingWrapperRec.isIRAPTUser = True;
                //check if user is irapt admin
                List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>([SELECT  Id FROM PermissionSetAssignment WHERE 
                                                AssigneeId =: UserInfo.getuserId() and PermissionSet.Name = 'SC_SI_Service_Incidents_IRAPT_Admin_User']);
                if( psa.size() > 0 ){
                    latestQualityCoachingWrapperRec.isIraptAdmin = True;
                    latestQualityCoachingWrapperRec.isIRAPTUser = False;
                    isIraptAdmin = True;
                }
                //Get existing record, if any
                if(sourceType == 'Quality Coaching')
                    existingQCRec = [SELECT Id, Notes__c, Case__r.OwnerId, CreatedByid FROM SC_KCS_Scorecard__c WHERE Id =:sourceId LIMIT 1];
                else if( isIraptAdmin )
                    existingQCRec = [SELECT Id, Notes__c, Case__r.OwnerId, CreatedByid FROM SC_KCS_Scorecard__c WHERE Case__c =:sourceId AND CreatedById =:currentUserId LIMIT 1];
                else if( !isIraptAdmin ){
                    existingQCRec = [SELECT Id, Notes__c, Case__r.OwnerId, CreatedByid FROM SC_KCS_Scorecard__c WHERE Case__c =:sourceId AND OwnerId =:currentUserId LIMIT 1];
                }
                    //set case OwnerId
                if(existingQCRec.size() != 0)
                    caseOwnerId = existingQCRec[0].Case__r.OwnerId;
                else
                    caseOwnerId = [Select Id, OwnerId from Case where Id =:sourceId LIMIT 1].OwnerId;
                
                if(existingQCRec.size() != 0){
                        lExistingQCCriteriaRec = [SELECT Id,Score_Rca__c,Max_Score_RCA__c FROM SC_KCS_Scorecard_Criteria__c where KCS_Scorecard__c =:existingQCRec[0].Id ORDER BY Criteria_Number__c];
                    }
                    
                //Getting default value from custom metadata for QC criteria
                List<SC_KCS_Scorecard_Criteria_Settings__mdt> lCriteriaMetadata =[SELECT Id, Criteria_Name__c, Criteria_Number__c, Parent_Object__c, Max_Score__c FROM SC_KCS_Scorecard_Criteria_Settings__mdt WHERE Parent_Object__c = 'RCA' ORDER BY Criteria_Number__c];
                
                //Setting latest Quality Coaching record
                latestQCRec.Id = (existingQCRec.size() == 0) ? null : existingQCRec[0].Id;
                latestQCRec.Notes__c = (existingQCRec.size() == 0) ? null : existingQCRec[0].Notes__c;
                
                //--------------------------------Start of Populating Table Data------------------------
                Integer maxScore = 0;
                //Setting latest Quality Coaching Criteria records
                for(Integer i=0; i<lCriteriaMetadata.size(); i++){
                    //Each SC_KCS_Scorecard_Criteria__c record
                    SC_KCS_Scorecard_Criteria__c eachCriteria = new SC_KCS_Scorecard_Criteria__c();
                    eachCriteria.Criteria_Name__c = lCriteriaMetadata[i].Criteria_Name__c;
                    eachCriteria.Max_Score_RCA__c = lCriteriaMetadata[i].Max_Score__c;
                    eachCriteria.Criteria_Number__c = lCriteriaMetadata[i].Criteria_Number__c;
                    eachCriteria.Score_Rca__c = (lExistingQCCriteriaRec.size()>0 && lExistingQCCriteriaRec[i].Score_Rca__c != NULL) ? lExistingQCCriteriaRec[i].Score_Rca__c : 0;
                    maxScore += (lExistingQCCriteriaRec.size()>0 && lExistingQCCriteriaRec[i].Score_Rca__c != NULL) ? (Integer)lCriteriaMetadata[i].Max_Score__c : 0;//sum of all the criteria max score.
                    //Each CriteriaWrapper instance
                    CriteriaWrapper eachCriteriaWrapper = new CriteriaWrapper();
                    eachCriteriaWrapper.qualityCoachingCriteria = eachCriteria;
                    //eachCriteriaWrapper.maxScore = maxScore;
                    lCriteriaWrapper.add(eachCriteriaWrapper);
                    
                    //lLatestQCCriteriaRec.add(eachCriteria);
                }
                
                //Setting wrapper record
                latestQualityCoachingWrapperRec.qualityCoaching = new SC_KCS_Scorecard__c();
                latestQualityCoachingWrapperRec.qualityCoaching = latestQCRec;
                latestQualityCoachingWrapperRec.tableData = new List<CriteriaWrapper>();
                latestQualityCoachingWrapperRec.tableData.addAll(lCriteriaWrapper);
                latestQualityCoachingWrapperRec.maxScore = maxScore;
                
            } else {
                latestQualityCoachingWrapperRec.isWrongUser = True;
            }
            
            
            
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return latestQualityCoachingWrapperRec;
    }
    
    //Method to Save Quality Coaching and Criteria records(Upsert)
    @AuraEnabled
    public static void updateQualityCoachingDetails(String tableData, String notes, String sourceId, String sourceType, String parentType, Integer maxScore,  Integer criteriaMetNumber){
        //------------------ Start of Scorecard Upsertion --------------------------
        //String to store current user id
        String currentUserId=UserInfo.getUserId();
        
        
        //Getting Case RecordTypeId
        Id caseRecTypeId = Schema.SObjectType.SC_KCS_Scorecard__c.getRecordTypeInfosByName().get('RCA Request').getRecordTypeId();
        
        //Stores parent Case Id
        String caseId;
        
        // variable for getting existing Quality Coaching for logged in user if any
        List<SC_KCS_Scorecard__c> existingQCRec = new List<SC_KCS_Scorecard__c>();
        
        //Stores the details of latest Quality Coaching fields like notes , etc in case of edit
        SC_KCS_Scorecard__c latestQCRec = new SC_KCS_Scorecard__c();
        //Get existing record, if any
        if(sourceType == 'Quality Coaching'){
            existingQCRec = [SELECT Id, Case__c, Case__r.OwnerId, Notes__c,Service_Incident__c FROM SC_KCS_Scorecard__c WHERE Id =:sourceId LIMIT 1];
            caseId = existingQCRec[0].Case__c;
        }
        else{
            existingQCRec = [SELECT Id, Case__c, Case__r.OwnerId, Notes__c, Service_Incident__c FROM SC_KCS_Scorecard__c WHERE Case__c =:sourceId AND CreatedById =:currentUserId LIMIT 1];
            caseId = sourceId;
        }
            
        Case cs = [Select Id, OwnerId, Service_Incident__c,Service_Incident__r.BIL__c, Service_Incident__r.OwnerId FROM Case WHERE ID =: caseId];
        User u = new User();
        if( cs.Service_Incident__c != NULL && cs.Service_Incident__r.OwnerId != NULL && string.valueOf(cs.Service_Incident__r.OwnerId).startsWith('005')){
            u = [Select Id, Manager__c FROM User WHERE Id =: cs.Service_Incident__r.OwnerId];
        }
        latestQCRec.Service_Incident__c = cs.Service_Incident__c;
        if(existingQCRec.size() > 0){
            latestQCRec.Id = existingQCRec[0].Id;
            //caseId = existingQCRec[0].Case__c;
        }
        else{
            latestQCRec.RecordTypeId = caseRecTypeId;
            latestQCRec.Case__c = sourceId;
            

        }
        if( cs.Service_Incident__c != NULL && cs.Service_Incident__r.BIL__c != NULL )
            latestQCRec.CIM_Name__c = cs.Service_Incident__r.BIL__c;
        latestQCRec.CIM_Manager__c = (u.id != NULL) ? u.Manager__c : '';
        latestQCRec.Criteria_Met_RCA__c = criteriaMetNumber;
        latestQCRec.maximum_Score__c = maxScore;
        latestQCRec.Notes__c = notes;
        latestQCRec.OwnerId = cs.OwnerId;
        
        try{
            upsert latestQCRec;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        //------------------ End of Scorecard Upsertion -----------------------------

        //------------------ Start of Scorecard Criteria Upsertion ------------------
        //String to store Quality Coaching Id
        String qualityCoachingId = latestQCRec.Id;
        
        //List of existing Quality Coaching Criteria values previously created by the user
        List<SC_KCS_Scorecard_Criteria__c> lExistingQCCriteriaRec =[SELECT Id FROM SC_KCS_Scorecard_Criteria__c where  KCS_Scorecard__c =:qualityCoachingId ORDER BY Criteria_Number__c];     

        //Converting List of tableData Data collected in JSON format from the Lightning component into a List of SC_KCS_Scorecard_Criteria__c
        List<CriteriaWrapper> lCriteriaWrapper = (List<CriteriaWrapper>) System.JSON.deserializeStrict(tableData, List<CriteriaWrapper>.Class);
        
        //List to store latest values of Qulity Coaching Criteria records for insert/update
        List<SC_KCS_Scorecard_Criteria__c> lLatestQCCriteriaRec = new List<SC_KCS_Scorecard_Criteria__c>();
        
        for(CriteriaWrapper eachTDRec : lCriteriaWrapper){
            //lLatestQCCriteriaRec.addAll(eachTDRec.lQualityCoachingCriteria);
                
                lLatestQCCriteriaRec.add(eachTDRec.qualityCoachingCriteria);
            
        }
        
        
        
        for (Integer i=0; i<lLatestQCCriteriaRec.size(); i++){
            //If criteria record exists for the Quality Coaching then set Criteria Id(Updation)
            if(lExistingQCCriteriaRec.size() != 0)
                lLatestQCCriteriaRec[i].Id = lExistingQCCriteriaRec[i].Id;
            //If criteria record does not exist for the Quality Coaching then set QC Id(Insertion)
            else
                lLatestQCCriteriaRec[i].KCS_Scorecard__c = qualityCoachingId;
            
        }

        try{        
            upsert lLatestQCCriteriaRec;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        //------------------ End of Scorecard Criteria Upsertion --------------------
        
        //Update Has Quality Reviewed field on Case
        if(!String.isBlank(caseId)){
            
            
            //Update Has Quality Reviewed field on Case
            Case caseRec = new Case();
            caseRec.Id = caseId;
            caseRec.Has_Quality_Review__c = True;
            caseRec.Validation_Override__c = True;
            try{
                update caseRec;
            }catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    

}