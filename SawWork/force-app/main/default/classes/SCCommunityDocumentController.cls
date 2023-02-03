/*******************
  ESESP-1548   22/8/2018    Document view Page rewritten
**********************************/
public class SCCommunityDocumentController
{

    @AuraEnabled
     public static Customer_Community_Document__c getdocuments(Id DocumentId)
     {
     
            List<Customer_Community_Document__c> Docu =[Select Title__c,Description__c, Group_Id__c, CreatedBy.FirstName,CreatedBy.LastName,CreatedDate,LastModifiedBy.FirstName,LastModifiedBy.LastName,LastModifiedDate from Customer_Community_Document__c where id =:DocumentId];
            return Docu[0];
     
     
     }
     
     
    @AuraEnabled
    public static void DeleteDocumentApex(Id DocumentId)
    {
        System.debug('DocumentID'+DocumentId);
        List<Customer_Community_Document__c> Docu = [Select Id from Customer_Community_Document__c where id =:DocumentId];
        Delete Docu;
    }
    
    @AuraEnabled
    public static void UpdateDocument(Id DocumentId,String Title,String Description)
    {
        Customer_Community_Document__c Docu = new Customer_Community_Document__c(Id=DocumentId);
        Docu.Title__c=Title;
        Docu.Description__c=Description;
        update Docu;
    }
    
    @AuraEnabled 
    public static CollaborationGroup getGroupName(Id DocumentId)
    {
        List<Customer_Community_Document__c> Docu =[Select Title__c,Description__c, Group_Id__c from Customer_Community_Document__c where id =:DocumentId];
        system.debug(Docu[0].Group_Id__c);
        List<CollaborationGroup> GrpName = [Select Id, Name from CollaborationGroup where Id=:Docu[0].Group_Id__c];
        system.debug(GrpName[0].Name);
        return GrpName[0];
        
        
    }
    
    @AuraEnabled
    public static boolean hasEditAccess(Id DocumentId)
    {
        List<UserRecordAccess> hasedit=[SELECT  RecordId,HasReadAccess,HasEditAccess,HasDeleteAccess FROM  UserRecordAccess WHERE  UserId=:UserInfo.getUserId() AND RecordId =: DocumentId];
        return hasedit[0].HasEditAccess;
    }
    
    @AuraEnabled
    public static boolean hasDeltAccess(Id DocumentId)
    {
        List<UserRecordAccess> hasdel=[SELECT  RecordId,HasReadAccess,HasEditAccess,HasDeleteAccess FROM  UserRecordAccess WHERE  UserId=:UserInfo.getUserId() AND RecordId =: DocumentId];
        return hasdel[0].HasDeleteAccess;
    }
    //Added on 21st Sep 2018 by Vikas to fetch the id of the customer community network ESESP-1678
    @AuraEnabled
    public static String fetchCommunityId(){
        Map<String,String> communityUtilMap = prepareMetadataMap();
        Id networkId = [Select id from Network where name =: communityUtilMap.get('CommunityName')].id;
        return String.valueOf(networkId);
    }
    //Added on 21st Sep 2018 by Vikas to prepare a map of SC Community Utility metadata
    private static Map<String,String> prepareMetadataMap(){
        Map<String,String> communityUtilMap = new Map<String,String>();
        for(SC_CommunityUtility__mdt commUtil: [select Value__c, MasterLabel from SC_CommunityUtility__mdt])
        {
            communityUtilMap.put(commUtil.MasterLabel, commUtil.Value__c);
        }
       return communityUtilMap;
    }
}