/*
 * CR: FFPSA-142
 * Developer: Sujay
 * Description: This Class is used to send email alerts when Delegated approver is set/ removed in Custom page
 * Date: 26th Feb 2018
 * 
*/ public class PSA_FFDelegationHistoryHandler {
    
    //Its is used to send email alert for users when Delegation is changed/removed
    public void sendEmailAlertOnInsertOrUpdate(Map<Id, FF_Delegation_History__c> newDelgRecs, Map<Id, FF_Delegation_History__c > oldDelgRecs, Boolean isInsert){
        
        String messageBody;
        Set<Id> userIds = new Set<Id>();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage objEmail;
        String EnvironmentURL = (String)(URL.getSalesforceBaseUrl().toExternalForm()) + '/ui/setup/personal/ApproverSettingsSetupPage?setupid=ApproverSettings';
        String LEnvironmentURL = (String)(URL.getSalesforceBaseUrl().toExternalForm()) + '/lightning/settings/personal/ApproverSettings/home?0.source=alohaHeader';
        //String fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;
        String fromAddress = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'FromEmailAdress'].Value_Long__c ;
        String orgWideEmailId = '';
        
        try
        {
             orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        }
        catch(Exception e)
        {
            
        }
    
        Map<Id, List<Id>> userIdToDelgId = new Map<Id, List<Id>>();
        
        for(Id delgHis : newDelgRecs.keySet()){
            
            FF_Delegation_History__c currentDelHis = newDelgRecs.get(delgHis);
            
            if(isInsert && currentDelHis.Delegated_Approver__c != NULL){
                
                userIdToDelgId.put(currentDelHis.Delegation_For__c, new List<Id>{NULL});
                userIdToDelgId.get(currentDelHis.Delegation_For__c).add(currentDelHis.Delegated_Approver__c);
                userIds.add(currentDelHis.Delegation_For__c);
                userIds.add(currentDelHis.Delegated_Approver__c);
                    
            }
            
            else if(!isInsert && currentDelHis.Delegated_Approver__c != oldDelgRecs.get(delgHis).Delegated_Approver__c ){
                
                userIdToDelgId.put(currentDelHis.Delegation_For__c, new List<Id>{oldDelgRecs.get(delgHis).Delegated_Approver__c});
                userIdToDelgId.get(currentDelHis.Delegation_For__c).add(newDelgRecs.get(delgHis).Delegated_Approver__c);
                userIds.add(currentDelHis.Delegation_For__c);
                userIds.add(currentDelHis.Delegated_Approver__c);
                userIds.add(oldDelgRecs.get(currentDelHis.Id).Delegated_Approver__c);
                
            }
            
        }//end of for
            
        //Store all User Id Name, Email, Delegation End Time From User with old map User Ids
        Map<Id,User> mapuIdToUser = new Map<Id,User>([SELECT Id, Name , Email, Delegation_EndTime__c  
                                                          From User
                                                          WHERE Id In :userIds]);
            
        for(Id uId : userIdToDelgId.keySet()){
                
                if(userIdToDelgId.get(uId).size() == 2 && userIdToDelgId.get(uId)[1] != NULL){
                    
                    messageBody = 'Hello, '+ '<br><br>' + 'You have been indicated as a temporary delegated approver in Salesforce on behalf of ' + '<b>' + mapuIdToUser.get(uId).Name +'</b>.' +'<br><br>'+ '<b>If you wish to receive email notifications when Timecards are pending your approval you <br>' +'must ensure your Salesforce Approver email settings are updated. ' + '<br><br>If you want to update this setting, then set “Receive Approval Request Emails” = “If I am an approver or <br>' +'delegated approver” from this link</b> '+ '<a href="'+ EnvironmentURL +'">Classic View</a> '+'| <a href="'+ LEnvironmentURL +'">Lightning View</a>. '+'<br><br>Alternatively you can access this page by navigating to My Settings > Personal > Approver Settings<br> and setting "Receive Approval Request Emails" = "If I am an approver or delegated approver".' +'<br><br> Thanks & Regards, <br> PSA Automated Notifications';
                    objEmail = new Messaging.SingleEmailMessage();
                    objEmail.setSubject('Delegated Approval Access Updated');
                    objEmail.setReplyTo('noreply@akamai.com');
                    if(orgWideEmailId != '')
                        {
                            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
                        }
                    objEmail.setToAddresses(new list<String>{mapuIdToUser.get(userIdToDelgId.get(uId)[1]).Email});
                    objEmail.setHtmlBody(messageBody);
                    mailsToBeSent.add(objEmail);
                
                }
                
                if( userIdToDelgId.get(uId)[0] != NULL ){
                    
                    messageBody = 'Hello, '+ '<br><br>' + 'Your status as a delegated approver on behalf of ' + '<b>' + mapuIdToUser.get(uId).Name +'</b>' + ' has been changed. <br>'+ 'You will no longer receive approval requests on their behalf.' + '<br> <br> Thanks & Regards, <br> PSA Automated Notifications';
                    objEmail = new Messaging.SingleEmailMessage();
                    objEmail.setSubject('Delegated Approval Access Updated');
                    objEmail.setReplyTo('noreply@akamai.com');
                    if(orgWideEmailId != '')
                        {
                            objEmail.setOrgWideEmailAddressId(orgWideEmailId);  
                        }
                    objEmail.setToAddresses(new list<String>{mapuIdToUser.get(userIdToDelgId.get(uId)[0]).Email});
                    objEmail.setHtmlBody(messageBody);
                    mailsToBeSent.add(objEmail);
                    
                }
                
            }//end of for
            
        Messaging.sendEmail(mailsToBeSent,false);

        }// end of method
    
    
    //Changes by Sujay for Delegated Approver enhancement to Track Delegated Approver on Timecards NOT approved/rejected : FFPSA-481
    public void validateHistoryStampPendingTcs(Map<Id,FF_Delegation_History__c>oldMap, Map<Id,FF_Delegation_History__c>newMap){
        
        //System.debug('In After Update Records');
        Map<Id, Id> userIdToDelgId= new Map<Id, Id>();
        
        for(Id delgId : oldMap.keySet()){
            //System.debug('newMap.get(delgId).Delegation_Start_Time__c :::' +  newMap.get(delgId).Delegation_Start_Time__c);
            if(oldMap.get(delgId).Delegated_Approver__c != NULL && newMap.get(delgId).Delegated_Approver__c == NULL){
                  userIdToDelgId.put(oldMap.get(delgId).Delegation_For__c , oldMap.get(delgId).Delegated_Approver__c);
                  //System.debug('userIdToDelgId :: '+ userIdToDelgId);
            }
        }

        //Calling Future method to create Pending Tc's that were not Approved by Actual/Delegated Approver
        if(userIdToDelgId.size() > 0)
        {
            List<ProcessInstanceWorkitem> pendingTcs = [SELECT Id,ActorId, Actor.Name ,ProcessInstance.TargetObjectId,ProcessInstance.Status,CreatedDate 
                                                        FROM ProcessInstanceWorkitem 
                                                        WHERE ProcessInstance.Status='Pending' 
                                                        AND ActorId In :userIdToDelgId.keySet()
                                                        ORDER BY ActorId];
            
            Map<Id, List<ProcessInstanceWorkitem>> actorIdToPIW = new Map<Id, List<ProcessInstanceWorkitem>>();
            
            for(ProcessInstanceWorkitem piw : pendingTcs){
                String tcId = String.valueof(piw.ProcessInstance.TargetObjectId);
                    if(tcId.startsWith('aAj')){
                        if(actorIdToPIW.get(piw.ActorId) == NULL){
                            actorIdToPIW.put(piw.ActorId, new List<ProcessInstanceWorkitem>());
                            actorIdToPIW.get(piw.ActorId).add(piw);
                        }
                        else{
                            actorIdToPIW.get(piw.ActorId).add(piw);
                        }
                    }
            }
            
            System.debug('in createPendingTimecard :: ' + pendingTcs.size());
    
            List<FF_Track_Pending_Timecard__c> listCreatePendingTC = new List<FF_Track_Pending_Timecard__c>();        
            
            for(FF_Delegation_History__c delHisId : oldMap.values()){
                
                if(delHisId.Delegated_Approver__c != NULL && newMap.get(delHisId.Id).Delegated_Approver__c == NULL && actorIdToPIW.containsKey(delHisId.Delegation_For__c) ){
                   
                    for(ProcessInstanceWorkitem piw : actorIdToPIW.get(delHisId.Delegation_For__c)){
                    
                        FF_Track_Pending_Timecard__c trackTc = new FF_Track_Pending_Timecard__c();//tcIdToTrackingReocrd.containsKey(piw.ProcessInstance.TargetObjectId) ? tcIdToTrackingReocrd.get(piw.ProcessInstance.TargetObjectId) :
                        //if(piw.CreatedDate >= delHisId.Delegation_Start_Time__c ){
                            trackTc.Timecard__c = piw.ProcessInstance.TargetObjectId;
                            trackTc.Actual_Approver__c = piw.ActorId;
                            trackTc.Delegated_Approver__c = userIdToDelgId.get(piw.ActorId);
                            trackTc.Status__c = 'Submitted';
                            listCreatePendingTC.add(trackTc); 
                        //}
                    
                    }
                }//end of if
                  
            }
            
            if(listCreatePendingTC.size() > 0){
                  Database.upsert(listCreatePendingTC,false);
            }
        
        }//enf of if userIdToDelgId.size()
    
    }//end of validateHistoryStampPendingTcs method
               
}