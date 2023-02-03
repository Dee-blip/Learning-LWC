/*---------------------------------------------------------------------------------
    Class name          : SC_KCS_Scorecard_Dashboard
    Test Class          :   SC_KCS_TestClass
    Author              :   Supreeth
    Created             :   18 Feb 2019
    JIRA                :   ESESP-1779
    Purpose             :  Quality Coaching Create/Edit
             
    Last Modified         Developer                 Purpose            
    ============= ========================         ==========
    22-Sep-19       Pinkesh                     ESESP-2316: Quality Coaching Create/Edit button
* --------------------------------------------------------------------------------*/
public class SC_KCS_Scorecard_Dashboard {
    
    //Wrapper to hold KCS Scorecard and Criteria Details
    public class KCS_Wrapper
    {
        
        @AuraEnabled public SC_KCS_Scorecard__c KCS_Scorecard;
        @AuraEnabled public List<SC_KCS_Scorecard_Criteria__c> KCS_Scorecard_Criteria;
        @AuraEnabled public Boolean Is_User_Authorized;
        @AuraEnabled public Boolean Published;
         
    }
    
    //Method to take construct values to be displayed for Scorecard and KCS_Scorecard_Criteria in the dashboard  based on the user and knowledge record id or Scorecard id
    @AuraEnabled
    public static KCS_Wrapper Calc_SC_KCS_Scorecard_Details(String sourceId, String sourceType, String parentType)
    {   
        //String to store current user id
        String CurrentUserId=UserInfo.getUserId();
        
        //String to store Scorecard Id in case of edit
        String Scorecard_Id;
         
        //Stores the details of Scorecard fields like notes , etc in case of edit. For first time creation, set with  default values.Used for Insert+Update
        SC_KCS_Scorecard__c scorecard_Insert_Update= new SC_KCS_Scorecard__c();
        
        //Stores the details of Criteria fields like notes , etc in case of edit. For first time creation, set with  default values.Used for Insert+Update
        List<SC_KCS_Scorecard_Criteria__c> scorecardCriteriaList = new List<SC_KCS_Scorecard_Criteria__c>();
        
        //KCS_Wrapper_Insert_Update contains the return value. Combination of Scorecard and List of criteria data returned to Lightning Component
        KCS_Wrapper KCS_Wrapper_Insert_Update= new KCS_Wrapper();
        
        // variable for getting existing scorecard for logged in user 
        List<SC_KCS_Scorecard__c> get_Existing_Scorecard= new  List<SC_KCS_Scorecard__c>();
        
        //variable for getting existing scorecard Criteria List for logged in user  
        List<SC_KCS_Scorecard_Criteria__c> get_Existing_Scorecard_Criteria_List = new List<SC_KCS_Scorecard_Criteria__c>();
        
        //Check whether User is authorized to Create Scorecard
        User loggedInUser = [SELECT KCS_Level__c, Profile.Name FROM User WHERE Id =:CurrentUserId LIMIT 1];
        Boolean Is_Published=true;
        String publish_status; 
        
        if(sourceType == 'Knowledge')
        {
          publish_status = [SELECT PublishStatus from Knowledge__kav where id=:sourceId LIMIT 1][0].PublishStatus;
            if(publish_status == 'Draft' || publish_status == 'Archived'){
                Is_Published =false;
            }
        }
            
        if (loggedInUser.KCS_Level__c == 'KCS Coach' || loggedInUser.KCS_Level__c == 'KCS KDE' || loggedInUser.Profile.Name.contains('Support - Tech Support Manager') || loggedInUser.Profile.Name.contains('Technical Relationship Engineer'))
        {   
            KCS_Wrapper_Insert_Update.Is_User_Authorized=true;
            KCS_Wrapper_Insert_Update.Published=Is_Published;
            if(Is_Published)
            {
          
            
            //If the component is called from Knowledge Page (record id starts with ka), set appropriate Scorecard_Id
            if(sourceType == 'Knowledge'){
                
                get_Existing_Scorecard=[SELECT Id,Notes__c FROM SC_KCS_Scorecard__c where CreatedById =:CurrentUserId AND Knowledge__c =:sourceId];
                
            }
            
            //If the component is called from Scorecard Page (record id starts with aG), set appropriate Scorecard_Id
            else if (sourceType == 'Quality Coaching'){
                
                get_Existing_Scorecard=[SELECT Id,Notes__c  FROM SC_KCS_Scorecard__c where Id =:sourceId];
                
            }
            
            //Get scorecard id in case of Edit
            if(get_Existing_Scorecard.size() != 0)
            {
                Scorecard_Id=get_Existing_Scorecard[0].Id;
                
                //Calculations for getting criteria based on the Scorecard Id
                get_Existing_Scorecard_Criteria_List=[SELECT Id,Fixed__c,Response__c FROM SC_KCS_Scorecard_Criteria__c where KCS_Scorecard__c =:Scorecard_Id ORDER BY Criteria_Number__c] ;
                
            }
            
            //Getting default value from custom metadata for Scorecard criteria
            List<SC_KCS_Scorecard_Criteria_Settings__mdt> criteriaList_metadata =[SELECT Criteria_Name__c, Criteria_Number__c, Points__c, Parent_Object__c FROM SC_KCS_Scorecard_Criteria_Settings__mdt WHERE Parent_Object__c = 'Knowledge' ORDER BY Criteria_Number__c];
            
            
            //Calculations for getting criteria List .Insert+ Update
            scorecard_Insert_Update.Id= (get_Existing_Scorecard.size() == 0) ? null : get_Existing_Scorecard[0].Id;
            
            scorecard_Insert_Update.Notes__c=(get_Existing_Scorecard.size() == 0) ? null: get_Existing_Scorecard[0].Notes__c;
            
            for(Integer i=0;i<criteriaList_metadata.size();i++){
                SC_KCS_Scorecard_Criteria__c scorecardCriteria = new SC_KCS_Scorecard_Criteria__c();
                scorecardCriteria.Criteria_Name__c = criteriaList_metadata[i].Criteria_Name__c; 
                scorecardCriteria.Criteria_Number__c = criteriaList_metadata[i].Criteria_Number__c;
                scorecardCriteria.Points__c = criteriaList_metadata[i].Points__c;
                scorecardCriteria.Response__c=(get_Existing_Scorecard.size() == 0) ? '' :get_Existing_Scorecard_Criteria_List[i].Response__c;
                scorecardCriteria.Fixed__c=(get_Existing_Scorecard.size() == 0) ? false :get_Existing_Scorecard_Criteria_List[i].Fixed__c;
                scorecardCriteriaList.add(scorecardCriteria);
            }
            
            // Populate the KCS_Scorecard_Criteria part of the wrapper instance
            KCS_Wrapper_Insert_Update.KCS_Scorecard_Criteria= new List<SC_KCS_Scorecard_Criteria__c>();
            KCS_Wrapper_Insert_Update.KCS_Scorecard_Criteria.addAll(scorecardCriteriaList);
            
            // Populate the KCS_Scorecard part of the wrapper instance
            KCS_Wrapper_Insert_Update.KCS_Scorecard = new SC_KCS_Scorecard__c();
            KCS_Wrapper_Insert_Update.KCS_Scorecard=scorecard_Insert_Update;
       }
        }
        
        //If user is not authorised, display the error message.
        else{
            KCS_Wrapper_Insert_Update.Is_User_Authorized=false;
            KCS_Wrapper_Insert_Update.Published=Is_Published;
        }
        
        return KCS_Wrapper_Insert_Update;
        
    }
    
    
    
    //Method to upsert data entered by the user in the dashboard into SC_KCS_Scorecard__c and SC_KCS_Scorecard_Criteria__c object based on user
    
    @AuraEnabled
    public static void Update_KCS_Scorecard_Details(String Criteria_Data, String Notes, String sourceId, String sourceType,String parentType) 
    {

        
        //------------------ Start of Scorecard Upsertion ------------------
        
        //String to store current user id
        String CurrentUserId = UserInfo.getUserId();
        
        //Getting Knowledge Article RecordTypeId
        Id knowledgeRecTypeId = Schema.SObjectType.SC_KCS_Scorecard__c.getRecordTypeInfosByName().get('Article Quality').getRecordTypeId();
        
        //Stores the details of Scorecard fields like notes , etc in case of edit. For first time creation, set with  default values. 
        SC_KCS_Scorecard__c scorecard_Insert_Update = new SC_KCS_Scorecard__c();
        
        //Temporary variable for Scorecard 
        List<SC_KCS_Scorecard__c> get_Existing_Scorecard  = new List<SC_KCS_Scorecard__c>();
        
        //If the component is called from Knowledge Page (record id starts with ka), set appropriate Scorecard_Id  
        if(sourceType == 'Knowledge'){
            
            get_Existing_Scorecard=[SELECT Id,Knowledge__r.Createdbyid FROM SC_KCS_Scorecard__c where CreatedById =:CurrentUserId AND Knowledge__c =:sourceId];
            
            if(get_Existing_Scorecard.size() != 0)
            {
                scorecard_Insert_Update.Id=get_Existing_Scorecard[0].Id;
            }
            else{
                scorecard_Insert_Update.RecordTypeId = knowledgeRecTypeId;
                scorecard_Insert_Update.Knowledge__c=sourceId;
            }
            
        }
        
        //If the component is called from Scorecard Page (record id starts with aG), set appropriate Scorecard_Id
        else if(sourceType == 'Quality Coaching'){
            
            get_Existing_Scorecard=[SELECT Id,Knowledge__r.CreatedbyId FROM SC_KCS_Scorecard__c where Id =:sourceId];
            
            if(get_Existing_Scorecard.size() != 0)
            {
                scorecard_Insert_Update.Id=get_Existing_Scorecard[0].Id;
            }
        }
        
        // Populate notes entered by the user into the instance   
        scorecard_Insert_Update.Notes__c=Notes;    
        
        upsert scorecard_Insert_Update;
        
        
        
        
        
        
        //------------------ End of Scorecard Upsertion ------------------
        
        
        //------------------ Start of Scorecard Criteria Upsertion ------------------
        
        //String to store Scorecard Id after upsertion
        String Scorecard_Id =scorecard_Insert_Update.Id;
        
        
        
        //This is the list of values existing in the database  based on scorecard previously created by the user
        List<SC_KCS_Scorecard_Criteria__c>  Existing_Criteria_List =[SELECT Id FROM SC_KCS_Scorecard_Criteria__c where  KCS_Scorecard__c =:Scorecard_Id ORDER BY Criteria_Number__c];    
        
        
        
        //Converting List of Criteria Data collected in JSON format from the Lightning component into a List of SC_KCS_Scorecard_Criteria__c
        
        //This is the list of values got from Lightning Component 
        List<SC_KCS_Scorecard_Criteria__c> List_Of_Criteria = (List<SC_KCS_Scorecard_Criteria__c>)System.JSON.deserializeStrict(Criteria_Data, List<SC_KCS_Scorecard_Criteria__c>.Class);
        
        
        
        
        for (Integer i=0;i<List_Of_Criteria.size();i++){
            //If criteria values exist for the scorecard -Updation
            if(Existing_Criteria_List.size() != 0){
                List_Of_Criteria[i].Id=Existing_Criteria_List[i].Id;
            }
            //If criteria values doesn't exist for the scorecard -Insertion
            else{
                List_Of_Criteria[i].KCS_Scorecard__c=Scorecard_Id;
            }
            
            
        }
        
        //upsert data entered by the user in the dashboard into SC_KCS_Scorecard__c and SC_KCS_Scorecard_Criteria__c object 
        
        upsert List_Of_Criteria Id;
        //------------------ End of Scorecard Criteria Upsertion ------------------
        
        //Calculation of Commulative score for the past 30 days
      DateTime considerationDate = (DateTime.now() - Integer.valueOf(30)).dateGMT();
        AggregateResult[] groupedResults;
        if(get_Existing_Scorecard.size() != 0){
            groupedResults = [SELECT AVG(Total_Score__c) FROM SC_KCS_Scorecard__c WHERE Knowledge__r.Createdbyid = :get_Existing_Scorecard[0].Knowledge__r.CreatedbyId AND Createddate > :considerationDate ];
        }
        
        else{
            SC_KCS_Scorecard__c scorecard1 = [SELECT Knowledge__r.CreatedbyId FROM SC_KCS_Scorecard__c where Id = :Scorecard_Id];
            groupedResults = [SELECT AVG(Total_Score__c) FROM SC_KCS_Scorecard__c WHERE Knowledge__r.Createdbyid = :scorecard1.Knowledge__r.CreatedbyId AND Createddate > :considerationDate ];
        }
        scorecard_Insert_Update.Cumulative_Score__c = Double.valueOf(groupedResults[0].get('expr0'));
        Update scorecard_Insert_Update;
        
        
        
    }
    
    @AuraEnabled
    public static String getParentType(String sourceId){
        SC_KCS_Scorecard__c qcRec=[SELECT Id, RecordType.DeveloperName FROM SC_KCS_Scorecard__c where Id =:sourceId limit 1];
        String recordTypeName = qcRec.RecordType.DeveloperName;
        if(recordTypeName == 'Case_Quality')
            return 'Case';
        if(recordTypeName == 'Escalation_Quality')
            return 'Escalation';
        if(recordTypeName == 'Transition_Quality')
            return 'Transition';
        if(recordTypeName == 'Article_Quality')
            return 'Knowledge';
        if(recordTypeName == 'RCA_Request')
            return 'RCA'; 
        return 'Not Found';
    }
    
    
    
    
}