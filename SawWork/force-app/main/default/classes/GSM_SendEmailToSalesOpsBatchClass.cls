global class GSM_SendEmailToSalesOpsBatchClass implements Schedulable
{
    global void execute(SchedulableContext ctx) 
    {
        validateAndSendEmailToSalesOps();
    }
    
    // SFDC-5465 Send new user email to Sales Ops every 2 days
    public void validateAndSendEmailToSalesOps()
    {
        
        // Get new User list that need to be sent email
        List<User> eligibleNewUserList = new List<User>();
        Set<Id> eligibleNewUserSalesManagerList = new Set<Id>();
        Set<Id> eligibleNewUserPreSalesManagerList = new Set<Id>();
        Set<String> fieldSet = new Set<String>();
        //Map<String, Map<String, String>> teamToEmail = new Map<String, Map<String, String>>();
        String currentYear = System.Today().year()+'%';
        DateTime currTime = System.now();
        DateTime before48Hours = currTime.addHours(-48);
        
        
        Integer timeIntervalInHoursInteger = -96;
        String timeIntervalInHours = GsmUtilClass.getGSMSettingValue('SalesOps_NewUserEmail_TimeInHours'); //168 Hours
        if(timeIntervalInHours != null)
        {
            timeIntervalInHoursInteger = -1 * Integer.valueof(timeIntervalInHours);
        }
        
        
        List<String> managerExcludedProfileName = GsmUtilClass.getGSMSettingValue('Manager_Excluded_Profile_UserProvisionin').split(';');
        Set<Id> managerIds = new Set<Id>();
        for(Account_Reassignment_Rule__c rule : [select Id,Associated_User__c from Account_Reassignment_Rule__c where CreatedDate <: currTime AND CreatedDate >: before48Hours])
        {
            managerIds.add(rule.Associated_User__c);
        }

        /*
        String fieldToQuery = GSMSettings.getVerbose('emailsToSalesPreSales');
        Map<String,Object> emailFields = (Map<String,Object>)JSON.deserializeUntyped(fieldToQuery);

        for(String profile : emailFields.keySet()){
            Map<String, Object> toCCAddress = (Map<String,Object>)JSON.deserializeUntyped(profile);

        }
        */

        List<String> userDivision = GsmUtilClass.getGSMSettingValue('New_Sales_User_Division').split(',');
        List<String> managerSalesProfile = GSMSettings.getVerbose('New_User_s_Manger_Sales_Profile').split(',');
        List<String> managerPreSalesProfile = GsmUtilClass.getGSMSettingValue('New_User_s_Manger_PreSales_Profile').split(',');
        List<String> userRole = GsmUtilClass.getGSMSettingValue('New_User_UserRole').split(',');
        
        // New Sales User whose Profile and Role has not yet been set
        for(User u : [select id, email, ManagerId, Division, Manager.Division, title, GSM_AlertOps_timestamp__c, Manager.name, Name, Manager.Email, Manager.Profile.Name
                      from User where IsActive = true and Division IN :userDivision and ManagerId != null 
                      and ((CreatedDate <: currTime AND CreatedDate >: before48Hours) OR (Manager_Update_Timestamp__c != null AND Manager_Update_Timestamp__c <: currTime AND Manager_Update_Timestamp__c >: before48Hours) OR (ManagerId IN : managerIds) OR (GSM_AlertOps_timestamp__c != null))
                      and Manager.IsActive = true
                      and (Manager.ProfileId IN :managerSalesProfile OR Manager.ProfileId IN :managerPreSalesProfile)
                      and (Manager.UserRole.Name IN :userRole OR Manager.UserRole.Name LIKE : currentYear )
                      and (( ProfileId NOT IN :managerSalesProfile and Manager.ProfileId IN :managerSalesProfile) OR (ProfileId NOT IN :managerPreSalesProfile and Manager.ProfileId IN :managerPreSalesProfile) OR 
                           (UserRole.Name NOT IN :userRole AND (NOT UserRole.Name LIKE : currentYear)))])
        {
            if(u.Division == u.Manager.Division){
                if(titleCheck(u)){     
                    if(u.GSM_AlertOps_timestamp__c == null){
                        eligibleNewUserList.add(u);
                        if(u.Manager.Profile.Name.contains('Sales')){
                            eligibleNewUserSalesManagerList.add(u.ManagerId);
                        }
                        else{
                            eligibleNewUserPreSalesManagerList.add(u.ManagerId);
                        }
                    }
                    else if(datetime.now().addHours(timeIntervalInHoursInteger).isSameDay(u.GSM_AlertOps_timestamp__c) && u.Manager.Profile.Name.contains('Sales')){
                        eligibleNewUserSalesManagerList.add(u.ManagerId);
                        eligibleNewUserList.add(u); 
                    }
                }
            }
        }
        
        List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
        List<String> emailTemplateDevNames = GsmUtilClass.getGSMSettingValue('SalesOps_NewUserEmail_EmailTemplate').split(',');
        List<EmailTemplate> templates = [select Id, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName IN : emailTemplateDevNames Order by DeveloperName];
        EmailTemplate desiredTemplate = new EmailTemplate();
        Map<Id, Account_Reassignment_Rule__c> managerToARRMap = new Map<Id, Account_Reassignment_Rule__c>();
        Map<Id, User> salesOpsIdToUser = new Map<Id, User>();
        List<Id> salesOpsId = new List<Id>();
        
        //get Divisional information from USer's manager's Account reassignment rule
        if(eligibleNewUserSalesManagerList.size()>0){           
            for(Account_Reassignment_Rule__c r : [select Id, Associated_User__c, Sales_Ops_Approver__c, Sales_Ops_Approver__r.manager.email,
                                                /*Geography_Formula__c,Division_Formula__c,Region__c,Division__c,Area__c,*/
                                                SubTerritory__c 
                                                from Account_Reassignment_Rule__c
                                                where Associated_User__c in :eligibleNewUserSalesManagerList])
            {
                managerToARRMap.put(r.Associated_User__c, r);
                salesOpsId.add(r.Sales_Ops_Approver__c);
            }

            if(salesOpsId.size() > 0){
                for(User usr : [Select id, manager.email from user where id IN :salesOpsId]){
                    salesOpsIdToUser.put(usr.id, usr);
                }
            }
        }
        
        for(User newUser : eligibleNewUserList){
            if(newUser.Manager.Profile.Name.contains('Sales')){                           
                Account_Reassignment_Rule__c ruleObj = managerToARRMap.get(newUser.ManagerId);
                if(ruleObj != null && ruleObj.Sales_Ops_Approver__c != null)
                {   
                    if(newUser.GSM_AlertOps_timestamp__c == null){
                        desiredTemplate = templates[1];
                        mailList.add(getEmailFromTemplate(newUser,newUser.Manager, templates[0], True));                            
                    }
                    else{
                        desiredTemplate = templates[2];
                    }
                    User salesOps = salesOpsIdToUser.get(ruleObj.Sales_Ops_Approver__c);
                    mailList.add(getEmailFromTemplate(newUser,salesOps, desiredTemplate, false));
                    newUser.GSM_AlertOps_timestamp__c = datetime.now();
                }
            }
            else{
                if(newUser.GSM_AlertOps_timestamp__c == null){
                    mailList.add(getEmailFromTemplate(newUser, newUser.Manager, templates[0], true));
                    newUser.GSM_AlertOps_timestamp__c = datetime.now();                 
                }
                
            }
        }
        
        // Fire the email to SalesOps based on template
        If(!mailList.isEmpty())
        {
            Messaging.sendEmail(mailList);
        }
        
        //Update new timestamp
        if(!eligibleNewUserList.isEmpty())
        {
            //update eligibleNewUserList;
            GsmUtilClass.doDatabaseUpdate(eligibleNewUserList,'GSM_SendEmailToSalesOpsBatchClass','validateAndSendEmailToSalesOps');
        }
        
    }
    
    
    @TestVisible private Messaging.SingleEmailMessage getEmailFromTemplate(User newUser, User SalesOpsOrManager, EmailTemplate emailTemplate, Boolean HDTicket)
    {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String msgBody = emailTemplate.Body;
        String msgSubject = emailTemplate.Subject;
        List<String> CCListEmail = GsmUtilClass.getGSMSettingValue('New_Sales_Rep_User_Email_CCList').split(';');
        List<String> ToListEmail = GsmUtilClass.getGSMSettingValue('New_Sales_Rep_User_Email_ToList').split(';');
        
        msgBody = msgBody.replace('__UserName__',newUser.Name);
        message.setCcAddresses(CCListEmail);
        
        if(!HDTicket){
            if(newUser.Manager.Profile.Name.contains('Sales')){
                message.setTargetObjectId(SalesOpsOrManager.Id);
                CCListEmail.add(newUser.email);
                CCListEmail.add(SalesOpsOrManager.manager.email);
                message.setCcAddresses(CCListEmail);
            }
            
        }else{
            message.setToAddresses(ToListEmail);
            //HD Ticket creation for Pre-Sales
            if(!newUser.Manager.Profile.Name.contains('Sales')){
                msgSubject = msgSubject.replace('__Team__', 'Pre-Sales');
                msgBody = msgBody.replace('__Team__', 'Pre-Sales team');
                CCListEmail.add(newUser.email);
                CCListEmail.add(newUser.Manager.Email);
                message.setCcAddresses(CCListEmail);
            }
            //HD Ticket creation for Sales
            else{
                msgSubject = msgSubject.replace('__Team__', 'Sales');
                msgBody = msgBody.replace('__Team__', 'Sales team');
            }
            
        }
        
        //set message paramters
        message.setSaveAsActivity(false);
        message.setPlainTextBody (msgBody);
        message.setSubject(msgSubject);
        CCListEmail.add(newUser.email);
        
        return message;    
    }
    
    private boolean titleCheck(User u)
    {
        if( u.title == 'Administrative Assistant..' || 
           u.title == 'Administrative Assistant.Senior.' || 
           u.title == 'Executive Assistant..' ||
           u.title == 'Office Manager..' || 
           u.title == 'Director..Operations' ||
           u.title == 'Product Sales Specialist.Senior.' ||
           u.title == 'Product Sales Specialist..')
        {
            return false;
        }
        else
        {
            return true;
        }
    }
}