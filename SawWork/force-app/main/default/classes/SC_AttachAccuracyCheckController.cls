/*=====================================================================================================+
    Class name          :   SC_AttachAccuracyCheckController 
    Author              :   Aditya Sonam
    Created             :   23-Nov-17
    Test Class          :   SC_AttachAccuracyController_TestClass
------------------------------------------------------------------
|   HISTORY                                                      |                                                                            
|   DATE            DEVELOPER   JIRA        DESCRIPTION          |                                             
|   ===========     =========   =======     =========== 
|   18-Jul-2019     Vishnu      ESESP-2104  Akapedia Dashbaord, Accuracy Check - filter invalid cases
=====================================================================================================*/
public class SC_AttachAccuracyCheckController {
    private Case caseRecord;
    public string eachCaseID{get;set;}
    public boolean isSuccess{get;set;}
    public boolean noCaseToDisplay{get;set;}
    public List<Case> caseList{get;set;}
    public Map<string,String> knowledgeArticleNumberMap{get;set;}
    public list<string> articleNumberList{get;set;}
    public Map<id,list<String>> caseArticleMap{get;set;}
    public dateTime userDateSelection;
    public integer inputdateNumber{get;set;}
    public boolean hasPermissionToView{get;set;}
    public boolean hasMoreThanOneArticle{get;set;}
    public list<string> articleList;
    public boolean isInAkapedia{get;set;}
    // ESESP-2104 Akapedia Dashbaord, Accuracy Check - filter invalid cases
    // CONSTANT - Invalid Record type
    static final String RT_INVALID = 'Invalid Case';
    public SC_AttachAccuracyCheckController(ApexPages.StandardController stdController){
        
        User loggedInUserDetail = [SELECT Id,Name,SC_KCS_Coach__c,KCS_Level__c,Profile.Name FROM User WHERE Id =:Userinfo.getUserId() LIMIT 1];
        hasPermissionToView = false;
        isSuccess = false;
        hasMoreThanOneArticle = false;
        
        String caseOwnerName = ApexPages.currentPage().getParameters().get('UN');
        caseList = new List<Case>();
        knowledgeArticleNumberMap = new Map<string,String>();
        articleNumberList= new List<string>();
        caseArticleMap = new Map<Id,list<String>>();
        
        //fetching permission level from metadata type
        string accuracyCheckPerm = [select value__c from SC_Utility__mdt where DeveloperName = 'Attach_Accuracy_Check_Profile_Permission' limit 1].value__c;

        //Checking permissions
        if(loggedInUserDetail.KCS_Level__c != Null && (accuracyCheckPerm.contains(loggedInUserDetail.KCS_Level__c) || accuracyCheckPerm.contains(loggedInUserDetail.Profile.Name)))
        {
            //Checking if page is opened in Case Publisher Action
            if(String.isBlank(caseOwnerName)){
                isInAkapedia = false;
                hasPermissionToView = true;
                caseRecord = (Case)stdController.getRecord();                
                
                //Querying Case
                // ESESP-2104 - added condition to exclude invalid cases - recordtype.name = invalid
                caseList = [SELECT id,Accuracy_Check_Created_Date__c,Article_Number_s__c,Has_Article_Linked__c,Numeric_Accurate_Attach__c,Has_Attach_Accuracy_Check__c,
                            Accurate_Attach__c,Non_Attach_Indicator__c,Akam_Case_Id__c FROM Case WHERE id =: caseRecord.id //AND (Accurate_Attach__c = '' OR Accurate_Attach__c = 'NO') AND Non_Attach_Indicator__c = '' 
                            AND Origin != 'Proactive' AND RecordType.Name != :RT_INVALID
                            AND Sub_Type__c != 'CMP Alerts' AND Sub_Type__c != 'Service & Support Packages' AND Sub_Type__c != 'NIE/NOCC Request' and Work_Type__c !='Proactive'
                            AND (NOT Account.Name LIKE '%Akamai%')
                           ];
                
                if(caseList.size()>0)
                    createCaseAndKAMap(caseList);
                else
                   noCaseToDisplay = false; 
                
            }
            
            //logic to get case when opened from Akapedia DB
            else
            {
                isInAkapedia = true;
                hasPermissionToView = true;
                string inputdate = ApexPages.currentPage().getParameters().get('dateRange');
                if(inputdate.indexOf('7') != -1){
                    inputdateNumber = 7;
                }
                else if(inputdate.indexOf('30') != -1){
                    inputdateNumber = 30;
                }
                else if(inputdate.indexOf('60') != -1){
                    inputdateNumber = 60;
                }
                else {
                    inputdateNumber = 90;
                }
                
                userDateSelection = System.now() - inputdateNumber;
                // ESESP-2104 - added condition to exclude invalid cases - recordtype.name = invalid
                 caseList = [SELECT id,Accuracy_Check_Created_Date__c,Article_Number_s__c,Has_Article_Linked__c,Numeric_Accurate_Attach__c,Has_Attach_Accuracy_Check__c,
                            Accurate_Attach__c,Non_Attach_Indicator__c,Akam_Case_Id__c FROM Case WHERE Owner.Name =: caseOwnerName AND RecordType.Name != :RT_INVALID AND Accurate_Attach__c = '' AND Non_Attach_Indicator__c = ''
                            AND AKAM_Closed_Date__c >:userDateSelection AND Origin != 'Proactive'
                            AND Sub_Type__c != 'CMP Alerts' AND Sub_Type__c != 'Service & Support Packages' AND Sub_Type__c != 'NIE/NOCC Request' AND Work_Type__c !='Proactive' AND status = 'Closed'
                            AND (NOT Account.Name LIKE '%Akamai%') LIMIT 10000];
                
                
                if(caseList.size()>0){
                    createCaseAndKAMap(caseList);
                }
                else
                   noCaseToDisplay = true; 
            }
        }
        
        caseList = con.getRecords();
    }
    
    //Creating Map of Case and Knowledge Article to display on Page
    public void createCaseAndKAMap(list <case> caseList){
        articleList = new list<String>();
        if(caseList.size()>0){
            for(Case eachCase :caseList){   
                if((eachCase.Has_Article_Linked__c || eachCase.Accurate_Attach__c == 'No') && eachCase.Article_Number_s__c != Null){
                    for(string eachId :eachCase.Article_Number_s__c.split(',')){
                        articleList.add(eachId);
                        if(caseArticleMap.get(eachCase.Id) != Null){
                            articleNumberList = caseArticleMap.get(eachCase.id);
                            articleNumberList.add(eachId);
                            caseArticleMap.put(eachCase.id,articleNumberList);
                        }
                        else{
                            caseArticleMap.put(eachCase.id, new List<String>{eachId});
                        }
                    }
                }  
                else{
                    caseArticleMap.put(eachCase.id, new List<String>{}); 
                }
            }
        }
        else{
            //noCaseToDisplay = true;
        }
        if(!caseArticleMap.isEmpty()){
            for(Knowledge__kav eachKA : [select Id,AKAM_Article_Number__c from Knowledge__kav where PublishStatus = 'Online' and Language = 'en_US' and AKAM_Article_Number__c IN :articleList]){
                knowledgeArticleNumberMap.put(eachKA.AKAM_Article_Number__c,eachKA.Id);
            }
            for(Knowledge__kav eachKA : [select Id,AKAM_Article_Number__c from Knowledge__kav where PublishStatus = 'Archived' and Language = 'en_US' and AKAM_Article_Number__c IN :articleList]){
                knowledgeArticleNumberMap.put(eachKA.AKAM_Article_Number__c,eachKA.Id);
            }
        }
    }
    
    //Save 
    public pageReference saveAccuracyCheck(){
        Case eachCaseForUpdate;
        CaseArticle eachCaseArticle;
        list<CaseArticle> caseAr = new list<CaseArticle>([Select id from CaseArticle where caseId =:eachCaseID]);
        for(case c :caseList){
            if(c.id == eachCaseID){
                eachCaseForUpdate = new Case(); 
                eachCaseForUpdate.Id = c.Id;
                eachCaseForUpdate.Validation_Override__c = true;  
                eachCaseForUpdate.Non_Attach_Indicator__c = c.Non_Attach_Indicator__c != Null ? c.Non_Attach_Indicator__c : '';
                eachCaseForUpdate.Accurate_Attach__c = c.Accurate_Attach__c != Null ? c.Accurate_Attach__c : '';
                
                if(c.Has_Article_Linked__c = true && c.Accurate_Attach__c == 'No' && caseArticleMap.containsKey(c.id) && caseArticleMap.get(c.id).size()== 1){
                    eachCaseForUpdate.Has_Article_Linked__c = false;

                }
                if(c.Accuracy_Check_Created_Date__c == null ){
                    eachCaseForUpdate.Accuracy_Check_Created_Date__c = system.now();
                }
                if(caseAr.size()== 1 && c.Accurate_Attach__c == 'No'){
                    eachCaseArticle = new CaseArticle();
                    eachCaseArticle.id = caseAr[0].id;
                    delete eachCaseArticle;  
                }
                
                else if(caseAr.size()>1 && c.Accurate_Attach__c == 'No'){
                    hasMoreThanOneArticle = true;
                }
                else {
                    hasMoreThanOneArticle = false;
                } 
            } 
        }
        update eachCaseForUpdate;
        isSuccess = true;
        
        return null;
    }
    
    //Refreshing Page
    public pageReference refreshPage(){
        string userName = System.currentPageReference().getParameters().get('UN');
        string dateRange = System.currentPageReference().getParameters().get('dateRange');
        PageReference pageRef = new PageReference('/apex/SC_AttachAccuracyCheck');
        pageRef.setRedirect(true);
        pageRef.getParameters().put('UN',userName);
        pageRef.getParameters().put('dateRange',dateRange);
        return pageRef;
    }
    
    //Standard Set Controller
    public ApexPages.standardSetController con{
        get{
            if(con == null)
            {
                Integer size = 2;
                con = new ApexPages.StandardSetController(caseList);
                con.setPageSize(size);
                Integer noOfRecords = con.getResultSize();
            }
            return con;
        }        
        set;
    }
       
    public Boolean hasNext{
        get{
            return con.getHasNext();
        }
        set;
    }
    public Boolean hasPrev{
        get{
            return con.gethasPrevious();
        }
        set;
    }
    
    // returns the page number of the current page set
    public Integer getPageNumber{
        get{
            if(con.getResultSize()==0)
                return 0;
            else
                return con.getPageNumber();
        }
        set;
    }
    
    public Integer getTotalPageNumber{
        get{
            Integer totalPages = (Math.mod(con.getResultSize(),2) == 0) ? con.getResultSize()/2 : con.getResultSize()/2 + 1;
            return totalPages;
        }
        set;
    }
    
    public void first(){
        con.first();
        caseList = con.getRecords();
    }
    public void last(){
        con.last();
        caseList = con.getRecords();
    }
    public void next(){
        con.next();
        caseList = con.getRecords();
    }
    public void previous(){
        con.previous();
        caseList = con.getRecords();
    }
}