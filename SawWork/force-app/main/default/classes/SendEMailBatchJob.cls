//Created by Mayank Bansal as part of SFDC-3280
//Test Class: SendEMailBatchJobTest

    global class SendEMailBatchJob implements Database.Batchable<sObject>, Database.Stateful{

        global List<Approval_History_Reminder__c> approvalList;
        global List<String> nameList = new List<String>();
        global Map<String, Approval_History_Reminder__c> mapNameToApprovalHistory;
        global Map<String, Map<Integer,String>> nameToReminderDayMap;
        global Map<String, Map<Integer,String>> nameToTemplateNameMap;
        global Map<String, String> mapTemplateNameToID;
        global List<ProcessInstance> piList;
        global integer totalEmailToBeSent;
        global integer totalSuccessEmailSent;

        global SendEMailBatchJob(){
            
            totalEmailToBeSent = 0;
            totalSuccessEmailSent = 0;
            mapNameToApprovalHistory = new Map<String, Approval_History_Reminder__c>();
            // Light Custom object
            approvalList = [Select Name, Template_Name_for_Each_Day__c, Reminder_Criteria_and_Mailing_Details__c from Approval_History_Reminder__c];
            for(Approval_History_Reminder__c obj: approvalList){
                mapNameToApprovalHistory.put(obj.Name, obj);
                nameList.add('\''+obj.Name+'\'');
            }
        }

        global Map<String, Map<Integer,String>> setPrerequisite(String fieldName){
            Map<String, Map<Integer,String>> tempMap = new Map<String, Map<Integer,String>>();
            for(Approval_History_Reminder__c obj: approvalList){

                    String str =(String) obj.get(fieldName);
                    Map<String, Object> criteriaMailMap = new Map<String, Object>();
                    Map<Integer,String> numberToMailDetails = new Map<Integer,String>();
                    criteriaMailMap = (Map<String, Object>)JSON.deserializeUntyped(str);
                    for(String s: criteriaMailMap.keySet()){
                        numberToMailDetails.put(Integer.valueOf(s), (String)criteriaMailMap.get(s));
                    }   
                    
                    tempMap.put(obj.Name, numberToMailDetails);
                }
                return tempMap;
        }

        //start method that creates the query and returns the query locator
        global Database.QueryLocator start(Database.BatchableContext bc)
        {  
            Integer dayLimit = 0;
            SendEMailBatchJob batchObj = new SendEMailBatchJob();
           //set Prerequisite create map of days and mailing list
            nameToReminderDayMap = new Map<String, Map<Integer,String>>();
            mapTemplateNameToID = new Map<String, String>();
            if(nameToReminderDayMap.isEmpty()){
                nameToReminderDayMap = batchObj.setPrerequisite('Reminder_Criteria_and_Mailing_Details__c');
            }

            for(String str: nameToReminderDayMap.keySet()){
                Map<Integer,String> nameMap = nameToReminderDayMap.get(str);
                    for(Integer i : nameMap.keySet()){
                        if(dayLimit < i){
                            dayLimit = i;
                        }
                    }
            }
            dayLimit = dayLimit +1;

            nameToTemplateNameMap = new Map<String, Map<Integer,String>>();
            if(nameToTemplateNameMap.isEmpty()){
                nameToTemplateNameMap = batchObj.setPrerequisite('Template_Name_for_Each_Day__c');
            }

            for(String str: nameToTemplateNameMap.keySet()){
                Map<Integer,String> nameMap = nameToTemplateNameMap.get(str);
                    for(Integer i : nameMap.keySet()){
                        mapTemplateNameToID.put(nameMap.get(i), null);
                    }
            }   

            List<EmailTemplate> templateList = [Select id, name from EmailTemplate where name in :mapTemplateNameToID.keySet()];
            
            
            for(EmailTemplate template: templateList){
                mapTemplateNameToID.put(template.Name, template.id);
            }
            
            //List<ProcessInstanceWorkitem> piwiList = [select id, ActorId, ProcessInstance.TargetObject.Type, Actor.Name, OriginalActorId, OriginalActor.Name, ElapsedTimeInDays from ProcessInstanceWorkitem where ProcessInstanceId  in :piList];
            
            String query = 'select id, createdBy.Name, ActorId, Actor.email, ProcessInstanceId, ProcessInstance.TargetObject.Type, ProcessInstance.TargetObject.Name, ProcessInstance.TargetObjectId, Actor.Name, OriginalActorId, OriginalActor.Name, ElapsedTimeInDays from ProcessInstanceWorkitem where ProcessInstance.Status like \'Pending\' and ProcessInstance.TargetObject.Type in '+nameList+' and ElapsedTimeInDays <'+dayLimit;
            return Database.getQueryLocator(query);
        }

        global void execute(Database.BatchableContext bc,List<sObject> scope)
        {
            SendEMailBatchJob batchObj = new SendEMailBatchJob();
            List<Integer> reminderDays = new List<Integer>();
            String templateId = null;
            List<String> ccAddress = new List<String>();
            Map<String, List<String>> toAddressMap =  new Map<String, List<String>>();
            Map<String, List<String>> ccAddressMap =  new Map<String, List<String>>();
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

            //Loop to check if record satisfies days condition and create map of record id with User's email
            for(sobject sc: scope){
                ProcessInstanceWorkitem piwi = (ProcessInstanceWorkitem) sc;
                if(mapNameToApprovalHistory.containsKey(piwi.ProcessInstance.TargetObject.Type)){
                    
                    String mailList = null;
                    if(nameToReminderDayMap.get(piwi.ProcessInstance.TargetObject.Type) != null)
                        mailList = nameToReminderDayMap.get(piwi.ProcessInstance.TargetObject.Type).get(piwi.ElapsedTimeInDays.intValue());
                    if(mailList != null){
                        if(mailList.contains(',')){
                            //It means multiple recievers
                            mailList = mailList.remove(' ');
                            List<String> strList = mailList.split(',');
                            for(String s: strList){
                                if(s.equalsIgnoreCase('Approver')){
                                    toAddressMap = batchObj.setvaluesToMap(toAddressMap, piwi.id, piwi.Actor.email);
                                } else if(s.equalsIgnoreCase('Manager')){
                                    ccAddressMap = batchObj.setvaluesToMap(ccAddressMap, piwi.id, 'Manager of ' +piwi.ActorId);
                                } else{
                                    ccAddressMap = batchObj.setvaluesToMap(ccAddressMap, piwi.id, s+':'+piwi.ProcessInstance.TargetObjectId+':'+piwi.ProcessInstance.TargetObject.Type+':'+piwi.id);
                                } 
                            }
                        } else if(mailList.equalsIgnoreCase('Approver')){
                            toAddressMap = batchObj.setvaluesToMap(toAddressMap, piwi.id, piwi.Actor.email);
                        }
                    }
                }
            }
                // Get list of User ids for which we need manager details   
                List<Id> userIdList = new List<Id>();
                Map<String, Set<String>> mapTypeToIdList = new Map<String, Set<String>>();
                Map<String, Set<String>> mapTypeToFieldApiList = new Map<String, Set<String>>();
                Map<String, List<String>> mapTargetObjIdToPiwiId = new Map<String, List<String>>();

                if(!ccAddressMap.isEmpty()){
                    for(String k: ccAddressMap.keySet()){
                        List<String> t = new List<String>();
                        t = ccAddressMap.get(k);
                        for(String s: t){
                            if(s.startsWith('Manager of')){
                                s =s.replace('Manager of ', '');
                                s = s.replace(' ', ''); 
                                userIdList.add(s);
                            } else{
                                s = s.replace(' ', '');
                                List<string> lst = s.split(':');
                                Set<String> stList = new Set<String>();
                                if(mapTypeToIdList.containsKey(lst[2]))
                                    stList = mapTypeToIdList.get(lst[2]);
                                stList.add(lst[1]);
                                mapTypeToIdList.put(lst[2], stList);
                                stList = new Set<String>();
                                if(mapTypeToFieldApiList.containsKey(lst[2]))
                                    stList = mapTypeToFieldApiList.get(lst[2]);
                                stList.add(lst[0]);
                                mapTypeToFieldApiList.put(lst[2], stList);
                               // mapTargetObjIdToPiwiId.put(lst[1], lst[3]);
                                List<String> piwiList = new List<String>();
                                if(mapTargetObjIdToPiwiId.containsKey(lst[1])){
                                    piwiList = mapTargetObjIdToPiwiId.get(lst[1]);
                                }
                                piwiList.add(lst[3]);
                                mapTargetObjIdToPiwiId.put(lst[1], piwiList);
                            }
                        }
                    }
                }
                
                if(!mapTypeToFieldApiList.isEmpty()){
                    List<String> updateList = new List<String>();
                    Map<String,String> dynamicQueryMap = new Map<String,String>();
                    for(String s: mapTypeToFieldApiList.keySet()){
                        String fields = '';
                        for(String field: mapTypeToFieldApiList.get(s)){
                            fields += (fields==''?'':',') +field;
                        }
                        String recordIds = '';
                        for(String recId: mapTypeToIdList.get(s)){
                            recordIds += (recordIds==''?'':',') +'\''+recId+'\'';
                        }
                        //Creating dynamic query for custom fields
                        String dynamicQuery = 'Select id,'+ fields +' from ' + s + ' where id in ('+recordIds +')';
                        dynamicQueryMap.put(s,dynamicQuery);
                    }
                    //Loop to query dynamic SOQL and update CCAddr from String to actual User Id.
                    for(String objName: dynamicQueryMap.keySet()){
                        List<Sobject> resList = Database.query(dynamicQueryMap.get(objName));

                        for(Sobject obj1: resList){
                            for(String st: mapTypeToFieldApiList.get(objName)){
                                String fieldVal = (String)obj1.get(st);
                                if(fieldVal != null && fieldVal.startsWith('005')){
                                    
                                    for(String s1: mapTargetObjIdToPiwiId.get(obj1.id)){
                                        updateList = new List<String>();
                                        updateList = batchObj.replaceStrWithId(ccAddressMap.get(s1),fieldVal, st+':'+obj1.id);
                                        ccAddressMap.put(s1, updateList);
                                        userIdList.add(fieldVal);
                                    }
                                }
                            }
                        }
                    }
                }

                List<User> usrlist = [select id, firstname, email, manager.email, manager.name from user where id in :userIdList and IsActive = true];
                Map<Id,User> mapIDToUSer = new Map<Id,User>();
                for(User u : usrlist){
                    mapIDToUSer.put(u.id, u);
                }

                for(sobject sc: scope){
                    ProcessInstanceWorkitem piwi = (ProcessInstanceWorkitem) sc;
                    List<String> updateList = new List<String>();
                    if(toAddressMap.containsKey(piwi.id)){

                        //For cc Address list
                        if(ccAddressMap.get(piwi.id) != null && !mapIDToUSer.isEmpty()){
                            System.debug('Mayank, ccad:'+batchObj.replaceIdWithEmail(ccAddressMap.get(piwi.id), mapIDToUSer));
                            updateList = batchObj.replaceIdWithEmail(ccAddressMap.get(piwi.id), mapIDToUSer);

                            ccAddressMap.put(piwi.id, updateList);
                        }
                    }

                    templateId = null;
                    if(nameToTemplateNameMap.get(piwi.ProcessInstance.TargetObject.Type) != null)
                     templateId = mapTemplateNameToID.get(nameToTemplateNameMap.get(piwi.ProcessInstance.TargetObject.Type).get(piwi.ElapsedTimeInDays.intValue()));

                    if(toAddressMap.get(piwi.id) != null && templateId != null){
                        mails.add(batchObj.prepareMail(toAddressMap.get(piwi.id), ccAddressMap.get(piwi.id), templateId, piwi));
                    }
                }

                if(mails.size() > 0){
                    totalEmailToBeSent = totalEmailToBeSent + mails.size();
                    totalSuccessEmailSent = totalSuccessEmailSent + batchObj.sendMail(mails);
                }
        }



        // Mailing functionality
        global Messaging.SingleEmailMessage prepareMail(List<String> toAddress, List<String> ccAddress, String templateId, ProcessInstanceWorkitem piwi)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddress);
            mail.setTemplateId(templateId);
            mail.setSaveAsActivity(false);
            mail.setWhatId(piwi.id);
            mail.setTargetObjectId(piwi.ActorId);

            System.debug('Mayank, adding ccAddress for piwi:' +piwi.id+ ' ccAddress:'+ccAddress);
            if(ccAddress != null && !ccAddress.isEmpty()){
                mail.setCcAddresses(ccAddress);
            }
            return mail;
        }

        //
        global Integer sendMail(List<Messaging.SingleEmailMessage> mails){

            if(mails.size() > 0){
                System.debug('Mayank, mails' +mails);
                Messaging.SendEmailResult[] sendEmailResultList = Messaging.sendEmail(mails);
                for(Messaging.SendEmailResult result : sendEmailResultList){
                    if(result.isSuccess())
                        totalSuccessEmailSent++;
                }
            }
            return totalSuccessEmailSent;
        }

        global Map<String, List<String>> setvaluesToMap(Map<String, List<String>> addrMap, String piwiId, String strToAdd){
            
            List<String> tempList = new List<String>();
            if(addrMap.get(piwiId) != null)
                tempList = addrMap.get(piwiId);
            tempList.add(strToAdd);
            addrMap.put(piwiId, tempList);

            return addrMap;
        }
        
        global List<String> replaceIdWithEmail(List<string> updateList, Map<Id,User> mapIDToUSer){
            List<String> emailList = new List<String>();
            for(String s: updateList){
                
                if(s.startsWith('005')){
                    User user = mapIDToUSer.get(s);
                    emailList.add(user.email);
                } else if(s.startsWith('Manager')){
                    s =s.replace('Manager of', '');
                    s =s.replace(' ', '');
                    User user = mapIDToUSer.get(s);
                    if(user.managerId != null)
                        emailList.add(user.manager.email);
                }
            }
            return emailList;
        }

        global List<String> replaceStrWithId(List<string> updateList, String IdToReplaceWith, String strToReplace){
            List<String> emailList = new List<String>();
            for(String s: updateList){
                if(s.startsWith(strToReplace)){
                    emailList.add(IdToReplaceWith);
                } else{
                    emailList.add(s);
                }
            }
            return emailList;
        }

        //BatchApex Completes
        // execution with this finish method
        global void finish(Database.BatchableContext BC)
        {   
            string results = 'Total emails to be sent: '+totalEmailToBeSent+', Success: '+totalSuccessEmailSent+', Failure: '+(totalEmailToBeSent-totalSuccessEmailSent);
            Util.updateCronRunWithResult('Approval History Mailing Batch Job', results);
        }

        
    }