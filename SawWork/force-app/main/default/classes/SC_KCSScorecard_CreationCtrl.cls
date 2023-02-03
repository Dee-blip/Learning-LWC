/*---------------------------------------------------------------------------------
 * Class Name           : SC_KCSScorecard_CreationCtrl
 * Developer Name       : Vamsee Surya
 * Date                 : 25th May,2017
 * JIRA                 : ESESP-550 
 * Test Class           : SC_KCS_TestClass
|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
  22-Nov-2017    Pinkesh    ESESP-810 -  KCS: Add new KCS KDE value
 ---------------------------------------------------------------------------------*/ 

public class SC_KCSScorecard_CreationCtrl{
    
    //List to store each Scorecard criteria Object
    public List<SC_KCS_Scorecard_Criteria__c> scorecardCriteriaList{get;set;}
    
    //Scorecard Object
    Public SC_KCS_Scorecard__c scorecardObject{get;set;}
    
    //Display error message when article in Draft state
    Public boolean isValid{get;set;}
    
    Public String errorMessage{get;set;}
    
    //To Store the Query String
    String query;
    
    //To Store Id
    String tempId;
    
    //Contructor for Create Page 
    Public SC_KCSScorecard_CreationCtrl(){
        
        //Get the Id from the Page Parameter
        tempId = ApexPages.currentPage().getParameters().get('Id');
            
        //Check whether User is authorized to Create Scorecard
        User loggedInUser = [SELECT KCS_Level__c, Profile.Name FROM User WHERE Id =:Userinfo.getUserId() LIMIT 1];
        if(loggedInUser.KCS_Level__c == 'KCS Coach' || loggedInUser.KCS_Level__c == 'KCS KDE' || loggedInUser.Profile.Name.contains('Support - Tech Support Manager')){
            
            
            //If the Id is KB Article Id
            if(tempId.startsWithIgnoreCase('kA')){
                scorecardObject = new SC_KCS_Scorecard__c();
                scorecardCriteriaList = new List<SC_KCS_Scorecard_Criteria__c>();
                
                query = 'SELECT KnowledgeArticleId, ArticleNumber, Title, OwnerId, VersionNumber, Createddate FROM KnowledgeArticleVersion WHERE  ' +
                        ' KnowledgeArticleId  =\''+ tempId + '\' AND PublishStatus=\'Online\' AND Language =\'en_US\' LIMIT 1';
                
                List<KnowledgeArticleVersion> articleList = Database.query(query);
                
                //If articleList size != 1 then Article should be in Draft/Archive State
                if(articleList.size() == 1){
                    isValid = True;
                    //populate the article details into scorecard object
                    scorecardObject.Article_Created_By__c  = articleList[0].OwnerId;
                    scorecardObject.Article_Title__c = articleList[0].Title;
                    scorecardObject.Article_Id__c = articleList[0].ArticleNumber;
                    scorecardObject.Article_Created_Date__c = articleList[0].Createddate;
                    scorecardObject.Article_SF_Id__c  = articleList[0].KnowledgeArticleId;
                
                    //Get the Article owner Details this is required because it need to be visible on creation page
                    User ArticleOwnerDetail = [SELECT KCS_Level__c, SC_KCS_Coach__c, Manager.Name FROM User WHERE Id =:articleList[0].OwnerId LIMIT 1];
                    scorecardObject.Article_Author_KCS_Level__c = ArticleOwnerDetail.KCS_Level__c;
                    scorecardObject.Article_Author_Manager__c = ArticleOwnerDetail.Manager.Name;
                    scorecardObject.Coach__c = ArticleOwnerDetail.SC_KCS_Coach__c;
                    
                    //Scorecard Criteria
                    List<SC_KCS_Scorecard_Criteria_Settings__mdt> criteriaList = [SELECT Criteria_Name__c, Criteria_Number__c, Points__c FROM SC_KCS_Scorecard_Criteria_Settings__mdt ORDER BY Criteria_Number__c];
                    for(SC_KCS_Scorecard_Criteria_Settings__mdt eachCriteria : criteriaList){
                        SC_KCS_Scorecard_Criteria__c scorecardCriteria = new SC_KCS_Scorecard_Criteria__c();
                        scorecardCriteria.Criteria_Name__c = eachCriteria.Criteria_Name__c; 
                        scorecardCriteria.Criteria_Number__c = eachCriteria.Criteria_Number__c;
                        scorecardCriteria.Points__c = eachCriteria.Points__c;
                        scorecardCriteriaList.add(scorecardCriteria);
                    }
            
                }
                else{
                    isValid = False;
                    errorMessage = 'Scorecard can be created only on Published Article';
                }
            }
            else{
                isValid = False;
                errorMessage = 'Not a valid Article';
            }
                
        }
        else{
            isValid = False;
            errorMessage = tempId.startsWithIgnoreCase('kA') ? 'Only Coach, KDE and Tech Support Managers can Score an Article' : 'Scorecard can be created only on Published Article';
        }   
    }
    
    //Constructor for Edit Page
    Public SC_KCSScorecard_CreationCtrl(ApexPages.StandardController stdController){
        
        //Check whether User is authorized to Edit Scorecard
        User loggedInUser = [SELECT KCS_Level__c, Profile.Name FROM User WHERE Id =:Userinfo.getUserId() LIMIT 1];
        if(loggedInUser.KCS_Level__c == 'KCS Coach' || loggedInUser.KCS_Level__c == 'KCS KDE' || loggedInUser.Profile.Name.contains('Support - Tech Support Manager')){
            scorecardObject = new SC_KCS_Scorecard__c();
            scorecardCriteriaList = new List<SC_KCS_Scorecard_Criteria__c>();
        
            //get the Id from the URL
            tempId = ApexPages.currentPage().getParameters().get('Id');
            
            //If Id is not null
            if(String.isNotBlank(tempId) && (!tempId.startsWithIgnoreCase('ka'))){
                query =     'SELECT Id, Article_Created_By__c,Article_Title__c, Article_Created_Date__c, Notes__c, Article_Id__c, ' +
                            'Article_SF_Id__c, Article_Author_KCS_Level__c,Article_Author_Manager__c,Coach__c, Cumulative_Score__c, ' +
                            '(SELECT Id, Criteria_Name__c, Criteria_Number__c, Points__c, Response__c, Fixed__c, KCS_Scorecard__c '+
                            'FROM SC_KCS_Scorecard_Criteria__r) FROM SC_KCS_Scorecard__c WHERE Id =\''+ tempId + '\'';
                scorecardObject = Database.query(query);
                scorecardCriteriaList = scorecardObject.SC_KCS_Scorecard_Criteria__r;
                isValid = True;
            
             }
        }
        else{
            isValid = False;
            errorMessage = 'Only KCS Coach/KCS KDE/Tech Support Managers can Create/Edit a Scorecard';
        } 
    }
    
    //This method will be called when User click on Save from Create Page
    public void CreateScorecard(){
        //Insert and Update can be put as Upsert but AddFeedItem should be called only during Insert
        Try{
            if(scorecardObject.Id != null){
                Upsert scorecardObject;
                Upsert scorecardCriteriaList;
                UpdateCumulativeScore();
            
            }    
            else{
                Upsert scorecardObject;
                for(SC_KCS_Scorecard_Criteria__c eachScorecardCriteria : scorecardCriteriaList){
                    eachScorecardCriteria.KCS_Scorecard__c  = scorecardObject.Id;
                }
                Upsert scorecardCriteriaList;
                UpdateCumulativeScore();
                AddFeedItem();
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Saved Successfully!'));
        }
        Catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
        }
            
    }
    
    //This method will be called when User click on Save from Edit Page
    Public pagereference UpdateScorecard(){
        Try{
            Upsert scorecardObject;
            Upsert scorecardCriteriaList;
            UpdateCumulativeScore();
            pagereference pr = new pagereference('/' + scorecardObject.id);
            return pr;
        }
        Catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
            return null;
        }
        
    }
    
    //This method will add the FeedItem on the KB Article
    Public void AddFeedItem(){
        FeedItem postFeedItem = new FeedItem();
        postFeedItem.ParentId = scorecardObject.Article_SF_Id__c;
        postFeedItem.Body = 'New Scorecard is created on this Article';
        postFeedItem.LinkUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + scorecardObject.Id;
        postFeedItem.Title = 'Review ScoreCard';
        insert postFeedItem;
        
    }
    
    //This method calculates cumulative scores over the last 30 days 
    Public void UpdateCumulativeScore(){
        DateTime considerationDate = (DateTime.now() - Integer.valueOf(30)).dateGMT();
        AggregateResult[] groupedResults = [SELECT AVG(Total_Score__c) FROM SC_KCS_Scorecard__c WHERE Article_Created_By__c = :scorecardObject.Article_Created_By__c AND Createddate > :considerationDate];
        scorecardObject.Cumulative_Score__c  = Double.valueOf(groupedResults[0].get('expr0'));       
        Update scorecardObject;
    }
}