/* 
Author          : Sumukh SS/Vishnu/Sharath
Description     : Trigger for Community Comment Functionality JARVIS


Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
15 Mar 2021				Authors				 	    					  Initial Development
------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_CommunityCommentTriggerHandler {
    
    //Commenting out the method. Revamping the logic - Sharath
    //Calculating the Commented by details for Case comments
    // public static void getCommentedByDetails(list<Community_Comments__c> caseCommentlst)
    // {
    //     map<id,string> userIdProfileNameMap = new map<id,string>();
    //     set<id> parentids = new set<id>();
        
    //     set<string> memberIdParentIdset = new set<string>();
        
    //     for(Community_Comments__c eachCaseComment : caseCommentlst)
    //     {
    //         if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case' && eachCaseComment.Commented_By__c==null)
    //         {
    //             UserIdProfileNameMap.put(eachCaseComment.AKAM_Created_By__c,'');
    //             parentids.add(eachCaseComment.Parent_ID__c);
    //         }
    //     }

    //     map<id, string> caseidRecordtypeMap = new map<id,string>();
    //     for(case eachrec : [select id,recordtype.name,accountid from case where id IN :parentids])
    //     {
    //         caseidRecordtypeMap.put(eachrec.id,eachrec.recordtype.name+'-'+eachrec.accountid);
    //     }
        
    //     for(user eachuser : [select id,profile.name from user where id IN :UserIdProfileNameMap.keyset()])
    //     {
    //         UserIdProfileNameMap.put(eachuser.id,eachuser.profile.name);
    //     }
        
    //     for(caseteammember eachmember : [select MemberId,ParentId from caseteammember where ParentId IN :parentids and memberid IN :UserIdProfileNameMap.keyset()])
    //     {
    //         memberIdParentIdset.add(string.valueof(eachmember.MemberId)+string.valueof(eachmember.ParentId));
    //     }
        
    //     for(Community_Comments__c eachCaseComment : caseCommentlst)
    //     {
    //         if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case' && eachCaseComment.Commented_By__c==null)
    //         {
    //             if(UserIdProfileNameMap.get(eachCaseComment.AKAM_Created_By__c)!='SFCommunityCustomers')
    //             {
    //                 eachCaseComment.Commented_By__c='Internal User';
    //             }
    //             else
    //             {
    //                 if(memberIdParentIdset.contains(string.valueof(eachCaseComment.AKAM_Created_By__c)+string.valueof(eachCaseComment.Parent_ID__c)))
    //                 {
    //                     eachCaseComment.Commented_By__c='Collaborator';
    //                 }
    //                 else
    //                 {
    //                     eachCaseComment.Commented_By__c='Customer';
    //                 }
    //             }
    //             string recordtype = caseidRecordtypeMap.get(eachCaseComment.Parent_ID__c).split('-')[0];

    //             if(recordtype=='AMG'||recordtype=='Billing')
    //             {
    //                 eachCaseComment.Account_ID_for_Community_Share__c=caseidRecordtypeMap.get(eachCaseComment.Parent_ID__c).split('-')[1];
    //             }
            
    //         }
    //     }
        
    // }
    public static void getCommentedByDetails(list<Community_Comments__c> caseCommentlst)
    {
        set<id> parentids = new set<id>();
                
        for(Community_Comments__c eachCaseComment : caseCommentlst)
        {
            if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case')
            {
                parentids.add(eachCaseComment.Parent_ID__c);
            }
        }

        map<id, string> caseToAccountLookup = new map<id,string>();
        for(case eachrec : [select id,Community_Sharing_Set_Account_Lookup__c from case where id IN :parentids])
        {
            caseToAccountLookup.put(eachrec.id,eachrec.Community_Sharing_Set_Account_Lookup__c);
        }
                
        for(Community_Comments__c eachCaseComment : caseCommentlst)
        {
            if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case' &&
            eachCaseComment.Account_ID_for_Community_Share__c != caseToAccountLookup.get(eachCaseComment.Parent_ID__c))
            {
                eachCaseComment.Account_ID_for_Community_Share__c=caseToAccountLookup.get(eachCaseComment.Parent_ID__c);
            }
        }
        
    }
    
    //For sharing Logic of community comments -- depending on the recordtype
    public static void provisionCommentShareAccess(list<Community_Comments__c> caseCommentlst)
    {
        set<id> caseids = new set<id>();
        for(Community_Comments__c eachCaseComment : caseCommentlst)
        {
            if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case')
            {
                caseids.add(eachCaseComment.Parent_ID__c);
            }
            
        }
        
        map<id, case> caseidCaseDetMap = new map<id,case>();
        for(case eachrec : [select id,akam_case_id__c,recordtype.name,contact.email from case where id IN :caseids])
        {
            caseidCaseDetMap.put(eachrec.id,eachrec);
        }
        
        caseids.clear();

        for(Community_Comments__c eachCaseComment : caseCommentlst)
        {
            if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case')
            {
                string recordtype = caseidCaseDetMap.get(eachCaseComment.Parent_ID__c).recordtype.name;

                switch on recordtype {
                    when 'Managed Security', 'Technical','Professional Services', 'AMG','Billing', 'Emerging Products Engineering','Partner Technical Support'
                {
                    caseids.add(eachCaseComment.Parent_ID__c);
                }
              
                }
            }
        }
        
        map<id, list<string>> caseIDPublicGrplst = new map<id, list<string>>();
        
        list<caseshare> caseGrpLst = new list<caseshare>();
        caseGrpLst = [select CaseId,UserOrGroupId from caseshare where caseId IN :caseids and RowCause='Manual'  
        and UserorGroup.Name LIKE 'JA%'];
        
        if(caseGrpLst.size()>0)
        {
            for(caseshare eachsharerec : caseGrpLst)
            {
                list<string> groupids = new list<string>();
                if(caseIDPublicGrplst.containsKey(eachsharerec.CaseId))
                {
                    groupids = caseIDPublicGrplst.get(eachsharerec.CaseId);   
                    groupids.add(eachsharerec.UserOrGroupId);
                    caseIDPublicGrplst.put(eachsharerec.CaseId,groupids);
                }
                else
                {	
                    groupids.add(eachsharerec.UserOrGroupId);
                    caseIDPublicGrplst.put(eachsharerec.CaseId,groupids);
                }
            }
            
            list<community_comments__share> sharesToBeProvisioned = new list<community_comments__share>();
            for(Community_Comments__c eachCaseComment : caseCommentlst)
            {
                if(eachCaseComment.Application__c=='JARVIS' && eachCaseComment.Related_Object__c=='Case')
                {
                    list<string> groupsForAccess =caseIDPublicGrplst.get(eachCaseComment.Parent_ID__c);
                    
                    for(string eachgrpid : groupsForAccess)
                    {
                        community_comments__share shareRec= new community_comments__share();
                        shareRec.ParentID = eachCaseComment.id;
                        shareRec.RowCause = 'Manual';
                        shareRec.AccessLevel = 'Read';
                        shareRec.UserOrGroupId = eachgrpid;
                        
                        sharesToBeProvisioned.add(shareRec);
                    }
                }
            }

            if(sharesToBeProvisioned.size()>0)
                insert sharesToBeProvisioned;
        }
    } 
    
    //Called from ContentDocumentLinkHandler. Adds a comment for each File Uploaded
    public static void createCommentFromFileUpload( map<string,string> contentDocCaseIdMap) {
        
        map<string,string> contentdocTitleMap = new map<string,string>();
        Map<Id, Case> caseInfoMap = new Map<Id, Case>([select id, recordtype.Name, Akam_Case_Id__c, ContactId, AccountId from case where id in :contentDocCaseIdMap.values()]);

        list<Community_Comments__c> commentsToBeAdded = new list<Community_Comments__c>();

        for(ContentVersion cv : [select id, ContentDocumentId, ContentDocument.title, ContentDocument.OwnerId, customvisibility_fileupload__c from ContentVersion 
        where ContentDocumentId IN :contentDocCaseIdMap.keyset() 
            and Origin = 'C' and IsLatest = true])        
        {
            Id caseId = contentDocCaseIdMap.get(cv.ContentDocumentId);
            Case parentCase = caseInfoMap.get(caseId);
            string commentTxt = cv.ContentDocument.title + '/' + cv.ContentDocumentId;

            Community_Comments__c newcomment = SC_JARVIS_CustomerTouchpoints.getJarvisComment(parentCase, null, commentTxt, cv.ContentDocument.OwnerId ,'File' );
            //By Pass Case Update Email when files are uploaded during case creation ESESP-7120
            if(cv.customvisibility_fileupload__c == 'scJarvisCaseCreate')
                newcomment.Skip_Email_Notification__c = True;
            commentsToBeAdded.add(newcomment);
        }
        
        insert commentsToBeAdded;
        
    }
    
    public static void createFeed(list<Community_Comments__c> caseCommentlst) {
        List<FeedItem> toInsertFeedItems = new List<FeedItem>();
        
        Map<Id, String> caseIdAccountNameMap = new Map<Id, String>();
        
        for( Community_Comments__c cm: caseCommentlst) {
            caseIdAccountNameMap.put(cm.Parent_ID__c, '');
        }
            
        for( Community_Comments__c cm: caseCommentlst) {
            Community_Comments__c cmClone = cm.clone();
            if(cm.Comment__c != null && cm.type__c != 'Email')
            {
                String comment = SC_Jarvis_utility.stripHtmlTag(cm.Comment__c, 'img', '<p> <i> ----Image Removed, Check Community Comment---- </i> </p>');
                comment = comment.replaceAll('<[^>]+>',' ');
                
                
                comment = ' <p> <b> <a target="_self" href="https://' + System.Url.getOrgDomainUrl().getHost() +'/' + cm.id +'"> Community Comment </a>  </b> </p>' 
                		 + comment; 
                comment = comment.abbreviate(10000);
                toInsertFeedItems.add(new FeedItem(ParentId = cm.Parent_ID__c, 
                                                Body = comment, 
                                                isRichText = true,
                                                CreatedById = cm.AKAM_Created_By__c));

            }
        }
        Database.DMLOptions opt = new Database.DMLOptions();
        opt.allowFieldTruncation = true;
        opt.optAllOrNone = false;
        Database.insert(toInsertFeedItems, opt);
    }
}