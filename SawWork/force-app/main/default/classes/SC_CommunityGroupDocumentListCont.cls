/*
 * Description: Controller for CommunityDocument_Create and CustomerCommunityDocuments lightning components
 * Created by: Vikas
 * Modified by: Vikas on 18th Sep 2018 for ESESP-1678
*/
public with sharing class SC_CommunityGroupDocumentListCont {
    
    @AuraEnabled
    public static List<SC_CommunityWrapper> fetchCommunityDocuments(String searchString, String dataCategoryId,String pageNumber,String currnetPagesCount)
    {
        String DocumentQuery = '';
        SC_CommunityWrapper communityWrapper;
        List<SC_CommunityWrapper> communityWrapList = new List<SC_CommunityWrapper>();
        List<Id> documentIdList = new List<Id>();
        Map<Id,Boolean> documentEditMap = new Map<Id,Boolean>();
        Map<Id,Boolean> documentDelMap = new Map<Id,Boolean>();
        Integer totalRecords = 0;
        Boolean isModeratorOrSpaceAdmin = false;
        
        List<Customer_Community_Document__c> searchedList = new List<Customer_Community_Document__c>();
        List<Customer_Community_Document__c> finalSearchedList = new List<Customer_Community_Document__c>();
        List<CollaborationGroupMember> memberList =  new List<CollaborationGroupMember>();
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT ExcludeGroupForDocumentShare__c, PermissionSetToEditGrpDoc__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];

        if(!String.isEmpty(dataCategoryId))
            memberList = [SELECT Id, CollaborationGroupId, MemberId FROM CollaborationGroupMember where CollaborationGroupId =: id.valueOf(dataCategoryId) and MemberId =: UserInfo.getUserId()];
        Id adminId = [Select id from Profile where Name = 'System Administrator'].id;
        for(PermissionSetAssignment permissionSet : [SELECT Id,AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =:userinfo.getUserId()]){
            if(communityMetaDataVal.PermissionSetToEditGrpDoc__c.contains(String.valueOf(permissionSet.PermissionSetId)))
                isModeratorOrSpaceAdmin = true;
        }
        if(!String.isEmpty(dataCategoryId) && (memberList.size() > 0 || isModeratorOrSpaceAdmin || userinfo.getProfileId() == adminId)){
            DocumentQuery = 'Select id,Name,title__c,Group_Id__c,Share_With_Group_Ids__c,createdby.Name,CreatedDate,Description__c,CreatedBy.Id,ownerid,CreatedById from Customer_Community_Document__c '; 
            
            if(!String.isEmpty(searchString))
            {
                DocumentQuery += ' WHERE Group_Id__c = \''+dataCategoryId+'\''+' AND (';
                DocumentQuery += 'title__c like \'%'+searchString+'%\' OR CreatedBy.Name like \'%'+searchString+'%\'';  
                DocumentQuery += ') ORDER BY CreatedDate desc LIMIT '+currnetPagesCount+' OFFSET ';
            }
            else
            {
                DocumentQuery+= ' WHERE Group_Id__c = \''+dataCategoryId+'\''+' ORDER BY CreatedDate desc LIMIT '+currnetPagesCount+' OFFSET ';
            }
            searchedList = database.query(DocumentQuery.substringBefore('ORDER BY'));
            totalRecords = searchedList.size();
            searchedList = new List<Customer_Community_Document__c>();
            if(String.isBlank(pageNumber) || Integer.valueOf(pageNumber) == 1){
                DocumentQuery = DocumentQuery + ' 0';
            }
            else{
                DocumentQuery = DocumentQuery + String.valueOf((Integer.valueOf(pageNumber)-1)*Integer.valueOf(currnetPagesCount));
            }
            if(!String.isEmpty(DocumentQuery))
                searchedList = Database.query(DocumentQuery);
        }
        if(searchedList.size() > 0){
            Map<Id,Id> collaborationGroupMap = new Map<Id,Id>();
            for(Customer_Community_Document__c eachDocument :searchedList){
                if(!String.isEmpty(communityMetaDataVal.ExcludeGroupForDocumentShare__c))
                {
                    if(communityMetaDataVal.ExcludeGroupForDocumentShare__c.contains(eachDocument.Group_Id__c))
                        collaborationGroupMap.put(eachDocument.id,id.valueOf(eachDocument.Group_Id__c));
                    else
                        documentIdList.add(eachDocument.Id);
                }
                else
                    documentIdList.add(eachDocument.Id);
            }
            if(collaborationGroupMap.values().size() != 0){
                
                for(CollaborationGroupMember member : [SELECT Id, CollaborationGroupId, MemberId, CollaborationRole FROM CollaborationGroupMember 
                                                       where MemberId =: userinfo.getUserId() AND CollaborationGroupId IN: (collaborationGroupMap.values())])
                {
                    for(Customer_Community_Document__c eachDocument :searchedList){
                        if((eachDocument.Group_Id__c == member.CollaborationGroupId) && 
                           (member.CollaborationRole == 'Admin' || eachDocument.OwnerId == userinfo.getUserId() || eachDocument.CreatedById == userinfo.getUserId() 
                            || isModeratorOrSpaceAdmin || userinfo.getProfileId() == adminId)){
                                documentIdList.add(eachDocument.Id);
                           }
                    }
                }
            }
            if(documentIdList.size() > 0){
                list<UserRecordAccess> uRaList= [Select RecordId, HasEditAccess, HasDeleteAccess, HasAllAccess From UserRecordAccess Where UserId =:UserInfo.getUserId() AND RecordId IN:(documentIdList)];
                for(UserRecordAccess uRa : uRaList){
                    documentEditMap.put(uRa.RecordId,uRa.HasEditAccess);
                    documentDelMap.put(uRa.RecordId,uRa.HasDeleteAccess);
                }
            }
            
            for(Customer_Community_Document__c eachDocument :searchedList){
                communityWrapper = new SC_CommunityWrapper();
                if(!String.isEmpty(eachDocument.Group_Id__c)){
                    if(eachDocument.Group_Id__c.contains(dataCategoryId)){
                        communityWrapper.communityDocument = eachDocument;
                        if(documentEditMap.get(eachDocument.Id) != null)
                            communityWrapper.hasEdit = documentEditMap.get(eachDocument.Id);
                        if(documentDelMap.get(eachDocument.Id) != null)
                            communityWrapper.hasDel = documentDelMap.get(eachDocument.Id);
                        communityWrapper.totalRecords = totalRecords;
                        communityWrapList.add(communityWrapper);
                    }
                }
            }
        }
        return communityWrapList;
    }
    
    @AuraEnabled
    public static Boolean checkAccess(String documentGroupId){
        Profile p = [select name from Profile where id =:UserInfo.getProfileId()];
        Map<String,String> communityUtilMap = prepareMetadataMap();
        List<CollaborationGroupMember> collGrpMemList = [Select Id,CollaborationGroupId,MemberId from CollaborationGroupMember where CollaborationGroupId =:Id.valueOf(documentGroupId) and MemberId =:userinfo.getUserId()];
        if(p.name != communityUtilMap.get('CommuntiyGuestProfile') && UserInfo.getOrganizationName().contains(communityUtilMap.get('CompanyName'))
           && UserInfo.getUserEmail().contains(communityUtilMap.get('CompanyEmail')) && collGrpMemList.size() > 0)
        {
            return true;
        }
        else
            return false;
    }
    @AuraEnabled
    public static Boolean fetchDocumentEditAccess(String documentGroupId){
        list<UserRecordAccess> uRaList= [Select RecordId, HasAllAccess From UserRecordAccess Where UserId =:UserInfo.getUserId() AND RecordId =:id.valueOf(documentGroupId)];
        return uRaList[0].HasAllAccess;
    }
    @AuraEnabled
    public static Customer_Community_Document__c fetchDocument(String documentId){
        Customer_Community_Document__c doc = new Customer_Community_Document__c();
        doc = [select id,Createdby.Id,Title__c,Description__c,Group_Id__c,Share_With_Group_Ids__c from Customer_Community_Document__c where id=:id.valueOf(documentId) limit 1];
        return doc;
    }
    @AuraEnabled
    public static String saveDoc(Customer_Community_Document__c documentRecord){
        try{
            if(documentRecord.Description__c != null){
                String descLength = String.valueOf(documentRecord.Description__c.length()); 
                if(documentRecord.Description__c.length() >= 131072){
                    return 'SIZEERROR'+descLength;
                }
                else{
                    update documentRecord;
                    return documentRecord.Id;
                }
            }
            else{
                return null;
            }
        }
        catch(Exception e){
            system.debug('EXCEPTION : '+e.getMessage());
            return null;
        }
    }  
    @AuraEnabled
    public static void delDoc(String documentId){
        try{
            delete[Select id from Customer_Community_Document__c where id=:id.valueOf(documentId)];
        }
        catch(Exception e){
            system.debug('EXCEPTION : '+e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createDocRecord(Customer_Community_Document__c docRecord, String documentGroupId){
        try{
            String descLength = String.valueOf(docRecord.Description__c.length()); 
            if(docRecord.Description__c.length() >= 131072){
                return 'SIZEERROR'+descLength;
            }
            else{
                Customer_Community_Document__c newDocRecord = new Customer_Community_Document__c();
                newDocRecord.id = docRecord.id;
                newDocRecord.Title__c = docRecord.Title__c;
                newDocRecord.Description__c = docRecord.Description__c;
                newDocRecord.Group_Id__c = documentGroupId;
                insert newDocRecord;
                return newDocRecord.Id;
            }
        }
        catch(Exception e){
            system.debug('EXCEPTION : '+e.getMessage());
            SC_Jarvis_utility.sendErrorMails('Error in Community Document createDocRecord method: ', e.getMessage(), e.getStackTraceString());
            return 'EXCEPTION'+e.getMessage();
        }
    }
    //Added on 18th Sep 2018 by Vikas to fetch the id of the customer community network ESESP-1678
    @AuraEnabled
    public static String fetchCommunityId(){
        Map<String,String> communityUtilMap = prepareMetadataMap();
        Id networkId = [Select id from Network where name =: communityUtilMap.get('CommunityName')].id;
        return String.valueOf(networkId);
    }
    //Added on 18th Sep 2018 by Vikas to prepare a map of SC Community Utility metadata
    private static Map<String,String> prepareMetadataMap(){
        Map<String,String> communityUtilMap = new Map<String,String>();
        for(SC_CommunityUtility__mdt commUtil: [select Value__c, MasterLabel from SC_CommunityUtility__mdt])
        {
            communityUtilMap.put(commUtil.MasterLabel, commUtil.Value__c);
        }
       return communityUtilMap;
    }
    @AuraEnabled
    public static PGN_PageInfo getPageCountInfo(String pageCountInfo, String dataCategoryId, String searchString,String pageNumber,String currnetPagesCount){
        PGN_PageInfo pgn = new PGN_PageInfo(); 
        try
        {
            Integer currentListCount = pageCountInfo != null && pageCountInfo != '' ? Integer.valueOf(pageCountInfo) : 10;
            if(String.isEmpty(searchString))
            {
                Integer blogCount = 0;
                for(Customer_Community_Document__c eachDocument : [select id,Group_Id__c,Share_With_Group_Ids__c from Customer_Community_Document__c]){
                    if(!String.isEmpty(eachDocument.Group_Id__c)){
                        if(eachDocument.Group_Id__c.contains(dataCategoryId)){
                            blogCount++;
                        }
                    }
                }
                if(blogCount > 0)
                {
                    if(math.mod(blogCount, currentListCount) != 0)
                        pgn.totalPages = (blogCount/currentListCount)+1;
                    else
                        pgn.totalPages = (blogCount/currentListCount);
                }
            }
            else
            {
                List<SC_CommunityWrapper> finalSearchedList = fetchCommunityDocuments(searchString,dataCategoryId,pageNumber,currnetPagesCount);
                if(finalSearchedList != null)
                {
                    if(math.mod(finalSearchedList[0].totalRecords, currentListCount) != 0)
                        pgn.totalPages = (finalSearchedList[0].totalRecords/currentListCount)+1;
                    else
                        pgn.totalPages = (finalSearchedList[0].totalRecords/currentListCount);
                }
            }
            pgn.currentPageNumber = 1;
            List<Integer> cnt = new List<Integer>();
            for(Integer loop_var = 0;loop_var < pgn.totalPages;loop_var++){
                cnt.add(loop_var+1);
                if((loop_var+1) == 4)
                    break;
            }
            //Commented on 25th Apr to not display the last page number
            //if(pgn.totalPages > 4)
            //cnt.add(pgn.totalPages);
            pgn.pageCounter = cnt;
        }
        catch(exception e)
        {
            system.debug('exception : '+e);
        }
        return pgn;        
    }
    
    @AuraEnabled
    public static PGN_PageInfo getPageCountChange(String pageNumber,String currnetPagesCount,String totalPages){
        PGN_PageInfo pgn = new PGN_PageInfo();
        pgn.currentPageNumber = Integer.valueOf(pageNumber);
        pgn.totalPages = Integer.valueOf(totalPages);
        
        List<Integer> cnt = new List<Integer>();
        
        if((Integer.valueOf(pageNumber)+2) < Integer.valueOf(totalPages) && Integer.valueOf(pageNumber) != 1){
            for(Integer loop_var = (Integer.valueOf(pageNumber)-1);loop_var < (Integer.valueOf(pageNumber)+3);loop_var++){
                cnt.add(loop_var);
            }
            //cnt.add(pgn.totalPages);//Commented on 25th Apr to not display the last page number
            
        }else if(Integer.valueOf(pageNumber) == 1){
            for(Integer loop_var = 1;loop_var < Integer.valueOf(totalPages);loop_var++){
                cnt.add(loop_var);
                if((loop_var) == 5)
                    break;
            }
            //cnt.add(pgn.totalPages);//Commented on 25th Apr to not display the last page number
        }else{
            if(Integer.valueOf(currnetPagesCount) >= pgn.totalPages){
                for(Integer loop_var = 1;loop_var < (pgn.totalPages+1);loop_var++){
                    cnt.add(loop_var);
                }
            }else{
                for(Integer loop_var = (pgn.totalPages-4);loop_var < (pgn.totalPages+1);loop_var++){
                    cnt.add(loop_var);
                }
            }
        }
        pgn.pageCounter = cnt;
        return pgn;
    }
}