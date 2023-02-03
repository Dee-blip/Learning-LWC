/* 
Author          : Sumukh SS/Sharath P
Description     : Controller for Community Comment Functionality

Date                    Developer                   JIRA #                      Description                                                       
-------------------------------------------------------------------------------------------------------------------------------------
15 Mar 2021             Authors                     ESESP-5085                  Initial Development
01 Dec 2021             Harshil                     ESESP-6070                  Check #days since case closed to disable new comments
18 Jan 2022             Aravind                     ESESP-6209                  Added body preview for email comments
18 Jan 2022             Harshil                     ESESP-6553                  Removing Jarvis Logic filter
22 Feb 2022             Aravind                     ESESP-6620                  Modified case status update logic
08 Feb 2022             Jay                         ESESP-6503                  Added method to get EmailMessage record and its attachments
08 Feb 2022             Jay                         ESESP-6277                  Last_Case_Update__c field should get populated when commnent is added by community user
03 March                Vishnu M                    ESESP-6834                  Remapped createdby UI parameter to use Commented_by_user__c field
10 Mar 2022             Jay Rathod                  ESESP-6799                  Updated logic to identify community comment record as isCustomer
29 Apr 2022             Harshil                     ESESP-7094                  Added file size and extension to file comment type
-------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class SC_CommunityCommentController {
    
    public class MainCommentWrapper{ 
        @AuraEnabled public string commentId; 
        @AuraEnabled public string commentBody; 
        @AuraEnabled public string commentedBy; 
        @AuraEnabled public string createdBy;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public boolean isOutboundMessage=false;
        @AuraEnabled public boolean isInboundMessage=false;
        @AuraEnabled public boolean isCustomerComment=false;
        @AuraEnabled public String styleOverride;
        @AuraEnabled public boolean isFile=false;
        @AuraEnabled public boolean isEmail=false;
        @AuraEnabled public boolean isImage=false;
        @AuraEnabled public boolean isText=false;
        @AuraEnabled public string chatType; // text, image, file
        @AuraEnabled public boolean doesMessageContainImage=false; 
        @AuraEnabled public list<RecordWrapper> relatedRecords = new List<RecordWrapper>();
        public mainCommentWrapper( Community_Comments__c comment) {

            String createdBy;

            
            if(comment.Type__c == 'Email' && String.isNotBlank(comment.Posted_By_Email__c)) {
                createdBy = comment.Posted_By_Email__c; 
            } else {
                // ESESP-6834 - createdby is mapped to Commented_by_user__c field
                createdBy = comment.Commented_By__c == 'Internal User'
                                    ?  comment.Commented_By_User__c + ' (Akamai)'
                                    : comment.Commented_By_User__c;
            }

            this.commentId = comment.Id;
            this.commentBody = comment.Comment__c;
            this.commentedBy = comment.Commented_By__c;
            this.createdDate = comment.AKAM_Created_Date__c;//.format();
            this.createdBy = createdBy;
            this.isOutboundMessage = comment.AKAM_Created_By__c == userinfo.getUserId();
            this.isInboundMessage = !this.isOutboundMessage;
            if(comment.Application__c == 'JARVIS') {
                //ESESP-6944 -> Case Comments Allignment & Color
                this.isCustomerComment = comment.CreatedByUserType__c != 'Standard' || (!String.isBlank(comment.AKAMCreatedByUserType__c) && comment.AKAMCreatedByUserType__c != 'Standard') || (!String.isBlank(comment.Posted_By_Email__c) && !comment.Posted_By_Email__c.endsWithIgnoreCase('@akamai.com')) || comment.Commented_By__c == 'Customer';
                if((userinfo.getUserType() == 'Standard' && this.isCustomerComment) || (userinfo.getUserType() != 'Standard' && !this.isCustomerComment)){
                    this.styleOverride = 'grey';
                    this.isOutboundMessage = False;
                }
                else {
                    this.styleOverride = 'blue';
                    this.isOutboundMessage = True;
                }
                this.isInboundMessage = !this.isOutboundMessage;
                
            }
            this.chatType = comment.Type__c;
            if(comment.Type__c == 'File') {
                this.isFile = true;
                this.addFiles(comment.Comment__c);
            } else if(comment.Type__c == 'Email') {
                this.isEmail = true;
                this.addEmail(comment.Comment__c);
            } else if(comment.Comment__c !=null && comment.Comment__c.contains('<img')){
                this.isImage = true;
            } else {
                this.isText = true;
            }
        }
        void addFiles(String fileComment) {

            for(string eachfile : fileComment.split(',')) {
                string fileName = eachfile.split('/')[0];
                string docID = eachfile.split('/')[1];
                
                relatedRecords.add(new RecordWrapper(fileName, docID));
            }
        }
        void addEmail(String emailComment) {
            String delimiter = '__';
            Integer delimitterIndex = emailComment.indexOf(delimiter);
            String emaiLId = emailComment.substring(0, delimitterIndex);
            String emailSub = emailComment.substring(delimitterIndex + delimiter.length(), emailComment.length());
            
            relatedRecords.add(new RecordWrapper(emailSub, emaiLId));
        }
    }    
    
    public class RecordWrapper {
        @AuraEnabled public string id;
        @AuraEnabled public string name;
        @AuraEnabled public string preview;
        //ESESP-7094 - added variables
        @AuraEnabled public string fileSize;
        @AuraEnabled public string fileExtension;
        recordWrapper(String name, String id) {
            this.id = id;
            this.name = name;
        }
    }
    
    @AuraEnabled
    public static list<MainCommentWrapper> getCommentDetails(Id parentid, string application, string parentobject, String visibility)
    {
        List<MainCommentWrapper> mainCommentWrapperList=new list<MainCommentWrapper>();

        if(application == 'JARVIS') {

            List<UserRecordAccess> recReadAccess = [SELECT RecordId 
                                                            FROM UserRecordAccess 
                                                            where RecordId  = :parentid and 
                                                            UserId = :userinfo.getUserId() and
                                                            HasReadAccess = true];
            //ESESP-6553 Removing apply_jarvis_logic__c from where clause
            List<Case> jarvisCase = [select id, do_not_show_in_portal__c from Case where id = :parentid];

            if(recReadAccess.isEmpty() || jarvisCase.isEmpty()) {
                throw new AuraHandledException('No Access');
            }

            List<Id> emailIdList = new List<Id>();
            List<Id> contentDocumentIdList = new List<Id>();
            for(Community_Comments__c eachCommentrec : [select Id,CreatedByUserType__c,AKAMCreatedByUserType__c, Comment__c, Commented_By__c, AKAM_Created_By__c, Akam_created_by__r.Name,
                                        Commented_By_User__c, Posted_By_Email__c, Application__c, CreatedBy.UserType, AKAM_Created_Date__c, Type__c
                from Community_Comments__c 
                where Parent_ID__c =:parentid 
                    and Visibility__c =:visibility 
                    and Application__c =:application 
                    and Related_Object__c=:parentobject  
                order by AKAM_Created_Date__c asc]) 
            {
                mainCommentWrapperList.add(new MainCommentWrapper(eachCommentrec));
                if(eachCommentrec.Type__c == 'Email') {
                    emailIdList.add(eachCommentrec.Comment__c.substringBefore('__'));
                }
                //ESESP-7094
                if(eachCommentrec.Type__c == 'File') {
                    contentDocumentIdList.add(eachCommentrec.Comment__c.split('/')[1]);
                }
            }
            Map<Id, EmailMessage> emailBodyMap = new Map<Id, EmailMessage>([SELECT Id, TextBody FROM EmailMessage WHERE Id IN :emailIdList]);
            //ESESP-7094 - Query file details
            Map<Id, ContentDocument> fileMap = new Map<Id, ContentDocument>([SELECT Id, LatestPublishedVersion.File_Size__c, fileExtension FROM ContentDocument WHERE Id IN :contentDocumentIdList]);
            for(MainCommentWrapper comment : mainCommentWrapperList) {
                if(comment.isEmail) {
                    for(RecordWrapper eml : comment.relatedRecords) {
                        eml.preview = emailBodyMap.get(eml.id).TextBody.trim().replaceAll('\\[cid:.+\\]', '[image]').replaceAll('\\s', ' ').replaceAll('  +', ' ');
                    }
                }
                //ESESP-7094 - Set file details
                if(comment.isFile) {
                    for(RecordWrapper file : comment.relatedRecords) {
                        ContentDocument contentDoc = fileMap.get(file.id);
                        file.fileSize = contentDoc.LatestPublishedVersion.File_Size__c;
                        file.fileExtension = (contentDoc.fileExtension != null) ? contentDoc.fileExtension : System.Label.Jarvis_EmailMessage_Unknown;
                    }
                }
            }
        } else {
            mainCommentWrapperList = SC_Jarvis_utility.getCommentDetails(parentid, application, parentobject, visibility);
        }
        
        return mainCommentWrapperList;
    }
    
    static final Map<String, String> COMM_SAVE_CLASS = new Map<String, String> {
                                                                'JARVIS' => 'SC_CommunityCommentController.Jarvis_CommCommentLogic', 
                                                                'CHIME' => 'SC_CommunityCommentController.Chime_CommCommentLogic'
                                                            };
        @AuraEnabled
        public static void insertnewComment(string parentid, string application, string parentobject,string comment, string visibility)
    {
        String logicClassName = COMM_SAVE_CLASS.get(application.toUpperCase());
        
        if(String.isBlank(logicClassName)) {
            logicClassName = 'SC_CommunityCommentController.Vritual_CommCommentLogic';
        }
        
        Type commSaveType = Type.forName(logicClassName);
        Vritual_CommCommentLogic commLogic  = (Vritual_CommCommentLogic)commSaveType.newInstance();
        commLogic.saveComment( parentid, application, parentobject, comment, visibility);
    }
    
    // For calculating access details to hide / show the comment text box.
    
    public class OnLoadCommentWrapper
    {
        @AuraEnabled public boolean isCommunityLoad=false;
        @AuraEnabled public boolean userHasWriteAccess=false;
        @AuraEnabled public boolean isCustomerCase = false;
        //ESESP-6553 - Not used anymore - Commenting out 
        //@AuraEnabled public boolean isInScope = false;
        //ESESP-6070 - Added variable in wrapper
        @AuraEnabled public boolean isCaseClosed = false;
    }
    
    @AuraEnabled (cacheable=true)
    public static OnLoadCommentWrapper onLoadDetails(string caseid)
    {
        OnLoadCommentWrapper subOnLoadCommentWrapper = new OnLoadCommentWrapper();
        //ESESP-6070 - Added field for query
        case caserec = [select recordtype.name,do_not_show_in_portal__c, Apply_Jarvis_Logic__c, Status, AKAM_Closed_Date__c from case where id = :caseid];
        

        subOnLoadCommentWrapper.isCustomerCase = !caserec.do_not_show_in_portal__c;
        //ESESP-6553 - Not used anymore - Commenting out 
        //subOnLoadCommentWrapper.isInScope = caserec.Apply_Jarvis_Logic__c;

        //ESESP-6070 - Start of changes
        if(caserec.AKAM_Closed_Date__c != null && caserec.Status.containsIgnoreCase('closed')){
            subOnLoadCommentWrapper.isCaseClosed = SC_Jarvis_utility.getDaysSinceClosed(caserec.AKAM_Closed_Date__c) > 14 ? true : false;
        }
        else {
            subOnLoadCommentWrapper.isCaseClosed = false;
        }
        //End of changes
        
        //ESESP-6553 - Removing jarvis logic variable from condition
        //if(!subOnLoadCommentWrapper.isCustomerCase || !subOnLoadCommentWrapper.isInScope) {
        if(!subOnLoadCommentWrapper.isCustomerCase) {
            return subOnLoadCommentWrapper;
        }

        Id siteId = Site.getSiteId(); 

        if (siteId != null) 
        {
            subOnLoadCommentWrapper.isCommunityLoad=true;
            string recordtypename = caserec.recordtype.name;
            
            switch on recordtypename {
                when 'Managed Security' {		
                    subOnLoadCommentWrapper.userHasWriteAccess=true;
                }	
                when 'Emerging Products Engineering','Technical','Professional Services','AMG','Billing' {		
                    List<UserRecordAccess> recEditAccess = [SELECT RecordId 
                                                            FROM UserRecordAccess 
                                                            where RecordId  = :caseid and 
                                                            UserId = :userinfo.getUserId() and
                                                            HasEditAccess = true];
                    subOnLoadCommentWrapper.userHasWriteAccess = recEditAccess.size() > 0;  
                }
            }
        }
        else //For internal Users
        {
            subOnLoadCommentWrapper.isCommunityLoad=false; 
            //ESESP-6553 - changing to true, removing jarvis logic dependency
            subOnLoadCommentWrapper.userHasWriteAccess = true;
        }
        
        return subOnLoadCommentWrapper;
    }

    @AuraEnabled
    public static void insertnewFileComment(string parentid, string application, string parentobject,string comment)
    {
        String logicClassName = COMM_SAVE_CLASS.get(application.toUpperCase());
        if(String.isBlank(logicClassName)) {
            logicClassName = 'SC_CommunityCommentController.Vritual_CommCommentLogic';
        }
        
        Type commSaveType = Type.forName(logicClassName);
        Vritual_CommCommentLogic commLogic  = (Vritual_CommCommentLogic)commSaveType.newInstance();
        commLogic.insertnewFileComment( parentid, application, parentobject, comment);
    }

    @AuraEnabled (cacheable=true)
    public static EmailMessage getEmailBody(Id emailId) {
        EmailMessage emsg = [select id, FromAddress, CcAddress, ToAddress, Subject, HtmlBody from EmailMessage  where Id = :emailId];
        return emsg;
    }

    //ESESP-6503
    @AuraEnabled (Cacheable=true)
    public static Map<String,Object> getEmail(Id emailId) {
        Map<String,Object> message = new Map<String, Object>();
        if (!String.isBlank(emailId)) {
            EmailMessage eM = [SELECT Id, FromAddress, CcAddress, ToAddress, Subject, HtmlBody, TextBody, HasAttachment FROM EmailMessage WHERE Id = :emailId];
            message.put('email', eM);
            Integer attachmentCount = 0;
            if (eM.HasAttachment) {
                attachmentCount = [SELECT COUNT() FROM Attachment WHERE ParentId =: emailId];
            }
            message.put('attachmentCount',attachmentCount);
        }
        return message;
    }

    //ESESP-6503
    @AuraEnabled
    public static List<Map<String,Object>> getAttachments(String parentId){
        String fileBaseUrl = (UserInfo.getUserType() == 'Standard' ? '' : '/customers') + '/servlet/servlet.FileDownload?file=';
        List<Map<String,Object>> attachments = new List<Map<String, Object>>();
        if(!String.isBlank(parentId)){
            for(Attachment att :  [SELECT Id,Name,ContentType,BodyLength FROM Attachment WHERE ParentId=:parentId ORDER BY Name ASC]){
                attachments.add(new Map<String,Object>{
                        'Id' => att.Id,
                        'Name' => att.Name,
                        'ContentType' => att.ContentType,
                        'BodyLength' => att.BodyLength,
                        'Url' => fileBaseUrl+att.Id
                });
            }
        }
        return attachments;
    }

    public virtual Class Vritual_CommCommentLogic {
        public Community_Comments__c newcomment = new Community_Comments__c();

        public virtual void saveComment(string parentid, string application, string parentobject,string comment, string visibility) {
            newcomment = new Community_Comments__c();
            User usr = [select id, Profile.Name, contactid,name from user where id=:userinfo.getUserId()];

            if(parentid != null && parentid.startsWith('500')) {
                Case caserec = [Select Akam_case_id__c, recordtype.name, accountId from case where id = :parentid and accountId != null limit 1];
                if(caserec.recordtype.name == 'AMG' || caserec.recordtype.name == 'Billing') {
                    newcomment.Account_ID_for_Community_Share__c = caserec.accountId;
                }
                newcomment.Parent_Name__c = caserec.Akam_case_id__c;
            }
            newcomment.Visibility__c=visibility;
            newcomment.Contact__c=usr.contactid;
            newcomment.Parent_ID__c=parentid;
            newcomment.Comment__c=comment;
            newcomment.Commented_By__c = UserInfo.getUserType() == 'Standard'
                                            ? 'Internal User': 'Customer';
            newcomment.Application__c =application;
            newcomment.Related_Object__c=parentobject;
            newcomment.AKAM_Created_Date__c=datetime.now();
            newcomment.AKAM_Modified_Date__c=datetime.now();
            newcomment.AKAM_Created_By__c=userinfo.getUserId();
            newcomment.Type__c = comment.contains('<img')?'Image':'Text';
            insert newcomment;
        }
        public virtual void insertnewFileComment(string parentid, string application, string parentobject,string comment)
        {
            string contactid = [select contactid from user where id=:userinfo.getUserId()].contactid;
            Community_Comments__c newcomment = new Community_Comments__c();
            newcomment.Parent_ID__c=parentid;
            newcomment.Contact__c=contactid;
            newcomment.Visibility__c='Public';
            newcomment.Commented_By__c='Informational';
            newcomment.Type__c='Text';
            newcomment.Comment__c=comment;
            newcomment.Application__c =application;
            newcomment.Related_Object__c=parentobject;
            newcomment.AKAM_Created_Date__c=datetime.now();
            newcomment.AKAM_Modified_Date__c=datetime.now();
            newcomment.AKAM_Created_By__c=userinfo.getUserId();
            
            insert newcomment;
        }

    }

    public Class Jarvis_CommCommentLogic extends Vritual_CommCommentLogic implements Queueable {

        public override void saveComment(string parentid, string application, string parentobject,string comment, string visibility) {

            super.saveComment(parentid, application, parentobject, comment, visibility);
            if(UserInfo.getUserType() == 'Standard' ) {
                this.execute(null);
            } else {
                System.enqueueJob(this);
            }
        }
        public override void insertnewFileComment(string parentid, string application, string parentobject,string comment) {
            // Jarvis File Comments will be invoked from trigger
        }

        public void execute(QueueableContext context) {
            try {
                List<String> milestoneNames = new List<String>{'Initial Response', 'Case Update', 'AMG Post Transition Initial Response'};
                Case cs = [select id, AccountId, Recordtype.Name, OwnerId,
                                    (select Id, completionDate, MilestoneType.Name from CaseMilestones
                                                where MilestoneType.Name in :milestoneNames 
                                                    and completionDate = null limit 1)
                                    From Case where Id = :newcomment.parent_id__c];
                
                if(UserInfo.getUserType() == 'Standard' ) {
                    CaseMilestone cmStone = cs.CaseMilestones.size() > 0? cs.CaseMilestones[0]:null;
                    String mileStoneName = cmStone != null? cmStone.MilestoneType.Name:null;
                    Boolean isOwnerUpdate = cs.OwnerId == UserInfo.getUserId();

                    if(cs.recordType.Name == 'Technical' || cs.recordType.Name == 'Emerging Products Engineering') {
                        cs.Last_Case_Update__c = System.now();

                        if(mileStoneName == 'Initial Response') {
                            cs.Next_Action__c = 'Akamai';
                            if(!(String.valueOf(cs.OwnerId).startsWith('00G'))) { // ESESP-6620
                                cs.Status = 'Work in Progress';
                            }
                            cmStone.completionDate = System.now();
                        } else if(mileStoneName == 'Case Update') {
                            cmStone.completionDate = System.now();
                            cs.Next_Action__c = 'Customer';
                        } else {
                            cs.Next_Action__c = 'Customer';
                        }
                    } else if(cs.recordType.Name == 'AMG') {
                        cs.Next_Action__c = 'Customer';
                        cs.Last_Case_Update__c = System.now();
                        if(isOwnerUpdate) {
                            cs.Last_Case_Owner_Update__c = System.now();
                        } else {
                            cs.Last_Non_Case_Owner_Update__c = System.now();
                        }
                        if(mileStoneName == 'Initial Response' || mileStoneName ==  'AMG Post Transition Initial Response') {
                            cmStone.completionDate = System.now();
                            if(!(String.valueOf(cs.OwnerId).startsWith('00G'))) { // ESESP-6620
                                cs.Status = 'Work in Progress';
                            }
                        }
                    } else if(cs.recordType.Name == 'Billing' && isOwnerUpdate) {
                        if(mileStoneName == 'Initial Response') {
                            cmStone.completionDate = System.now();
                        }
                    }
                    if(cmStone != null && cmStone.completionDate != null) {
                        update cmStone;
                    }
                } else {
                    if(cs.Recordtype.Name == 'Technical' || cs.Recordtype.Name == 'Emerging Products Engineering' || cs.Recordtype.Name == 'AMG'){
                        cs.Last_Customer_Activity_Date__c = System.Now();
                        cs.Recent_Update__c = true;
                        cs.Next_Action__c = 'Akamai';
                    }
                    cs.Last_Case_Update__c = System.now();
                }
                cs.Validation_Override__c = true;
                update cs;

                if(newcomment.visibility__c == 'Public') {
                    Task taskForAkamCC = new Task();
                    taskForAkamCC.WhatId = cs.Id;
                    taskForAkamCC.Subject = 'Jarvis Comment';
                    taskForAkamCC.Description = newcomment.Comment__c.replaceAll('\\<.*?\\>', '').abbreviate(10000);
                    taskForAkamCC.Type__c = 'Web Update';
                    taskForAkamCC.Visibility__c = 'Customer';
                    taskForAkamCC.Status = 'Completed';
                    insert taskForAkamCC;
                }
            } Catch(Exception ex) {
                SC_Jarvis_utility.sendErrorMails('ERROR: JARVIS COMMENTS', ex.getStackTraceString(), null);
            }
        }
    }
    
    public without sharing Class Chime_CommCommentLogic extends Vritual_CommCommentLogic{
        public override void saveComment(string parentid, string application, string parentobject,string comment, string visibility) {
            User u = [select id,contactid,name from user where id=:userinfo.getUserId()];
            newcomment.Parent_ID__c=parentid;
            if(u.contactid != null){
                newcomment.Contact__c=u.contactid;
                newcomment.Commented_By__c='Customer';
            }
            else{
                newcomment.Commented_By__c='Internal User';
            }
            newcomment.Visibility__c=visibility;
            newcomment.Comment__c=comment;
            newcomment.Application__c =application;
            newcomment.Related_Object__c=parentobject;
            newcomment.AKAM_Created_Date__c=datetime.now();
            newcomment.AKAM_Modified_Date__c=datetime.now();
            newcomment.AKAM_Created_By__c=userinfo.getUserId();
            newcomment.Type__c = comment.contains('<img')?'Image':'Text';

            insert newcomment;

            CHIME__c ch = [select Id,CHIME_Name__c,CreatedById,CreatedBy.Email,Account__c from CHIME__c where Id =: parentid];
            List<Case> cases = [Select Id,OwnerId,Owner.Email from Case where Chime_Form__c =: ch.Id and Chime_Case_Type__c = 'Integration Case' limit 1];
            List<Case> reviewcases = [Select Id,OwnerId,Owner.Email from Case where Chime_Form__c =: ch.Id and Chime_Case_Type__c = 'Review Case' limit 1];

            if(u.contactid != null){
                list<string> toAddress = new list<string>{ch.CreatedBy.Email};
                if(cases.size()>0)
                    toAddress.add(cases[0].Owner.Email);
                if(reviewcases.size()>0){
                    toAddress.add(reviewcases[0].Owner.Email);
                }
                if(toAddress.size()>0)
                    sendCommNotification(toAddress,ch.CHIME_Name__c,comment,u.Name,'CustomerToInternal',ch.Id);
            }
            else{
                if(visibility=='Public'){
                    List<String> toAddress = new List<String>(); 
                    for(CHIME_Contact__c c : [select Contact__c, Contact__r.Email from CHIME_Contact__c 
                                              where CHIME__c=: parentid and Chime_access__c=true and Contact__r.Email != null]){
                        toAddress.add(c.Contact__r.Email);
                    }
                    if(toAddress.size()>0){
                    	for(AccountTeamMember atm : [select id, TeamMemberRole,userid ,user.email from AccountTeamMember 
                                                 	where Accountid =:ch.Account__c and TeamMemberRole = 'Technical Sales - Primary']){
                			toAddress.add(atm.user.email);
                            toAddress.add(ch.CreatedBy.Email);
                            break;
        				}
                    	sendCommNotification(toAddress,ch.CHIME_Name__c,comment,u.Name,'InternalToCustomer',ch.Id);
                    }
                }
                else if(visibility=='Private'){
                    list<string> toAddress = new list<string>();
                    if(u.id != ch.CreatedById)
                        toAddress.add(ch.CreatedBy.Email);
                    if(cases.size()>0 && cases[0].OwnerId != u.Id)
                        toAddress.add(cases[0].Owner.Email);
                    if(reviewcases.size()>0 && reviewcases[0].OwnerId != u.Id)
                    toAddress.add(reviewcases[0].Owner.Email);
                    if(toAddress.size()>0)
                        sendCommNotification(toAddress,ch.CHIME_Name__c,comment,u.Name,'InternalToInternal',ch.Id);
                }
            }            
        }

        public void sendCommNotification(list<string> toAddress, string chimeName, string comment, string userName, string audience, string chimeId)
        {
            String msg='';
            list<OrgWideEmailAddress> orgWideAddress = [select Id from OrgWideEmailAddress where Address =: GsmUtilClass.getGSMSettingValue('CHIME_OrgWideAddress')];
            String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
            String baseUrlFromPortal = System.URL.getOrgDomainUrl().toExternalForm();
            //String commUrlInstance = ChimeContactClass.getCommunitySiteURL();
            String commUrlInstance='';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddress);
    
            if(audience=='CustomerToInternal')
                mail.setSubject(userName + ' has posted a Comment on '+chimeName);
            else if(audience=='InternalToCustomer')
                mail.setSubject('New Comment added on Technical Requirement Document - '+chimeName);
            else if(audience=='InternalToInternal')
                mail.setSubject('New Comment added on CHIME - '+chimeName);
    
            comment=comment.replace('<p>','');
            comment=comment.replace('</p>','');
            comment=comment.replace('<b>','');
            comment=comment.replace('</b>','');
            comment=comment.replace('<u>','');
            comment=comment.replace('</u>','');
    
            commUrlInstance = commUrlInstance +'chimecustomerform?c__chimeId='+chimeId+'&c__chimeName='+chimeName;
    
            if(audience=='CustomerToInternal')
                msg='<html>You have one new notification from <b>'+userName+'</b> on <a href="'+baseUrlFromPortal+'/'+chimeId+'">'+chimeName+'</a> form.'+'<br/>'+'Comment: '+comment+'</html>';
            else if(audience=='InternalToCustomer')
                msg='<html>You have one new notification from Akamai on the Technical Requirement Document - <a href="'+commUrlInstance+'">'+chimeName+'</a>.<br/>'+'Comment: '+comment+'</html>';
            else if(audience=='InternalToInternal')
                msg='<html>You have one new internal comment on <b>'+chimeName+'</b> form. Please '+'<a href="'+baseUrl+'/'+chimeId+'">click here</a> to access the CHIME form.'+'<br/>'+'Comment: '+comment+'</html>';
                
            mail.setHtmlBody(msg);
            mail.setOrgWideEmailAddressId(orgWideAddress[0].Id);
            System.debug('toAddress' + toAddress);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }
    }
}