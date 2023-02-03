/*---------------------------------------------------------------------------------
    Class name          :   SC_QualityCoaching_Escalation_Handler
    Test Class          :   SC_QualityCoaching_TC
    Author              :   Pinkesh
    Created             :   22-Sep-19
    JIRA                :   ESESP-2316
    Purpose             :   Quality Coaching Create/Edit
             
    Last Modified         Developer                 Purpose            
    ============= ========================         ==========

* --------------------------------------------------------------------------------*/
public class SC_QualityCoaching_Escalation_Handler {
    //Criteria Wrapper
    public class CriteriaWrapper
    {
        @AuraEnabled public SC_KCS_Scorecard_Criteria__c qualityCoachingCriteria;
        @AuraEnabled public List<String> lToolTip;
    }
    
    //Wrapper class to form the table data structure on UI
    public class TableDataWrapper
    {
        @AuraEnabled public String qualityTheme;
        @AuraEnabled public List<CriteriaWrapper> lQualityCoachingCriteria;
    }
    
    //Wrapper to hold Quality Coaching and Criteria Details
    public class QualityCoachingWrapper
    {
        @AuraEnabled public SC_KCS_Scorecard__c qualityCoaching;
        @AuraEnabled public List<TableDataWrapper> tableData;
        @AuraEnabled public Boolean isUserAuthorized;
        @AuraEnabled public Boolean isWrongUser;
         
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
        List<TableDataWrapper> lLatestTableData = new List<TableDataWrapper>();
        
        //Contains latest return value. Combination of Quality Coaching and List of criteria data returned to Lightning Component
        QualityCoachingWrapper latestQualityCoachingWrapperRec = new QualityCoachingWrapper();
        
        //Check whether User is authorized to Create Quality Coaching records
        Id escOwnerId;
        
        try{
            //Get existing record, if any
            if(sourceType == 'Quality Coaching')
                existingQCRec = [SELECT Id,Notes__c, Escalation__r.OwnerId, CreatedByid FROM SC_KCS_Scorecard__c WHERE Id =:sourceId LIMIT 1];
            else
                existingQCRec = [SELECT Id,Notes__c, Escalation__r.OwnerId, CreatedByid FROM SC_KCS_Scorecard__c WHERE Escalation__c =:sourceId AND CreatedById =:currentUserId LIMIT 1];
            
            //set esc OwnerId
            if(existingQCRec.size() != 0)
                escOwnerId = existingQCRec[0].Escalation__r.OwnerId;
            else
                escOwnerId = [Select Id, OwnerId from Engagement_Request__c where Id =:sourceId LIMIT 1].OwnerId;
            
            //Check if User is authorized to Created/Edit Quality Coaching record
            if(escOwnerId == currentUserId)
                latestQualityCoachingWrapperRec.isUserAuthorized = true;
            else
                latestQualityCoachingWrapperRec.isUserAuthorized = false;
            
            //Check if User is not trying to Edit somebody else's QC recod
            if(existingQCRec.size() > 0 && existingQCRec[0].CreatedByid != currentUserId)
                latestQualityCoachingWrapperRec.isWrongUser = true;
            else
                latestQualityCoachingWrapperRec.isWrongUser = false;
            
            if (latestQualityCoachingWrapperRec.isUserAuthorized && !latestQualityCoachingWrapperRec.isWrongUser)
            {   
                if(existingQCRec.size() != 0){
                    lExistingQCCriteriaRec = [SELECT Id, Response__c FROM SC_KCS_Scorecard_Criteria__c where KCS_Scorecard__c =:existingQCRec[0].Id ORDER BY Criteria_Number__c];
                }
                
                //Getting default value from custom metadata for QC criteria
                List<SC_KCS_Scorecard_Criteria_Settings__mdt> lCriteriaMetadata =[SELECT Id, Criteria_Name__c, Criteria_Number__c, Parent_Object__c, Points__c, Quality_Theme__c, Quality_Theme_Number__c, Tool_Tip__c FROM SC_KCS_Scorecard_Criteria_Settings__mdt WHERE Parent_Object__c = 'Escalation' ORDER BY Criteria_Number__c];
                
                //Setting latest Quality Coaching record
                latestQCRec.Id = (existingQCRec.size() == 0) ? null : existingQCRec[0].Id;
                latestQCRec.Notes__c = (existingQCRec.size() == 0) ? null : existingQCRec[0].Notes__c;
                
                //--------------------------------Start of Populating Table Data------------------------
                
                //Setting latest Quality Coaching Criteria records
                for(Integer i=0; i<lCriteriaMetadata.size(); i++){
                    //Each SC_KCS_Scorecard_Criteria__c record
                    SC_KCS_Scorecard_Criteria__c eachCriteria = new SC_KCS_Scorecard_Criteria__c();
                    eachCriteria.Criteria_Name__c = lCriteriaMetadata[i].Criteria_Name__c;
                    eachCriteria.Criteria_Number__c = lCriteriaMetadata[i].Criteria_Number__c;
                    eachCriteria.Points__c = lCriteriaMetadata[i].Points__c;
                    eachCriteria.Quality_Theme__c = lCriteriaMetadata[i].Quality_Theme__c;
                    eachCriteria.Tool_Tip__c = lCriteriaMetadata[i].Tool_Tip__c;
                    eachCriteria.Response__c = (lExistingQCCriteriaRec.size() ==0) ? 'Need Fix' : lExistingQCCriteriaRec[i].Response__c;
                    
                    //List of tool tips for each Criteria
                    List<String> lToolTip = getListToolTip(lCriteriaMetadata[i].Tool_Tip__c);
                    
                    //Each CriteriaWrapper instance
                    CriteriaWrapper eachCriteriaWrapper = new CriteriaWrapper();
                    eachCriteriaWrapper.qualityCoachingCriteria = eachCriteria;
                    eachCriteriaWrapper.lToolTip = lToolTip;
                    
                    Integer tableDataIndex = (Integer) lCriteriaMetadata[i].Quality_Theme_Number__c - 1;
                    System.debug(lLatestTableData.size());
                    if(lLatestTableData.size() < tableDataIndex+1){
                        TableDataWrapper tableDataRec = new TableDataWrapper();
                        tableDataRec.qualityTheme = lCriteriaMetadata[i].Quality_Theme__c;
                        tableDataRec.lQualityCoachingCriteria = new List<CriteriaWrapper>();
                        tableDataRec.lQualityCoachingCriteria.add(eachCriteriaWrapper);
                        lLatestTableData.add(tableDataRec);
                    }
                    else{
                        TableDataWrapper tableDataRec = lLatestTableData[tableDataIndex];
                        if(tableDataRec.lQualityCoachingCriteria == null)
                            tableDataRec.lQualityCoachingCriteria = new List<CriteriaWrapper>();
                        tableDataRec.lQualityCoachingCriteria.add(eachCriteriaWrapper);
                    }
                    
                    //lLatestQCCriteriaRec.add(eachCriteria);
                }
                
                //Setting wrapper record
                latestQualityCoachingWrapperRec.qualityCoaching = new SC_KCS_Scorecard__c();
                latestQualityCoachingWrapperRec.qualityCoaching = latestQCRec;
                latestQualityCoachingWrapperRec.tableData = new List<TableDataWrapper>();
                latestQualityCoachingWrapperRec.tableData.addAll(lLatestTableData);
            }
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return latestQualityCoachingWrapperRec;
    }
    
    //Method to Save Quality Coaching and Criteria records(Upsert)
    @AuraEnabled
    public static void updateQualityCoachingDetails(String tableData, String notes, String sourceId, String sourceType, String parentType){
        //------------------ Start of Scorecard Upsertion --------------------------
        //String to store current user id
        String currentUserId=UserInfo.getUserId();
        
        //Getting Escalation RecordTypeId
        Id escalationRecTypeId = Schema.SObjectType.SC_KCS_Scorecard__c.getRecordTypeInfosByName().get('Escalation Quality').getRecordTypeId();
        
        //Stores parent Escalation Id
        String escalationId;
        
        // variable for getting existing Quality Coaching for logged in user if any
        List<SC_KCS_Scorecard__c> existingQCRec = new List<SC_KCS_Scorecard__c>();
        
        //Stores the details of latest Quality Coaching fields like notes , etc in case of edit
        SC_KCS_Scorecard__c latestQCRec = new SC_KCS_Scorecard__c();
        
        //Get existing record, if any
        if(sourceType == 'Quality Coaching')
            existingQCRec = [SELECT Id, Escalation__c, Escalation__r.CreatedById, Notes__c FROM SC_KCS_Scorecard__c WHERE Id =:sourceId LIMIT 1];
        else
            existingQCRec = [SELECT Id, Escalation__c, Escalation__r.CreatedById, Notes__c FROM SC_KCS_Scorecard__c WHERE Escalation__c =:sourceId AND CreatedById =:currentUserId LIMIT 1];
            
        if(existingQCRec.size() > 0){
            latestQCRec.Id = existingQCRec[0].Id;
            //escalationId = existingQCRec[0].Escalation__c;
        }
        else{
            latestQCRec.RecordTypeId = escalationRecTypeId;
            latestQCRec.Escalation__c = sourceId;
            escalationId = sourceId;
        }
        latestQCRec.Notes__c = notes;
        
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
        List<TableDataWrapper> lLatestTableData = (List<TableDataWrapper>) System.JSON.deserializeStrict(tableData, List<TableDataWrapper>.Class);
        
        //List to store latest values of Qulity Coaching Criteria records for insert/update
        List<SC_KCS_Scorecard_Criteria__c> lLatestQCCriteriaRec = new List<SC_KCS_Scorecard_Criteria__c>();
        
        for(TableDataWrapper eachTDRec : lLatestTableData){
            //lLatestQCCriteriaRec.addAll(eachTDRec.lQualityCoachingCriteria);
            for(CriteriaWrapper eachCriteriaWrapper : eachTDRec.lQualityCoachingCriteria){
                lLatestQCCriteriaRec.add(eachCriteriaWrapper.qualityCoachingCriteria);
            }
            
        }
        
        
        
        for (Integer i=0; i<lLatestQCCriteriaRec.size(); i++){
            //If criteria record exists for the Quality Coaching then set Criteria Id(Updation)
            if(lExistingQCCriteriaRec.size() != 0)
                lLatestQCCriteriaRec[i].Id = lExistingQCCriteriaRec[i].Id;
            //If criteria record does not exist for the Quality Coaching then set QC Id(Insertion)
            else
                lLatestQCCriteriaRec[i].KCS_Scorecard__c = qualityCoachingId;
            
        }

        System.debug('--------lLatestQCCriteriaRec' + lLatestQCCriteriaRec);   
        try{
            upsert lLatestQCCriteriaRec;
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        //------------------ End of Scorecard Criteria Upsertion --------------------
        
        //Update Has Quality Reviewed field on Escalation
        if(!String.isBlank(escalationId)){
            //Update Escalation Creator's Manager Email Id on Quality Coaching Record
            latestQCRec.Engineer_Managers_Email__c = [SELECT Id, CreatedBy.Manager.Email FROM Engagement_Request__c where Id = :escalationId limit 1].CreatedBy.Manager.Email;
            try{
                update latestQCRec;
            }catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
            
            //Update Has Quality Reviewed field on Escalation
            Engagement_Request__c escRec = new Engagement_Request__c();
            escRec.Id = escalationId;
            escRec.Has_Quality_Review__c = True;
            escRec.Validation_Override__c = True;
            try{
                update escRec;
            }catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }
    
    //Split and get list of tool tips
    public static List<String> getListToolTip(String toolTip){
        List<String> lToolTip = toolTip.split('#');
        return lToolTip;
    }

}