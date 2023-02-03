/*
* Developer  : Vandhana Krishnamurthy
* Purpose    : Trigger for Elevation Inserts/Updates
* Date       : 2 Aug 2021
* Test Class : SC_Elevation_TriggerHandler_Test
* 
* Date                 Developer           JIRA                            Changes
*
* 2-Aug-2021            Vandhana        ESESP-4359                 Elevate/Escalate on Account
*/ 

public class SC_Elevation_TriggerHandler 
{
    public static void beforeInsertUpdate(Boolean isInsert, List<Elevation__c> lstOldElevation, List<Elevation__c> lstNewElevation, Map<Id, Elevation__c> oldMap, Map<Id, Elevation__c> newMap) 
    {
        
    }
    
    public static void afterInsertUpdate(Boolean isInsert, List<Elevation__c> lstOldElevation, List<Elevation__c> lstNewElevation, Map<Id, Elevation__c> oldMap, Map<Id, Elevation__c> newMap) 
    {   
        if(isInsert)
        {
            Set<Id> setAccountId = new Set<Id>();
            Map<String,Boolean> mapAccCustWatch = new Map<String,Boolean>();
            List<Account> lstAccountToUpdate = new List<Account>();
            Map<Id,Account> mapAcc = new Map<Id,Account>();
            
            Boolean fieldChanged;
            
            List<String> toAddresses = new List<String>();
            Messaging.SingleEmailMessage mail;
            List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
            String errorMssg = '';
            
            List<String> atmRoles = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Elevation_ATM_Roles'].Value_Text__c.split(',');
            
            String atmEmailTemplateID;
            
            List<String> lstAccElevDL = new List<String>();
            
            for(Elevation__c eachElevation : lstNewElevation)
            {
                if(eachElevation.Status__c == 'Open')
                {
                    setAccountId.add(eachElevation.Account__c);
                    if(eachElevation.Customer_Watch__c)
                    {   
                        mapAccCustWatch.put(eachElevation.Account__c,true);     
                    }
                }
            }
            
            // Elevate Account (set Elevated? to true) on Parent Account if not already set
            
            mapAcc = new Map<Id,Account>([SELECT Elevated__c,Customer_Watch__c,Account_Elevation_Mailing_List__c,
                                          (SELECT ID,User.Email 
                                           FROM AccountTeamMembers 
                                           WHERE User.IsActive = true 
                                           AND TeamMemberRole IN :atmRoles) 
                                          FROM Account 
                                          WHERE Id IN :setAccountId
                                          FOR UPDATE]);
            
            if(!mapAcc.keyset().isEmpty())
            {
                for(Account accRec : mapAcc.values())
                {
                    fieldChanged = false;
                    
                    if(!accRec.Elevated__c)
                    {   
                        accRec.Elevated__c = true;
                        accRec.Validation_Override__c = true;
                        fieldChanged = true;
                    }
                    if(mapAccCustWatch.containsKey(accRec.Id) && !accRec.Customer_Watch__c)
                    {   
                        accRec.Customer_Watch__c = mapAccCustWatch.get(accRec.Id);  
                        accRec.Validation_Override__c = true;
                        fieldChanged = true;
                    }   
                    
                    if(fieldChanged)
                    {   
                        lstAccountToUpdate.add(accRec); 
                    }
                    
                }
                
                try
                {
                    System.debug('!!! ACCOUNTS TO UPDATE : ' + lstAccountToUpdate);
                    if(!lstAccountToUpdate.isEmpty())
                    {
                        //update lstAccountToUpdate;
                        List<Database.SaveResult> lstSaveRes = Database.update(lstAccountToUpdate, false);
                        
                        String errorAccId = '';
                        String errorMessage = '';
                        Messaging.SingleEmailMessage errorEmail;
                        List<Messaging.SingleEmailMessage> lstErrorEmails = new List<Messaging.SingleEmailMessage>();
                        
                        for (Database.SaveResult sr : lstSaveRes) 
                        {
                            errorMessage = '';errorAccId = '';
                            if (!sr.isSuccess()) 
                            {
                                errorAccId += sr.getId();
                                for(Database.Error err : sr.getErrors()) 
                                {     
                                    errorMessage = errorAccId + '::' + err.getStatusCode() + '::' + err.getMessage() + '::' + err.getFields() + '\n';
                                }
                                errorEmail = sendErrorEmail('Account Update Failure : SC_TaskTriggerHandler',errorMessage,new String[] {'sc-dev@akamai.com'});
                                lstErrorEmails.add(errorEmail);
                            }
                        }
                        
                        if(!lstErrorEmails.isEmpty())
                        {
                            List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(lstErrorEmails);  
                            System.debug('!!! ACCOUNTS TO UPDATE sendEmailResults : ' + sendEmailResults);
                        }
                    }
                    
                    // notify Account Team Members of New Elevation
                    
                    atmEmailTemplateID = [Select Value_Text__c from SC_Utility__mdt where DeveloperName = 'Notify_ATM_on_New_Elevation_TemplateId'].Value_Text__c;
                    
                    for(Elevation__c elevationRec : lstNewElevation)
                    {
                        toAddresses = new List<String>();
                        
                        if(mapAcc.containsKey(elevationRec.Account__c) && !mapAcc.get(elevationRec.Account__c).AccountTeamMembers.isEmpty())
                        {
                            for(AccountTeamMember eachATM : mapAcc.get(elevationRec.Account__c).AccountTeamMembers)
                            {
                                if(String.isNotBlank(eachATM.User.Email))
                                {   
                                    toAddresses.add(eachATM.User.Email);    
                                }   
                            }
                        }
                        
                        if(mapAcc.containsKey(elevationRec.Account__c) && String.isNotBlank(mapAcc.get(elevationRec.Account__c).Account_Elevation_Mailing_List__c))
                        {   
                            lstAccElevDL = new List<String>();
                            String accDL = mapAcc.get(elevationRec.Account__c).Account_Elevation_Mailing_List__c;
                            //accDL = accDL.replace('\r','\n').replaceAll('[\n;]',',');
                            toAddresses.addAll(accDL.split(','));   
                        }
                        
                        mail = new Messaging.SingleEmailMessage();
                        mail = Messaging.renderStoredEmailTemplate(atmEmailTemplateID, elevationRec.CreatedById,elevationRec.Id);
                        String emailHTMLBody = mail.getHtmlBody().replaceAll('<img[^>]*>','<p><b>[Inline Image added, please view the image in Salesforce]</b></p>').replaceAll('</img>','');
                        mail.setHtmlBody(emailHTMLBody);
                        mail.setPlainTextBody(mail.getplainTextBody());
                        mail.setSaveAsActivity(false);
                        mail.setToAddresses(toAddresses);
                        lstMails.add(mail);
                    }
                    
                    System.debug('!!! LIST OF EMAILS for ATM Notify on Elevation : ' + lstMails);
                    
                    if(!lstMails.isEmpty())
                    {
                        List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(lstMails);
                        
                        String errorMessage = '';
                        Messaging.SingleEmailMessage errorEmail;
                        List<Messaging.SingleEmailMessage> lstErrorEmails = new List<Messaging.SingleEmailMessage>();
                        
                        for(Messaging.SendEmailResult result : sendEmailResults) 
                        {
                            errorMessage = '';
                            if(!result.IsSuccess())
                            {
                                System.StatusCode statusCode = result.getErrors()[0].getStatusCode();
                                System.debug('Status code: ' + statusCode);
                                System.debug('Error msg: ' + result.getErrors()[0].getMessage());
                                
                                errorMssg = 'Status code: ' + statusCode + '\nError msg: '+ result.getErrors()[0].getMessage() + '\n';
                                errorEmail = sendErrorEmail('Notify ATM Failure : SC_Elevation_TriggerHandler',errorMssg,new String[] {'sc-dev@akamai.com'});
                                lstErrorEmails.add(errorEmail);
                            }
                        }
                        if(!lstErrorEmails.isEmpty())
                        {
                            List<Messaging.SendEmailResult> sendErrorEmailResults = Messaging.sendEmail(lstErrorEmails);  
                            System.debug('!!! sendErrorEmailResults for ATM Notify : ' + sendErrorEmailResults);
                        }
                    }
                }
                catch(Exception e)
                {   
                    sendErrorEmail('Notify ATM Failure : SC_Elevation_TriggerHandler',e.getMessage() + '::' + e.getLineNumber() + '::' + e.getStackTraceString(),new String[] {'sc-dev@akamai.com'});
                }
            }
        }
        else
        {
            // Rollup Elevated/Customer Watch from Elevation to parent Account
            
            Set<Id> setElevationId = new Set<Id>();
            Set<Id> setAccId = new Set<Id>();
            Map<Id,Account> mapAcc = new Map<Id,Account>();
            Set<Id> setElevationFieldUpdate = new Set<Id>();
            Set<Id> setElevationFieldUpdateAccId = new Set<Id>();
            Map<Id,Account> mapAccount2Update = new Map<Id,Account>(); Account acc;
            
            Boolean fieldChanged;
            Map<Id,Map<String,Boolean>> mapAccElevCustWatch = new Map<Id,Map<String,Boolean>>();
            Map<String,Boolean> mapElevCustWatch;
            
            for(Id elevationRecId : newMap.keyset())
            {
                if(oldMap.get(elevationRecId).Status__c != newMap.get(elevationRecId).Status__c 
                   || 
                   (oldMap.get(elevationRecId).Customer_Watch__c != newMap.get(elevationRecId).Customer_Watch__c && newMap.get(elevationRecId).Status__c == 'Open'))
                {
                    setElevationId.add(elevationRecId);
                    setAccId.add(newMap.get(elevationRecId).Account__c);
                }
                
                if(oldMap.get(elevationRecId).Status__c != newMap.get(elevationRecId).Status__c
                  || oldMap.get(elevationRecId).Latest_Summary__c != newMap.get(elevationRecId).Latest_Summary__c
                  || oldMap.get(elevationRecId).Exec_Summary__c != newMap.get(elevationRecId).Exec_Summary__c)
                {
                    setElevationFieldUpdate.add(elevationRecId);
                    setElevationFieldUpdateAccId.add(newMap.get(elevationRecId).Account__c);
                }
            } 
            
            if(!setElevationId.isEmpty())
            {
                mapAcc = new Map<Id,Account>([SELECT Elevated__c,Customer_Watch__c,(SELECT Status__c,Customer_Watch__c FROM Elevations__r WHERE Status__c = 'Open')
                                              FROM Account 
                                              WHERE Id IN :setAccId
                                              FOR UPDATE]);
                
                System.debug('mapACC : ' + mapAcc);
                System.debug('mapACC : ' + setElevationId);
                
                for(Id elevationRecId : setElevationId)
                {   
                    acc = null;
                    
                    if(
                        (oldMap.get(elevationRecId).Status__c != newMap.get(elevationRecId).Status__c 
                         && newMap.get(elevationRecId).Status__c == 'Open' 
                         && !mapAcc.get(newMap.get(elevationRecId).Account__c).Elevated__c)
                        ||
                        (oldMap.get(elevationRecId).Customer_Watch__c != newMap.get(elevationRecId).Customer_Watch__c && 
                         newMap.get(elevationRecId).Customer_Watch__c 
                         && !mapAcc.get(newMap.get(elevationRecId).Account__c).Customer_Watch__c)
                    )
                    {
                        Boolean elevateAcc = false;
                        Boolean custWatchAcc = false;
                        
                        if(oldMap.get(elevationRecId).Status__c != newMap.get(elevationRecId).Status__c)
                        {   
                            elevateAcc = true; 
                        }
                        
                        if(oldMap.get(elevationRecId).Customer_Watch__c != newMap.get(elevationRecId).Customer_Watch__c)
                        {   
                            custWatchAcc = true; 
                        }
                        
                        if(elevateAcc && custWatchAcc)
                        {
                            acc = new Account(Id=newMap.get(elevationRecId).Account__c,Elevated__c=true,Customer_Watch__c=true);
                        }
                        else if(elevateAcc)
                        {
                            acc = new Account(Id=newMap.get(elevationRecId).Account__c,Elevated__c=true);
                            if(newMap.get(elevationRecId).Customer_Watch__c)
                            {   
                                acc = new Account(Id=newMap.get(elevationRecId).Account__c,Elevated__c=true,Customer_Watch__c=true,Validation_Override__c=true);    
                            }
                        }
                        else if(custWatchAcc)
                        {
                            acc = new Account(Id=newMap.get(elevationRecId).Account__c,Customer_Watch__c=true,Validation_Override__c=true);
                        }
                        
                        System.debug(acc);
                    }
                    
                    /*
                    System.debug(oldMap.get(elevationRecId).Status__c != newMap.get(elevationRecId).Status__c);
                    System.debug(newMap.get(elevationRecId).Status__c == 'Closed');
                    System.debug(mapAcc.get(newMap.get(elevationRecId).Account__c).Elevated__c);
                    System.debug(oldMap.get(elevationRecId).Customer_Watch__c != newMap.get(elevationRecId).Customer_Watch__c );
                    System.debug(!newMap.get(elevationRecId).Customer_Watch__c);
                    System.debug(newMap.get(elevationRecId).Status__c == 'Open');
                    System.debug(mapAcc.get(newMap.get(elevationRecId).Account__c).Customer_Watch__c);
                    */
                    
                    if((oldMap.get(elevationRecId).Status__c != newMap.get(elevationRecId).Status__c 
                        && newMap.get(elevationRecId).Status__c == 'Closed' 
                        && mapAcc.get(newMap.get(elevationRecId).Account__c).Elevated__c)
                       ||
                       (oldMap.get(elevationRecId).Customer_Watch__c != newMap.get(elevationRecId).Customer_Watch__c 
                        && !newMap.get(elevationRecId).Customer_Watch__c && newMap.get(elevationRecId).Status__c == 'Open'
                        && mapAcc.get(newMap.get(elevationRecId).Account__c).Customer_Watch__c))
                    {
                        Boolean openElevationsPresent = false;
                        Boolean customerWatchElevPresent = false;
                        
                        for(Elevation__c eachRec : mapAcc.get(newMap.get(elevationRecId).Account__c).Elevations__r)
                        {
                            if(eachRec.Id != elevationRecId && eachRec.Status__c == 'Open')
                            {   
                                openElevationsPresent = true;break; 
                            }
                        }
                        
                        for(Elevation__c eachRec : mapAcc.get(newMap.get(elevationRecId).Account__c).Elevations__r)
                        {
                            if(eachRec.Id != elevationRecId && eachRec.Customer_Watch__c)
                            {   
                                customerWatchElevPresent = true;break;  
                            }
                        }
                        
                        System.debug(openElevationsPresent + '::' + customerWatchElevPresent);
                        
                        if((!customerWatchElevPresent && !newMap.get(elevationRecId).Customer_Watch__c) 
                           ||
                           (!customerWatchElevPresent && newMap.get(elevationRecId).Status__c == 'Closed' && openElevationsPresent)
                          )
                        {
                            acc = new Account(Id=newMap.get(elevationRecId).Account__c,Customer_Watch__c=false,Validation_Override__c=true);
                        }
                        if(!openElevationsPresent && newMap.get(elevationRecId).Status__c == 'Closed')
                        {
                            acc = new Account(Id=newMap.get(elevationRecId).Account__c,Elevated__c=false,Customer_Watch__c=false,Validation_Override__c=true);
                        }
                        
                    }
                    
                    if(acc != null)
                    {
                        System.debug('ACCOUNT : ' + acc);
                        mapAccount2Update.put(acc.Id,acc);
                    }
                }
                
                try 
                {
                    if(!mapAccount2Update.isEmpty())
                    {
                        System.debug('!!! ACCOUNTS UPDATED ON ELEVATION UPDATE : ' + mapAccount2Update);
                        List<Database.SaveResult> lstAccount2UpdateSR = Database.update(mapAccount2Update.values());
                        
                        String errorAccId = '';
                        String errorMessage = '';
                        Messaging.SingleEmailMessage errorEmail;
                        List<Messaging.SingleEmailMessage> lstErrorEmails = new List<Messaging.SingleEmailMessage>();    
                        
                        for (Database.SaveResult sr : lstAccount2UpdateSR) 
                        {
                            errorMessage = '';errorAccId = '';
                            if (!sr.isSuccess()) 
                            {
                                errorAccId += sr.getId();
                                for(Database.Error err : sr.getErrors()) 
                                {     
                                    errorMessage = errorAccId + '::' + err.getStatusCode() + '::' + err.getMessage() + '::' + err.getFields() + '\n';
                                }
                                errorEmail = sendErrorEmail('Account Update Failure : SC_TaskTriggerHandler',errorMessage,new String[] {'sc-dev@akamai.com'});  
                                lstErrorEmails.add(errorEmail);
                            }
                        }
                        if(!lstErrorEmails.isEmpty())
                        {
                            List<Messaging.SendEmailResult> sendErrorEmailResults = Messaging.sendEmail(lstErrorEmails);  
                            System.debug('!!! ACCOUNTS TO UPDATE sendErrorEmailResults : ' + sendErrorEmailResults);
                        }
                    }
                }
                catch(Exception e)
                {   
                    sendErrorEmail('Accounts Update failure : SC_Elevation_TriggerHandler',e.getMessage() + '::' + e.getLineNumber() + '::' + e.getStackTraceString(),new String[] {'sc-dev@akamai.com'});
                }
            }
            
            if(!setElevationFieldUpdate.isEmpty())
            {
                List<String> toAddresses = new List<String>();
                List<String> lstAccElevDL = new List<String>();
                
                Messaging.SingleEmailMessage mail;
                List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
                
                String emailSubj = ''; 
                String emailHTMLBody = '';
                String plainTextBody = '';
                
                String elevUpdateEmailTemplate = [Select Value_Text__c from SC_Utility__mdt where DeveloperName = 'Notify_ATM_on_New_Elevation_TemplateId'].Value_Text__c;
                
                mapAcc = new Map<Id,Account>([SELECT Elevated__c,Customer_Watch__c,Account_Elevation_Mailing_List__c
                                              FROM Account 
                                              WHERE Id IN :setElevationFieldUpdateAccId]);
                
                for(Id elevationId : setElevationFieldUpdate)
                {
                    if(String.isNotBlank(mapAcc.get(newMap.get(elevationId).Account__c).Account_Elevation_Mailing_List__c))
                    {
                        toAddresses = new List<String>();
                        
                        mail = new Messaging.SingleEmailMessage();
                        mail = Messaging.renderStoredEmailTemplate(elevUpdateEmailTemplate,newMap.get(elevationId).CreatedById,elevationId);
                        
                        lstAccElevDL = new List<String>();
                        String accDL = mapAcc.get(newMap.get(elevationId).Account__c).Account_Elevation_Mailing_List__c;
                        //accDL = accDL.replace('\r','\n').replaceAll('[\n;]',',');
                        toAddresses.addAll(accDL.split(','));   
                        
                        mail.setSaveAsActivity(false);
                        
                        emailSubj = mail.getSubject().replace('New Elevation created','Elevation ' + newMap.get(elevationId).Name + ' has been updated');
                        emailHTMLBody = mail.getHtmlBody().replace('A new Elevation has been created','Elevation ' + newMap.get(elevationId).Name + ' has been updated');
                        plainTextBody = mail.getplainTextBody().replace('A new Elevation has been created','Elevation ' + newMap.get(elevationId).Name + ' has been updated');
                        emailHTMLBody = emailHTMLBody.replaceAll('<img[^>]*>','<p><b>[Inline Image added, please view the image in Salesforce]</b></p>').replaceAll('</img>','');
                        mail.setTargetObjectId(newMap.get(elevationId).CreatedById);
                        mail.setSubject(emailSubj);
                        mail.setHtmlBody(emailHTMLBody);
                        mail.setPlainTextBody(plainTextBody);
                        mail.setToAddresses(toAddresses);
                        lstMails.add(mail);
                    }
                }   
                
                if(!lstMails.isEmpty())
                {
                    System.debug(lstMails);
                    List<Messaging.SendEmailResult> sendEmailResults = Messaging.sendEmail(lstMails);
                    
                    String errorMessage = '';
                    Messaging.SingleEmailMessage errorEmail;
                    List<Messaging.SingleEmailMessage> lstErrorEmails = new List<Messaging.SingleEmailMessage>();    
                    
                    for(Messaging.SendEmailResult result : sendEmailResults) 
                    {
                        errorMessage = '';
                        if(!result.IsSuccess())
                        {
                            System.StatusCode statusCode = result.getErrors()[0].getStatusCode();
                            System.debug('Status code: ' + statusCode);
                            System.debug('Error msg: ' + result.getErrors()[0].getMessage());
                            
                            errorMessage = 'Status code: ' + statusCode + '\nError msg: '+ result.getErrors()[0].getMessage() + '\n';
                            errorEmail = sendErrorEmail('New/Update Elevation Failure : SC_Elevation_TriggerHandler',errorMessage,new String[] {'sc-dev@akamai.com'});
                            lstErrorEmails.add(errorEmail);
                        }
                    }
                    if(!lstErrorEmails.isEmpty())
                    {
                        List<Messaging.SendEmailResult> sendErrorEmailResults = Messaging.sendEmail(lstErrorEmails);  
                        System.debug('!!! ELEVATIONS TO CREATE/UPDATE sendErrorEmailResults : ' + sendErrorEmailResults);
                    }
                }
            }
            
            /*
            if(!mapAcc.keyset().isEmpty())
            {
                for(Id accId : mapAcc.keySet())
                {
                    mapElevCustWatch = new Map<String,Boolean>();
                    mapElevCustWatch.put('E',false);
                    mapElevCustWatch.put('CW',false);
                    
                    if(!mapAcc.get(accId).Elevations__r.isEmpty())
                    {
                        for(Elevation__c eachElevation : mapAcc.get(accId).Elevations__r)
                        {
                            if(eachElevation.Status__c == 'Open')
                            {   mapElevCustWatch.put('E',true);     }
                            if(eachElevation.Customer_Watch__c)
                            {   mapElevCustWatch.put('CW',true);    }
                        } 
                    }
                    mapAccElevCustWatch.put(accId,mapElevCustWatch);
                }
                
                for(Id elevRecId : newMap.keyset())
                {
                    fieldChanged = false;
                    if(newMap.get(elevRecId).Status__c == 'Closed' && newMap.get(elevRecId).Status__c != oldMap.get(elevRecId).Status__c)
                    {
                        if(mapAccElevCustWatch.containsKey(newMap.get(elevRecId).Account__c) 
                           && !mapAccElevCustWatch.get(newMap.get(elevRecId).Account__c).get('E') && mapAcc.get(newMap.get(elevRecId).Account__c).Elevated__c)
                        {
                            if(mapAcc.get(newMap.get(elevRecId).Account__c).Elevated__c)
                            {   
                                
                            }
                        }
                    }
                    if(!newMap.get(elevRecId).Customer_Watch__c && oldMap.get(elevRecId).Customer_Watch__c)
                    {
                        
                    }
                }
            }
            */
        }
    }
    
    public static Messaging.SingleEmailMessage sendErrorEmail(String subj, string plainTextBody, List<String> lstToAddresses)
    {
        Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
        singleEmail.setSubject(subj);
        singleEmail.setplainTextBody(plainTextBody);
        singleEmail.setToAddresses(lstToAddresses);
        return singleEmail;
        //Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {singleEmail});
    }
}