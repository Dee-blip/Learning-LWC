public class SC_CommunityWrapper {
 	@AuraEnabled
    public Community_Blog_Comment__c comment {get;set;}
    
    @AuraEnabled
    public Customer_Community_Document__c communityDocument {get;set;}
    
    @AuraEnabled
    public Boolean hasEdit {get;set;}
    
    @AuraEnabled
    public Boolean hasDel {get;set;}
    
    @AuraEnabled
    public Integer totalRecords {get;set;}
    
    @AuraEnabled
    public List<Knowledge__kav> allBlogList {get;set;}
}