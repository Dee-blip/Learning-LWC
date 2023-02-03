public with sharing class customCaseSearchController {
 /*   @AuraEnabled(cacheable=true)
    public static List<Case> getCasesList(String searchText) {
        List<List<SObject>> caseResults = [FIND :searchText IN ALL FIELDS  RETURNING Case(Id,Subject,CaseNumber, AKAM_Case_ID__c,Status, Account.name, AKAM_Created_Date__c ,recordtype.name,Owner.Alias ) limit 10];
        Case [] searchedCases = ((List<Case>)caseResults[0]);
        return searchedCases;
        
    }   
    */
    // @AuraEnabled(cacheable=true)
    // public static List<Community_Comments__c> getCaseCommentsList(String searchText) {
    //     List<List<SObject>> commentResults = [FIND :searchText IN ALL FIELDS  RETURNING Community_Comments__c(Id,Comment__c,AKAM_Created_Date__c,Parent_Name_Url__c,Parent_Name__c,Parent_ID__c)];
    //     Community_Comments__c [] searchedCaseComments = ((List<Community_Comments__c>)commentResults[0]);
    //     return searchedCaseComments;
        
    // } 

    @AuraEnabled//Get Case Records
    public static String getCaseList(Integer pageSize, Integer pageNumber, String searchText){
        String jsonDT = '';
      
        //Offset for SOQL
        Integer offset = (pageNumber - 1) * pageSize;
         
        //Total Records
        List<List<SObject>> caseResults = [FIND :searchText IN ALL FIELDS  RETURNING Case(Id,Subject,CaseNumber, AKAM_Case_ID__c,Status)];
        Case [] searchedCases = ((List<Case>)caseResults[0]);
        Integer totalRecords = searchedCases.size();
        Integer recordEnd = pageSize * pageNumber;
         
        CaseDTWrapper objDT =  new CaseDTWrapper();  
        objDT.pageSize = pageSize;
        objDT.pageNumber = pageNumber;
        objDT.recordStart = offset + 1;
        objDT.recordEnd = totalRecords >= recordEnd ? recordEnd : totalRecords;
        objDT.totalRecords = totalRecords;
        objDT.cases = ((List<Case>)[FIND :searchText IN ALL FIELDS  RETURNING Case(Id,Subject,CaseNumber, AKAM_Case_ID__c,Status,FORMAT(AKAM_Created_Date__c), Description ORDER BY AKAM_Created_Date__c DESC LIMIT :pageSize OFFSET :offset)][0]);//[SELECT Id, Name, AccountNumber, Industry, Phone FROM Account LIMIT :pageSize OFFSET :offset];
        jsonDT = JSON.serialize(objDT);
        return jsonDT;
    }
     
    public class CaseDTWrapper {
        public Integer pageSize {get;set;}
        public Integer pageNumber {get;set;}
        public Integer totalRecords {get;set;}
        public Integer recordStart {get;set;}
        public Integer recordEnd {get;set;}
        public List<Case> cases {get;set;}
    }
    
    @AuraEnabled//Get Case Records
    public static String getCommunityCommentsList(Integer pageSizeComments, Integer pageNumberComments, String searchText){
        String jsonDTComments = '';
         
        //Offset for SOQL
        Integer offsetComments = (pageNumberComments - 1) * pageSizeComments;
         
        //Total Records
        List<List<SObject>> communityCommentsResults = [FIND :searchText IN ALL FIELDS  RETURNING Community_Comments__c(Id,Comment__c,FORMAT(AKAM_Created_Date__c) ,AKAM_Created_By__c ,Parent_Name__c ,Parent_ID__c ,Commented_By_User__c)];
        Community_Comments__c [] searchedCaseComments = ((List<Community_Comments__c>)communityCommentsResults[0]);
        Integer totalRecordsComments = searchedCaseComments.size();
        Integer recordEndComments = pageSizeComments * pageNumberComments;
         
        CommentDTWrapper objDTComments =  new CommentDTWrapper();  
        objDTComments.comments = ((List<Community_Comments__c>)[FIND :searchText IN ALL FIELDS  RETURNING Community_Comments__c(Id,Comment__c,FORMAT(AKAM_Created_Date__c) ,AKAM_Created_By__c ,Parent_Name__c ,Parent_ID__c ,Commented_By_User__c ORDER BY AKAM_Created_Date__c DESC LIMIT :pageSizeComments OFFSET :offsetComments)][0]);//[SELECT Id, Name, AccountNumber, Industry, Phone FROM Account LIMIT :pageSize OFFSET :offset];
        objDTComments.pageSizeComments = pageSizeComments;
        objDTComments.pageNumberComments = pageNumberComments;
        objDTComments.recordStartComments = offsetComments + 1;
        objDTComments.recordEndComments = totalRecordsComments >= recordEndComments ? recordEndComments : totalRecordsComments;
        objDTComments.totalRecordsComments = totalRecordsComments;
        jsonDTComments = JSON.serialize(objDTComments);
        return jsonDTComments;
    }
     
    public class CommentDTWrapper {
        public Integer pageSizeComments {get;set;}
        public Integer pageNumberComments {get;set;}
        public Integer totalRecordsComments {get;set;}
        public Integer recordStartComments {get;set;}
        public Integer recordEndComments {get;set;}
        public List<Community_Comments__c> comments {get;set;}
    }
}