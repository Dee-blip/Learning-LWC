/*---------------------------------------------------------------------------------
 * Class Name           : SC_KCSFlag_CreationCtrl
 * Developer Name       : Vamsee Surya
 * Date                 : 25th May,2017
 * JIRA                 : ESESP-550 
 * Test Class           : SC_KCS_TestClass
 ---------------------------------------------------------------------------------*/ 
public class SC_KCSFlag_CreationCtrl {
    
    //Flag object
    public SC_KCS_Flag__c KCSFlagObject {get;set;}
    
    //Display error message when article in Draft/Archive state
    public boolean isValid{get;set;}
    
    //List to Store the Article
    List<KnowledgeArticleVersion> articleList;
    
    //Constructor
    public SC_KCSFlag_CreationCtrl(){
        //Article Id will be set as Id
        String articleId  = ApexPages.currentPage().getParameters().get('Id');
        
        //If user tries to open the page from KB Article
        if(String.isNotBlank(articleId)){
            String query =  'SELECT Id, KnowledgeArticleId, ArticleNumber, Title, OwnerId, VersionNumber,'+
                            ' ArticleType FROM KnowledgeArticleVersion WHERE  ' +
                            ' KnowledgeArticleId  =\''+ articleId + '\' AND PublishStatus=\'Online\' AND Language =\'en_US\' LIMIT 1';  
            articleList = new List<KnowledgeArticleVersion>();
            articleList = Database.query(query);
            //If articleList size != 1 then Article should be in Draft/Archive State
            if(articleList.size() == 1){
                isValid = True;
                KCSFlagObject = new SC_KCS_Flag__c();
            }
            else
                isValid = False;
        }
         
    }
    
    //This method will be called when User click on Save
    public void CreateFlag(){
        try{
            KCSFlagObject.Status__c = 'Open';
            KCSFlagObject.Article_Title__c = articleList[0].Title;
            KCSFlagObject.Article_ID__c = articleList[0].ArticleNumber;
            KCSFlagObject.Article_SF_Id__c = articleList[0].KnowledgeArticleId;
            KCSFlagObject.Article_Created_By__c  = articleList[0].OwnerId;
            KCSFlagObject.Article_Version__c  = articleList[0].VersionNumber;
            KCSFlagObject.KCS_Coach__c = [SELECT SC_KCS_Coach__c FROM User WHERE Id = :articleList[0].OwnerId LIMIT 1].SC_KCS_Coach__c;
            
            //Get Visibility value of the article
            String visibilityQuery = 'SELECT Visibility__c FROM '+ articleList[0].ArticleType + ' WHERE Id =\''+ articleList[0].Id + '\' LIMIT 1';
            List<sObject> sObjectList = Database.query(visibilityQuery);
            if(sObjectList.size() == 1)
                KCSFlagObject.Visibility__c = String.valueOf(sObjectList[0].get('Visibility__c'));
            
            //Insert and Update can be put as Upsert but AddFeedItem should be called only during Insert
            if(KCSFlagObject.Id == null){
                Insert KCSFlagObject;
                AddFeedItem();
            }
            else{
                Update KCSFlagObject;
            }
            //Add success message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Saved Successfully!'));
        }
        Catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
        }
        
    }
    
    //This method will add the FeedItem on the KB Article
    Public void AddFeedItem(){
        FeedItem postFeedItem = new FeedItem();
        postFeedItem.ParentId = KCSFlagObject.Article_SF_Id__c;
        postFeedItem.Body = 'New Flag is created on this Article';
        postFeedItem.LinkUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + KCSFlagObject.Id;
        postFeedItem.Title = 'Review Flag';
        insert postFeedItem;
    }   
}