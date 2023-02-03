/*
* Author: Samir Jha
* Business Use-Case: Notify Managers of their pending approvals with all timecard Details in the mail based on their preference.
: 
--Developer           --Date            --Change
Sharath Ravishankar   20th Jan 2017     CR 3565841 : Changes done to send the filter parametrs to the page.
Sharath Prasanna      10th Feb 2017     CR 3565841 : Adding a null pointer check for the 'All' grouping
Sharath Ravishankar   6th Mar 2017      CR 3675742 - Test classes : Increase Code coverage 
Sujay                 21st Feb 2018     FFPSA-142  : Adding Delegated Approver Timecards to notify Users over emails

*/

global class PSA_NotifyPendingApprovalsDaily implements Database.Batchable<sObject>
{
    //PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
    //String fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;

    PSA_Common_Setting__mdt EnggEmail = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='Engineering Team Email' limit 1];
    String fromAddress = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='FromEmailAdress'  limit 1].Value_Long__c;

    String orgWideEmailId = '';
    private string query;
    private string TestClass_Query;
    private string batchQuery;
    
    
    //RETURN USER PREFERENCE RECORDS
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        query = 'Select id,User__c,User__r.email,User__r.Name,Notification_Frequency__c, Disable_Approval_Digests__c ,Digest_Grouping__c from PSA_Approval_Notification_Preference__c where Disable_Approval_Digests__c = False and Notification_Frequency__c = \'Daily\'';
        //Changes by Sharath R to limit the rows while executing test class
        TestClass_Query = query + ' order by createddate desc limit 5'; 
        
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : query;
        
        return Database.getQueryLocator(batchQuery);
        //end of changes by Sharath R
    }
    
    //MAIN method
    //Create a Map of UserId to UserPreference
    //Create a Map of TimecardId and Process Instance WorkIteem Records
    //Create a Map of UserId and Timecards
    //For every User for the list of Timecards, create a mail and send it to user
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
        list<PSA_Approval_Notification_Preference__c> userPreference = new list<PSA_Approval_Notification_Preference__c>();
        userPreference = scope;
        //system.assertEquals(userPreference,NULL);
        Map<Id,PSA_Approval_Notification_Preference__c> userIdPreferenceMap = new Map<Id,PSA_Approval_Notification_Preference__c>();
        Map<Id,ProcessInstanceWorkitem> mapTcardIdWorkitem = new Map<Id,ProcessInstanceWorkitem>();
        Map<Id,list<pse__Timecard_Header__c>> mapUserIdTCHList = new Map<Id,list<pse__Timecard_Header__c>>();
        
        for(PSA_Approval_Notification_Preference__c up1: userPreference)
        {
            userIdPreferenceMap.put(up1.User__c,up1);
            //system.assertEquals(userIdPreferenceMap, NULL);
        }

        // Changes by Sujay : Adding below map to get if Users from userIdPreferenceMap are Delegated Approvers to any Other Users in Org. 
        
        //And add Delegated Approver Timecards to Users in PSA_Approval_Notification_Preference__c
        try
        {
             orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        }
        catch(Exception e)
        {
            
        }
        
        Map<Id, User> map_uIdToDelgUser = new Map<Id, User>([SELECT Id,Name, DelegatedApproverId 
                                                             FROM User 
                                                             WHERE DelegatedApproverId In : userIdPreferenceMap.keySet() 
                                                             AND DelegatedApproverId != ''
                                                             AND isActive = true]);
        
        System.debug('Test map_uIdToDelgUser' +map_uIdToDelgUser.keySet());
        System.debug('+++++ TEST userIdPreferenceMap ------' + userIdPreferenceMap);
        
        //Changes by Sujay : to store user Id and Delegated Approver User Id and Delegation End Time
        Map<Id, Id> map_uIdToDelId = new Map<Id, Id>();
        Map<Id, String> map_uIdToDelEndDate = new Map<Id, String>();
        
        for(User uIds : [SELECT Id, DelegatedApproverId, Delegation_EndTime__c 
                        FROM User
                        WHERE (DelegatedApproverId In : userIdPreferenceMap.keySet() 
                        OR DelegatedApproverId In : map_uIdToDelgUser.keySet())]){
                            
                map_uIdToDelId.put(uIds.Id, uIds.DelegatedApproverId);
                if(uIds.Delegation_EndTime__c != NULL){
                    map_uIdToDelEndDate.put(uIds.Id, uIds.Delegation_EndTime__c.format());
                }
                else{
                    map_uIdToDelEndDate.put(uIds.Id, 'Not Provided');         
                }
                    
         }

        //Changes by Sujay Surendranath : Adding filter confition to get Tc's pending with Delegation Users
        list<ProcessInstanceWorkitem> usersTC2Approve = [Select Id,ActorId, Actor.Name ,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ProcessInstance.Status='Pending' and (ActorId IN :userIdPreferenceMap.keySet() OR ActorId IN :map_uIdToDelgUser.keySet()) and CreatedDate = LAST_N_DAYS:1 Order by ActorId];
        for(ProcessInstanceWorkitem piw:usersTC2Approve)
        {
            
            if(((STRING)(piw.ProcessInstance.TargetObjectId)).startsWith('aAj'))
            {
                
                mapTcardIdWorkitem.put(piw.ProcessInstance.TargetObjectId,piw); 
            }
        }
        System.debug('++++ Test mapTcardIdWorkite keySet ---' + mapTcardIdWorkitem.keySet());
        List<pse__Timecard_Header__c> tchList = [SELECT Id,pse__Milestone__r.Name,Name,pse__Resource__c,pse__Resource__r.Name, pse__Friday_Hours__c , pse__Monday_Hours__c , pse__Saturday_Hours__c , pse__Sunday_Hours__c , pse__Thursday_Hours__c , pse__Tuesday_Hours__c , pse__Wednesday_Hours__c , pse__Additional_Notes__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Total_Hours__c,pse__Billable__c,pse__Start_Date__c, pse__Approver__r.DelegatedApproverId from pse__Timecard_Header__c where Id in:mapTcardIdWorkitem.keySet() Order by pse__Approver__c]; 
        for(Id uId:userIdPreferenceMap.keySet())
        {
            for(pse__Timecard_Header__c tch:tchList)
            {
                //Changes by Sujay : Adding a filter to get TC's pending with Actual and Delegated Users
                if(mapTcardIdWorkitem!= NULL && 
                    mapTcardIdWorkitem.get(tch.Id) != NULL && 
                        (uId==mapTcardIdWorkitem.get(tch.Id).ActorId || uId==map_uIdToDelId.get(mapTcardIdWorkitem.get(tch.Id).ActorId)) )
                {
                    if(mapUserIdTCHList.get(uId)==NULL)
                        mapUserIdTCHList.put(uId,new list<pse__Timecard_Header__c>());
                    
                    mapUserIdTCHList.get(uId).add(tch);
                }
            }
            
        }
        
        //string fromEmailAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c.trim();  
        //string orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :fromEmailAddress limit 1].Id;
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail; 
        String messageBody,messageTable,EnvironmentURL,PreferenceLink,BulkApprovalLink,messageTable_Delegated;
        
        for(Id uId1:userIdPreferenceMap.keySet())
        {
            messageBody = 'Hi '+ userIdPreferenceMap.get(uId1).User__r.Name + ',<br>'+'Click on the individual Approve/Reject links to take action on individual Timecards.'+'<br>'+'The below Timecards are awaiting your approval:<br>';
            
            EnvironmentURL = (String)(URL.getSalesforceBaseUrl().toExternalForm());
            BulkApprovalLink = '<br>You can click here to APPROVE/REJECT all pending timecards :'+'<br>' +EnvironmentURL + '/apex/PSA_TCApproveNew'; 
            PreferenceLink = 'Click on the link to view/update your notification preferences: '+ EnvironmentURL +'/'+ userIdPreferenceMap.get(uId1).Id +'<br>';
            Map<Id,list<pse__timecard_header__c>> mapGroupsOfTimecard = new Map<Id,list<pse__timecard_header__c>>();
            if(userIdPreferenceMap.get(uId1).Digest_Grouping__c == 'Project')
            {
                if(mapUserIdTCHList!= NULL && mapUserIdTCHList.get(uId1)!=NULL)
                {
                    for(pse__timecard_header__c tch3:mapUserIdTCHList.get(uId1))
                    {
                        
                        if(mapGroupsOfTimecard==NULL || mapGroupsOfTimecard.get(tch3.pse__Project__c)==NULL)
                        {
                            mapGroupsOfTimecard.put(tch3.pse__Project__c,new list<pse__timecard_header__c>());
                        }
                        mapGroupsOfTimecard.get(tch3.pse__Project__c).add(tch3);
                        
                    }
                }
                
                for(Id projId:mapGroupsOfTimecard.keyset())
                {
                    
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setReplyTo('noreply@akamai.com');
                    //objEmail.setSenderDisplayName('FinancialForce PSA Notification');
                    //objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    objEmail.setToAddresses(new list<String>{userIdPreferenceMap.get(uId1).User__r.email});//userIdPreferenceMap.get(uId1).User__r.email});
                    messageTable = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Approve/Reject</th></tr>';
                    messageTable_Delegated = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Actual Approver</th><th>Delegation EndDate</th><th>Approve/Reject</th></tr>';
                    for(pse__timecard_header__c tch2 : mapGroupsOfTimecard.get(projId))
                    {   
                        //Changes by Sujay : Added an if condition to differentiate b/n Actual and Delegated Timecards.
                        if(mapTcardIdWorkitem.get(tch2.Id).ActorId == uId1){
                               messageTable+='<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+'</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+ mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                               //system.assertEquals('<tr><td><a href="+'EnvironmentURL+'/'+tch2.Id +'">TimecardLink</a></td><td>',NULL);  
                        }
                        else{
                                messageTable_Delegated += '<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+ '</td><td>'+ mapTcardIdWorkitem.get(tch2.Id).Actor.Name + '</td><td>' + map_uIdToDelEndDate.get(mapTcardIdWorkitem.get(tch2.Id).ActorId) + '</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+ mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                                //system.assertEquals('<tr><td><a href="+'EnvironmentURL+'/'+tch2.Id +'">TimecardLink</a></td><td>',NULL);  
                            }
                    }
                    messageTable+='</table></body>  </html>';
                    messageTable_Delegated+='</table></body>  </html>';
                    objEmail.setSubject('Job mail : Project Daily');
                    if(orgWideEmailId != '')
                        {
                            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
                        }
                    //BulkApprovalLink = '<br>You can click here to APPROVE all pending timecards for this day for this project by clicking on the link below:'+'<br>' +EnvironmentURL + '/apex/PSA_BulkApproveFromEmail?projFilter='+projId + '&Date='+ Date.Today().addDays(-1).format() + '&Type=Daily'; 
                    //Changes by Sujay : Adding a new Table to email "messageTable_Delegated" to show delegated Timecards. 
                    String mTable = messageTable.contains('<td>') ? messageTable : '';
                    String mTable_delegated = messageTable_Delegated.contains('<td>') ?  '<br>' + 'Below Timecards are Delegated to you' + '<br>' + '<br>'+ messageTable_Delegated : '';
                    objEmail.setHtmlBody(messageBody + BulkApprovalLink +'?projFilter='+projId+'<br>'+ mTable + mTable_delegated +'<br>'+ PreferenceLink + 'Thanks & Regards,<br>PSA Automated Notifications');
                    mailsToBeSent.add(objEmail);
                }
            }
            else if(userIdPreferenceMap.get(uId1).Digest_Grouping__c == 'Account')
            {
                if(mapUserIdTCHList!= NULL && mapUserIdTCHList.get(uId1)!=NULL){
                    for(pse__timecard_header__c tch3:mapUserIdTCHList.get(uId1))
                    {
                        
                        if(mapGroupsOfTimecard==NULL || mapGroupsOfTimecard.get(tch3.pse__Project__r.pse__Account__c)==NULL)
                        {
                            mapGroupsOfTimecard.put(tch3.pse__Project__r.pse__Account__c,new list<pse__timecard_header__c>());
                        }
                        mapGroupsOfTimecard.get(tch3.pse__Project__r.pse__Account__c).add(tch3);
                    }
                }
                //SYSTEM.assertequals(mapGroupsOfTimecard.keySet(),NULL);
                for(Id AccId:mapGroupsOfTimecard.keyset())
                {
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setReplyTo('noreply@akamai.com');
                    //objEmail.setSenderDisplayName('FinancialForce PSA Notification');
                    //objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    objEmail.setToAddresses(new list<String>{userIdPreferenceMap.get(uId1).User__r.email});
                    messageTable = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Approve/Reject</th></tr>';
                    messageTable_Delegated = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Actual Approver</th><th>Delegation EndDate</th><th>Approve/Reject</th></tr>';
                    
                    for(pse__timecard_header__c tch2:mapGroupsOfTimecard.get(AccId))
                    {
                        if(mapTcardIdWorkitem.get(tch2.Id).ActorId == uId1)
                            {
                            messageTable+='<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+'</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                            //system.assertEquals('<tr><td><a href="+'EnvironmentURL+'/'+tch2.Id +'">TimecardLink</a></td><td>',NULL);
                            }
                        else{
                                messageTable_Delegated += '<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+ '</td><td>'+ mapTcardIdWorkitem.get(tch2.Id).Actor.Name + '</td><td>' + map_uIdToDelEndDate.get(mapTcardIdWorkitem.get(tch2.Id).ActorId)  + '</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+ mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                            //system.assertEquals('<tr><td><a href="+'EnvironmentURL+'/'+tch2.Id +'">TimecardLink</a></td><td>',NULL);
                            }
                    }
                    messageTable+='</table></body>  </html>';
                    messageTable_Delegated+='</table></body>  </html>';
                    objEmail.setSubject('Job mail : Account Daily');
                    if(orgWideEmailId != '')
                        {
                            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
                        }
                    //BulkApprovalLink = '<br>You can click here to APPROVE all pending timecards for this day for this Account by clicking on the link below:'+'<br>' +EnvironmentURL + '/apex/PSA_BulkApproveFromEmail?AccFilter='+AccId + '&Date='+ Date.Today().addDays(-1).format() + '&Type=Daily'; 
                    //Changes by Sujay : Adding a new Table to email "messageTable_Delegated" to show delegated Timecards. 
                    String mTable = messageTable.contains('<td>') ? messageTable : '';
                    String mTable_delegated = messageTable_Delegated.contains('<td>') ?  '<br>' + 'Below Timecards are Delegated to you' + '<br>'+'<br>' + messageTable_Delegated : '';
                    objEmail.setHtmlBody(messageBody + BulkApprovalLink +'?AccFilter='+AccId+'<br>'+ mTable + mTable_delegated +'<br>' + PreferenceLink + 'Thanks & Regards,<br>PSA Automated Notifications');
                    mailsToBeSent.add(objEmail);
                }
            }
            else if(userIdPreferenceMap.get(uId1).Digest_Grouping__c == 'Resource')
            {
                if(mapUserIdTCHList!= NULL && mapUserIdTCHList.get(uId1)!=NULL)
                {
                    for(pse__timecard_header__c tch3:mapUserIdTCHList.get(uId1))
                    {
                        
                        if(mapGroupsOfTimecard==NULL || mapGroupsOfTimecard.get(tch3.pse__Resource__c)==NULL)
                        {
                            mapGroupsOfTimecard.put(tch3.pse__Resource__c,new list<pse__timecard_header__c>());
                        }
                        mapGroupsOfTimecard.get(tch3.pse__Resource__c).add(tch3);
                        
                    }
                }
                //SYSTEM.assertequals(mapGroupsOfTimecard.keySet(),NULL);
                for(Id ResId:mapGroupsOfTimecard.keyset())
                {
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setReplyTo('noreply@akamai.com');
                    //objEmail.setSenderDisplayName('FinancialForce PSA Notification');
                    //objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    objEmail.setToAddresses(new list<String>{userIdPreferenceMap.get(uId1).User__r.email});
                    messageTable = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Approve/Reject</th></tr>';
                    messageTable_Delegated = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Actual Approver</th><th>Delegation EndDate</th><th>Approve/Reject</th></tr>';
                    
                    for(pse__timecard_header__c tch2:mapGroupsOfTimecard.get(ResId))
                    {
                        //Changes by Sujay : Added an if condition to differentiate b/n Actual and Delegated Timecards.
                        if(mapTcardIdWorkitem.get(tch2.Id).ActorId == uId1){
                                messageTable+='<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+'</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                               //system.assertEquals('<tr><td><a href="+'EnvironmentURL+'/'+tch2.Id +'">TimecardLink</a></td><td>',NULL);  
                        }
                        else{
                                messageTable_Delegated += '<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+ '</td><td>'+ mapTcardIdWorkitem.get(tch2.Id).Actor.Name + '</td><td>' + map_uIdToDelEndDate.get(mapTcardIdWorkitem.get(tch2.Id).ActorId) + '</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+ mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                                //system.assertEquals('<tr><td><a href="+'EnvironmentURL+'/'+tch2.Id +'">TimecardLink</a></td><td>',NULL);  
                            }
                    }
                    messageTable+='</table></body>  </html>';
                    messageTable_Delegated+='</table></body>  </html>';
                    objEmail.setSubject('Approval Mail: Resource Daily');
                    if(orgWideEmailId != '')
                        {
                            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
                        }
                    //BulkApprovalLink = '<br>You can click here to APPROVE/REJECT all pending timecards :'+'<br>' +EnvironmentURL + '/apex/PSA_BulkApproveFromEmail; 
                    //Changes by Sujay : Adding a new Table to email "messageTable_Delegated" to show delegated Timecards. 
                    String mTable = messageTable.contains('<td>') ? messageTable : '';
                    String mTable_delegated = messageTable_Delegated.contains('<td>') ?  '<br/>' + 'Below Timecards are Delegated to you' + '<br/>'+'<br/>' + messageTable_Delegated : '';
                    objEmail.setHtmlBody(messageBody + BulkApprovalLink +'?ResFilter='+ResId+'<br/>'+ mTable + mTable_delegated +'<br/>' + PreferenceLink + 'Thanks & Regards,<br/>PSA Automated Notifications');
                    mailsToBeSent.add(objEmail);
                }
            }
            else if(userIdPreferenceMap.get(uId1).Digest_Grouping__c == 'All')
            {
                //changes by Sharath Prasanna: Adding the null pointer check
                if (mapUserIdTCHList!= NULL && mapUserIdTCHList.get(uId1)!=NULL)
                {
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setReplyTo('noreply@akamai.com');
                    //objEmail.setSenderDisplayName('FinancialForce PSA Notification');
                    //objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    objEmail.setToAddresses(new list<String>{userIdPreferenceMap.get(uId1).User__r.email});
                    messageTable = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Approve/Reject</th></tr>';
                    messageTable_Delegated = '<html><body><table border="1"><tr><th>Timecard Id</th><th>Account</th><th>Project</th><th>Milestone</th><th>Resource</th><th>Billable</th><th>Start Date</th><th>Sunday</th><th>Monday</th><th>Tuesday</th><th>Wednesday</th><th>Thursday</th><th>Friday</th><th>Saturday</th><th>Total Hours</th><th>Actual Approver</th><th>Delegation EndDate</th><th>Approve/Reject</th></tr>';

                    for(pse__timecard_header__c tch2:mapUserIdTCHList.get(uId1))
                    {
                        if(mapTcardIdWorkitem.get(tch2.Id).ActorId == uId1){
                                 messageTable+='<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+'</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                        }
                        else{
                                messageTable_Delegated += '<tr><td><a href="'+EnvironmentURL+'/'+tch2.Id +'">'+tch2.Name+'</a></td><td>'+tch2.pse__Project__r.pse__Account__r.Name +'</td><td>'+tch2.pse__Project__r.Name+'</td><td>'+tch2.pse__Milestone__r.Name+'</td><td>'+tch2.pse__Resource__r.Name+'</td><td>'+tch2.pse__Billable__c+'</td><td>'+tch2.pse__Start_Date__c.format()+'</td><td>'+tch2.pse__Sunday_Hours__c+'</td><td>'+tch2.pse__Monday_Hours__c+'</td><td>'+tch2.pse__Tuesday_Hours__c+'</td><td>'+tch2.pse__Wednesday_Hours__c+'</td><td>'+tch2.pse__Thursday_Hours__c+'</td><td>'+tch2.pse__Friday_Hours__c+'</td><td>'+tch2.pse__Saturday_Hours__c+'</td><td>'+tch2.pse__Total_Hours__c+ '</td><td>'+ mapTcardIdWorkitem.get(tch2.Id).Actor.Name + '</td><td>' + map_uIdToDelEndDate.get(mapTcardIdWorkitem.get(tch2.Id).ActorId) + '</td><td><a href="'+EnvironmentURL+'/p/process/ProcessInstanceWorkitemWizardStageManager?id='+ mapTcardIdWorkitem.get(tch2.Id).Id +'">Approve/Reject</a></td></tr>';
                        }                    
                    }
                    messageTable+='</table></body>  </html>';
                    messageTable_Delegated+='</table></body>  </html>';
                    String mTable = messageTable.contains('<td>') ? messageTable : '';
                    String mTable_delegated = messageTable_Delegated.contains('<td>') ?  '<br/>' + 'Below Timecards are Delegated to you' + '<br/>'+'<br/>' + messageTable_Delegated : '';
                    objEmail.setSubject('Approval Mail: All Daily');
                    if(orgWideEmailId != '')
                        {
                            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
                        }
                    //BulkApprovalLink = '<br>You can click here to APPROVE all pending timecards for this day by clicking on the link below:'+'<br>' +EnvironmentURL + '/apex/PSA_BulkApproveFromEmail?Date='+ Date.Today().addDays(-1).format() + '&Type=Daily'; 
                    objEmail.setHtmlBody(messageBody + BulkApprovalLink +'<br>'+ mTable + mTable_delegated + '<br>' + PreferenceLink + 'Thanks & Regards,<br>PSA Automated Notifications');
                    mailsToBeSent.add(objEmail);
                }
            }
            
            
            //Messaging.sendEmail(mailsToBeSent,false);
        }
        //Changes by Sharath Prasanna: putting outside the loop
        Messaging.sendEmail(mailsToBeSent,false);
        
        
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
    }
    
}