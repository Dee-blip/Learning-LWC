/******
 * Description : Controller class for the lightning component "CommunityBlogList"
 * Author : Vikas R
 * Test Class : CommunityBlogCtrlTest
 * @History
    --Developer       --Date          --Change
    Vikas             23-May-2018      ESESP-1318:Edit permission for comment is given using UserRecordAccess object
    Vikas             18-Sep-2018      ESESP-1678:Fetch community Id
    Pinkesh           16-Jan-2018      ESESP-1602: Akatec Lightning Migration
******/
public class CommunityBlogCtrl {
    @AuraEnabled
    public static String createBlogRecord(Knowledge__kav blogrecord, String dataCategoryId){
        if(blogrecord.Description__c != null){
            String descLength = String.valueOf(blogrecord.Description__c.length()); 
            if(blogrecord.Description__c.length() >= 131072){
                return 'SIZEERROR'+descLength;
            }
            else{
                String returnURL = new CommunityBlogCtrl().saveBlog(blogrecord, dataCategoryId);
                return returnURL;
            }
        }
        else{
            String returnURL = new CommunityBlogCtrl().saveBlog(blogrecord, dataCategoryId);
            return returnURL;
        }
    }
    private String saveBlog(Knowledge__kav blogrecord, String dataCategoryId){
        String topicName = '';
        List<Knowledge__kav> newBlogrecord = new List<Knowledge__kav>();
        Knowledge__kav draftBlog = new Knowledge__kav();
        try{
            if(blogrecord != null){
                draftBlog = blogrecord;
                newBlogrecord = [select id,title,createdby.Name,createddate,UrlName,Community_Blog_Navigational_Topic__c,Description__c,KnowledgeArticleId,IsVisibleInCsp,IsVisibleInPkb,IsVisibleInPrm
                                 from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' and id=:blogrecord.id limit 1];
                
                if(newBlogrecord.size() > 0)
                {
                    if(draftBlog.IsVisibleInCsp == true)
                        draftBlog.IsVisibleInPrm = true;
                    if(draftBlog.IsVisibleInCsp == false)
                        draftBlog.IsVisibleInPrm = false;
                    String newBlogId = KbManagement.PublishingService.editOnlineArticle(String.valueOf(newBlogrecord[0].KnowledgeArticleId),true);
                    draftBlog.id = newBlogId;
                    draftBlog.Community_Blog_AKAM_Last_Modified_By__c = userinfo.getUserId();
                    draftBlog.AKAM_Modified_Date__c = system.now();
                    /* Pinkesh : Commmenting Attachment's part because Lightning supports only File
                    if(!String.isEmpty(attachName))
                        draftBlog.Attachments__Name__s = attachName;
                    if(!String.isEmpty(attachType))
                        draftBlog.Attachments__ContentType__s = attachType;
                    if(!String.isEmpty(attachBody))
                        draftBlog.Attachments__Body__s = EncodingUtil.base64Decode(attachBody);
                    */
                    update draftBlog;
                    KbManagement.PublishingService.publishArticle(newBlogrecord[0].KnowledgeArticleId, true);
                }
                
                if(!String.isBlank(dataCategoryId))
                {
                    topicName = [Select name from topic where id=:(Id.valueOf(dataCategoryId))].Name;
                    blogrecord.Community_Blog_Navigational_Topic__c  = topicName;
                    
                    Id communityBlogRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('Community_Blog').getRecordTypeId();
                    blogrecord.RecordTypeId = communityBlogRecordTypeId;
                    
                    if(blogrecord.IsVisibleInCsp == true)
                        blogrecord.IsVisibleInPrm = true;
                    if(blogrecord.IsVisibleInCsp == false)
                        blogrecord.IsVisibleInPrm = false;
                    String urlName = topicName+'-'+blogrecord.Title+'-'+String.valueOf(system.now());
                    urlName = urlName.replaceAll('[^a-zA-z0-9]','');
                    blogrecord.UrlName = urlName;
                    blogrecord.Community_Blog_AKAM_Created_By__c = userinfo.getUserId();
                    blogrecord.Community_Blog_AKAM_Last_Modified_By__c = userinfo.getUserId();
                    blogrecord.Community_Blog_AKAM_Created_Date__c = system.now();
                    blogrecord.AKAM_Modified_Date__c = system.now();
                    /* Pinkesh : Commmenting Attachment's part because Lightning supports only File
                    if(!String.isEmpty(attachName))
                        blogrecord.Attachments__Name__s = attachName;
                    if(!String.isEmpty(attachType))
                        blogrecord.Attachments__ContentType__s = attachType;
                    if(!String.isEmpty(attachBody))
                        blogrecord.Attachments__Body__s = EncodingUtil.base64Decode(attachBody);
                    */
                    insert blogrecord;
                    
                    blogrecord = [SELECT id,UrlName,KnowledgeArticleId FROM Knowledge__kav WHERE RecordType.DeveloperName = 'Community_Blog' AND Id = :blogrecord.Id];
                    KbManagement.PublishingService.publishArticle(blogrecord.KnowledgeArticleId, true);
                }
            }
        } 
        catch (Exception ex){
            system.debug('******AN EXCEPTION : '+ex.getMessage()+' OCCURED AT : '+ex.getLineNumber()+' of class CommunityBlogCtrl ******');
        }
        return String.valueOf(blogrecord.UrlName);
    }
    @AuraEnabled
    public static Knowledge__kav fetchBlogRecord(String blogId){
        /* Pinkesh : Removing Attachment from the query because Lightning supports only File
        return [select id,title,createdby.Name,createddate,UrlName,Community_Blog_Navigational_Topic__c,Community_Blog_Description__c,IsVisibleInCsp,IsVisibleInPkb,IsVisibleInPrm,Attachments__Name__s from Community_Blog__kav where id=:id.valueOf(blogId) limit 1];
        */
        return [select id,title,createdby.Name,createddate,UrlName,Community_Blog_Navigational_Topic__c,Description__c,IsVisibleInCsp,IsVisibleInPkb,IsVisibleInPrm from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' AND id=:id.valueOf(blogId) limit 1];
    }
    @AuraEnabled
    public static String deleteBlogRecord(String blogId){
        List<id> kbArticleIdList = new List<id>();
        String topicName;
        for (Knowledge__kav kav : [select id,KnowledgeArticleId,Community_Blog_Navigational_Topic__c from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' AND id=:id.valueOf(blogId)])
        {
            topicName = kav.Community_Blog_Navigational_Topic__c;
            kbArticleIdList.add(kav.knowledgeArticleId);
            KbManagement.PublishingService.archiveOnlineArticle(kav.knowledgeArticleId,null);
        }
        Id topicId = [Select id from topic where name =: topicName and networkId in(select id from network where name = 'Customer Community')].id;
        List<Community_Blog_Comment__c> updateCommentList = new List<Community_Blog_Comment__c>();
        for(Community_Blog_Comment__c thisComment : [Select id from Community_Blog_Comment__c where Community_Blog_Id__c in:(kbArticleIdList)]){
            thisComment.Deleted__c = true;
            updateCommentList.add(thisComment);
        }
        update updateCommentList;
        return String.valueOf(topicId);
    }
    @AuraEnabled
    public static Boolean checkAccess(){
        Profile p = [select name from Profile where id =:UserInfo.getProfileId()];
        Map<String,String> communityUtilMap = prepareMetadataMap();
        if(p.name != communityUtilMap.get('CommuntiyGuestProfile') && UserInfo.getOrganizationName().contains(communityUtilMap.get('CompanyName'))
           && UserInfo.getUserEmail().contains(communityUtilMap.get('CompanyEmail'))){
               return true;
           }
        else
            return false;
    }
    @AuraEnabled
    public static Boolean checkBlogType(String blogURL){
        Boolean isBlogType = false;
        List<Knowledge__kav> blogRecord = [Select id,Community_Blog_AKAM_Created_By__c,Createdbyid,ownerid from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' AND urlName =:blogURL];
        if(blogRecord.size() > 0)
            isBlogType = true;
        return isBlogType;
    }
    @AuraEnabled
    public static Boolean checkKBAccess(){
        Boolean hasKbAccess = false;
        Map<String,String> communityUtilMap = prepareMetadataMap();
        if(UserInfo.getOrganizationName().contains(communityUtilMap.get('CompanyName'))
           && UserInfo.getUserEmail().contains(communityUtilMap.get('CompanyEmail'))){
               hasKbAccess = [select UserPermissionsKnowledgeUser from user where id =:userinfo.getUserId()].UserPermissionsKnowledgeUser;
           }
        return hasKbAccess;
    }
    @AuraEnabled
    public static Boolean checkAdminAccess(String blogURL){
        Boolean hasAdminAccess = false;
        List<String> permissionSetIdList = new List<String>();
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PermissionSetToEditGrpDoc__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id adminId = [Select id from Profile where Name = 'System Administrator'].id;
        if(communityMdt.PermissionSetToEditGrpDoc__c != null)
            permissionSetIdList = communityMdt.PermissionSetToEditGrpDoc__c.split(',');
        List<PermissionSetAssignment> userPermission =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id FROM PermissionSetAssignment WHERE PermissionSetId IN:(permissionSetIdList) and AssigneeId =: userinfo.getUserId() LIMIT 1]);
        List<Knowledge__kav> blogRecord = [Select id,Community_Blog_AKAM_Created_By__c,Createdbyid,ownerid from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' AND urlName =:blogURL];
        if(blogRecord.size() > 0){
            if(blogRecord[0].Community_Blog_AKAM_Created_By__c == userinfo.getUserId() || blogRecord[0].OwnerId == userinfo.getUserId())
                hasAdminAccess = true;
        }
        if(userPermission.size() > 0 || userinfo.getProfileId() == adminId){
               hasAdminAccess = true;
           }
        return hasAdminAccess;
    }
    //Commented by VIKAS
    /*@AuraEnabled
    public static Boolean fetchArticleType(String articleId){
        list<UserRecordAccess> uRaList= [Select RecordId, HasEditAccess, HasDeleteAccess, HasAllAccess From UserRecordAccess Where UserId =:UserInfo.getUserId() AND RecordId =:(id.valueOf(articleId))];
        return uRaList[0].HasAllAccess;
        List<Community_Blog__kav> blogList = new List<Community_Blog__kav>();
        blogList = [select id,AKAM_Created_By__c.Id from Community_Blog__kav where id=:id.valueOf(articleId)];
        if(blogList.size() > 0 && userinfo.getUserId() == blogList[0].AKAM_Created_By__c.id)
            return 'true';
        else
            return 'false';
    }*/
    @AuraEnabled
    public static SC_CommunityWrapper fetchCommunityBlogs(String searchString, String dataCategoryId,String pageNumber,String currnetPagesCount)
    {
        String topicName = '';
        String publishedStatus = 'Online';
        String language = 'en_US';
        List<Knowledge__kav> finalSearchedList = new List<Knowledge__kav>();
        SC_CommunityWrapper communityWrapper = new SC_CommunityWrapper();
        communityWrapper.allBlogList = new List<Knowledge__kav>();
        communityWrapper.totalRecords = 0;
        Integer totalRecords = 0;
        if(!String.isEmpty(dataCategoryId))
            topicName = [Select name from topic where id=:(Id.valueOf(dataCategoryId))].Name;
        topicName = String.escapeSingleQuotes(topicName);
        String blogQuery = 'select id,title,Community_Blog_AKAM_Created_By__r.name, Community_Blog_AKAM_Created_Date__c, createdby.Name,createddate,UrlName,Community_Blog_Navigational_Topic__c from Knowledge__kav where RecordType.DeveloperName = \'Community_Blog\' AND Community_Blog_Navigational_Topic__c IN( \''+topicName+ '\') AND PublishStatus = \''+publishedStatus+'\'  AND language = \''+language+'\' '; 
        if(!String.isEmpty(searchString)){
            String searchFields = [select Value__c from SC_CommunityUtility__mdt where MasterLabel=: 'CommunitySearchFields' limit 1].Value__c;
            blogQuery+= 'AND (';
            for(String searchField : searchFields.split(',')){
                blogQuery+= searchField+' like \'%'+searchString+'%\' OR '; 
            }
            blogQuery = blogQuery.substring(0,blogQuery.length()-3);//To remove the extra OR   
            blogQuery+= ') ORDER BY Community_Blog_AKAM_Created_Date__c desc LIMIT '+currnetPagesCount+' OFFSET ';
        }
        else{
            blogQuery+= 'ORDER BY Community_Blog_AKAM_Created_Date__c desc LIMIT '+currnetPagesCount+' OFFSET ';
        }
        finalSearchedList = database.query(blogQuery.substringBefore('ORDER BY'));
        totalRecords = finalSearchedList.size();
        finalSearchedList = new List<Knowledge__kav>();
        if(String.isBlank(pageNumber) || Integer.valueOf(pageNumber) == 1){
            blogQuery = blogQuery + ' 0';
        }else{
            blogQuery = blogQuery + String.valueOf((Integer.valueOf(pageNumber)-1)*Integer.valueOf(currnetPagesCount));
        }
        finalSearchedList = Database.query(blogQuery);
        communityWrapper.allBlogList.addAll(finalSearchedList);
        communityWrapper.totalRecords = totalRecords;
        return communityWrapper;
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
            if(String.isEmpty(searchString)){
                String topicName = [Select name from topic where id=:(Id.valueOf(dataCategoryId))].Name;
                Integer blogCount = 0;
                for(Knowledge__kav commBlog: [Select id,Community_Blog_Navigational_Topic__c from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' AND PublishStatus = 'Online' AND Language = 'en_US']){
                    if(commBlog.Community_Blog_Navigational_Topic__c != null && topicName != null){
                        if(commBlog.Community_Blog_Navigational_Topic__c.equalsIgnoreCase(topicName)){
                            blogCount++;
                        }
                    }
                }
                if(blogCount > 0){
                    if(math.mod(blogCount, currentListCount) != 0)
                        pgn.totalPages = (blogCount/currentListCount)+1;
                    else
                        pgn.totalPages = (blogCount/currentListCount);
                }
            }
            else{
                SC_CommunityWrapper communityWrapper = fetchCommunityBlogs(searchString,dataCategoryId,pageNumber,currnetPagesCount);
                if(communityWrapper.totalRecords != 0){
                    if(math.mod(communityWrapper.totalRecords, currentListCount) != 0)
                        pgn.totalPages = (communityWrapper.totalRecords/currentListCount)+1;
                    else
                        pgn.totalPages = (communityWrapper.totalRecords/currentListCount);
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
        catch(exception ex){
            system.debug('******AN EXCEPTION : '+ex.getMessage()+' OCCURED AT : '+ex.getLineNumber()+'******');
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
        }
        else if(Integer.valueOf(pageNumber) == 1){
            for(Integer loop_var = 1;loop_var < Integer.valueOf(totalPages);loop_var++){
                cnt.add(loop_var);
                if((loop_var) == 5)
                    break;
            }
            //cnt.add(pgn.totalPages);//Commented on 25th Apr to not display the last page number
        }
        else{
            if(Integer.valueOf(currnetPagesCount) >= pgn.totalPages){
                for(Integer loop_var = 1;loop_var < (pgn.totalPages+1);loop_var++){
                    cnt.add(loop_var);
                }
            }
            else{
                for(Integer loop_var = (pgn.totalPages-4);loop_var < (pgn.totalPages+1);loop_var++){
                    cnt.add(loop_var);
                }
            }
        }
        pgn.pageCounter = cnt;
        return pgn;
    }
    
    public String getDataCategoryApiName(String dataCategoryName){
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        String categoryApiName =  null;
        try {
            //Making the call to the describeDataCategoryGroups to
            //get the list of category groups associated
            List<String> objType = new List<String>();
            objType.add('KnowledgeArticleVersion');
            describeCategoryResult = Schema.describeDataCategoryGroups(objType);
            
            //Creating a list of pair objects to use as a parameter
            //for the describe call
            List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
            
            //Looping throught the first describe result to create
            //the list of pairs for the second describe call
            for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
                if(singleResult.getName() == 'Blog'){
                    DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                    p.setSobject(singleResult.getSobject());
                    p.setDataCategoryGroupName(singleResult.getName());
                    pairs.add(p);
                }
            }
            if(pairs.size() > 0){
                //describeDataCategoryGroupStructures()
                describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
                //Getting data from the result
                for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
                    //Get the name of the data category group
                    singleResult.getName();
                    //Get the top level categories
                    DataCategory [] toplevelCategories =  singleResult.getTopCategories();
                    //Recursively get all the categories
                    List<DataCategory> allCategories = getAllCategories(toplevelCategories);
                    //dataCategoryList.addAll(allCategories);
                    for(DataCategory category : allCategories) {
                        //Get the name of the category
                        if(category.getLabel() == dataCategoryName)
                            categoryApiName = category.getName();
                    }
                }
            }
        } 
        catch (Exception ex){
            system.debug('******AN EXCEPTION : '+ex.getMessage()+' OCCURED AT : '+ex.getLineNumber()+'******');
        }
        return categoryApiName;
    }
    
    public  DataCategory[] getAllCategories(DataCategory [] categories){
        if(categories.isEmpty()){
            return new DataCategory[]{};
        } 
        else {
            DataCategory [] categoriesClone = categories.clone();
            DataCategory category = categoriesClone[0];
            DataCategory[] allCategories = new DataCategory[]{category};
                categoriesClone.remove(0);
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(getAllCategories(categoriesClone));
            return allCategories;
        }
    }

    public class JSONCategory{
        public String label{set;get;}
        public String name{set;get;}
        public List<TopLevelCategory> topCategories{set;get;}
    }
    
    public class TopLevelCategory{
        public List<ChildLevelCategory> childCategories{set;get;}
    }
    
    public class ChildLevelCategory{
        public List<ChildLevelCategory> childCategories{set;get;}
        public String label{set;get;}
        public String name{set;get;}
    }
    @AuraEnabled
    public static String uploadFile(String blogRecordId, String fileName, String base64Data, String contentType) {
        Knowledge__kav blogrecord;
        try{
            blogrecord = [select id, KnowledgeArticleId from Knowledge__kav where RecordType.DeveloperName = 'Community_Blog' and id=:blogRecordId limit 1];
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in Community Blog uploadFile method: ', e.getMessage(), e.getStackTraceString());
            return e.getMessage() +' : '+ e.getStackTraceString() +' : '+ e.getLineNumber();
        }
        
        String newBlogId;
        try{
            newBlogId = KbManagement.PublishingService.editOnlineArticle(blogrecord.KnowledgeArticleId,true);
        }catch(Exception e){
            KbManagement.PublishingService.deleteDraftArticle(blogrecord.KnowledgeArticleId);
            newBlogId = KbManagement.PublishingService.editOnlineArticle(blogrecord.KnowledgeArticleId,true);
        }
         
        try{
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
            contentVersion.PathOnClient = fileName; // The files name, extension is very important here which will help the file in preview.
            contentVersion.Title = fileName; // Display name of the files
            contentVersion.VersionData = EncodingUtil.base64Decode(base64Data); // converting your binary string to Blob
            insert contentVersion;
            
            //Getting ContentDocument Id
            Id contentDocumentId = [Select Id, ContentDocumentId from ContentVersion where Id =:contentVersion.Id limit 1].ContentDocumentId;
                
            //Create ContentDocumentLink
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocumentId;
            contentDocumentLink.LinkedEntityId = newBlogId; // draft article id
            contentDocumentLink.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
            
            KbManagement.PublishingService.publishArticle(blogrecord.KnowledgeArticleId, true);
        }catch(Exception e){
            SC_Jarvis_utility.sendErrorMails('Error in Community Blog uploadFile method: ', e.getMessage(), e.getStackTraceString());
            return e.getMessage() +' : '+ e.getStackTraceString() +' : '+ e.getLineNumber();
        }
        
        return 'success';
    }
}