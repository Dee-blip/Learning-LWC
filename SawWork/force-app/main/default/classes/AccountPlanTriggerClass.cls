/*Created By: Vivek Baidya
* Created Date: 04-Sep-2019
* Description: Trigger class for AccountPlanTriggerFramework Trigger. 
*/
public class AccountPlanTriggerClass {
    
    /* THIS METHOD IS USED TO SET ACCOUNT PLAN TEMPLATE BASED ON PLAN TYPE */
    public static void setAccountPlanTemplate(List<Account_Plan__c> planListToSetTemplate){
        Map<String,String> planToURL = new Map<String,String>();
        for(Account_Plan_Template_Mapping__c mapping : [SELECT Id, Template_URL__c, Language__c  
                                                        FROM Account_Plan_Template_Mapping__c LIMIT 50000])
        {
            planToURL.put(mapping.Language__c, mapping.Template_URL__c);
        }
        for(Account_Plan__c plan : planListToSetTemplate){
            plan.Quip_Template_URL__c = planToURL.get(plan.Language__c);
            if(Trigger.IsUpdate)
                plan.Quip_New_Document_URL__c = null;
        }
    }
    
    /* THIS METHOD IS USED TO SYNC ACCOUNT PLAN FIELDS (Configured In Metadata) TO ACCOUNT */
    public static void syncToAccount(Map<Account_Plan__c, List<String>> mapOfPlanToChangedFields, Map<String, Object> accountPlanToAccountFieldMapping){
        ByPassAndLimitUtils.disable('syncToAccountPlan');
        if(ByPassAndLimitUtils.isDisabled('syncToAccount')){
            return;
        }
        List<Account> accountListToUpdate = new List<SObject>();
        for(Account_Plan__c newPlan : mapOfPlanToChangedFields.keySet()){
            Account accObj = new Account(Id=newPlan.Account__c);
            for(String changedField : mapOfPlanToChangedFields.get(newPlan)){
                accObj.put(String.valueOf(accountPlanToAccountFieldMapping.get(changedField)), newPlan.get(changedField));
            }
            accObj.put('Validation_Override__c',true);
            accountListToUpdate.add(accObj);
        }
        if(accountListToUpdate.size() > 0){
            GsmUtilClass.doDatabaseUpdate(accountListToUpdate,'AccountPlanTriggerClass','syncToAccount');
        }
    }
    
    /* THIS METHOD IS USED TO SYNC ACCOUNT FIELDS (Configured In Metadata) TO ACCOUNT PLAN */
    public static void syncToAccountPlan(Map<String,Account> accountMap, Map<String, Object> accountPlanToAccountFieldMapping){
        ByPassAndLimitUtils.disable('syncToAccount');
        if(ByPassAndLimitUtils.isDisabled('syncToAccountPlan')){
            return;
        }
        String accountPlanFields = '';
        List<String> accountIds = new List<String>();
        accountIds.addAll(accountMap.keySet());
        for(Object fieldObj : accountPlanToAccountFieldMapping.keySet()){
            accountPlanFields = accountPlanFields + String.valueOf(fieldObj) + ',';
        }
        accountPlanFields = accountPlanFields.removeEndIgnoreCase(',');
        String accountPlanQuery = 'SELECT Id,Account__c,' + accountPlanFields + ' FROM Account_Plan__c WHERE Account__c IN : accountIds';
        List<Account_Plan__c> listOfPlanToUpdate = new List<Account_Plan__c>();
        for(Account_Plan__c existingPlan : Database.query(accountPlanQuery)){
            for(String planField : accountPlanToAccountFieldMapping.keySet()){
                existingPlan.put(planField, accountMap.get(existingPlan.Account__c).get(String.valueOf(accountPlanToAccountFieldMapping.get(planField))));
            }
            listOfPlanToUpdate.add(existingPlan);
        } 
        if(listOfPlanToUpdate.size() > 0){
            GsmUtilClass.doDatabaseUpdate(listOfPlanToUpdate,'AccountPlanTriggerClass','syncToAccountPlan');
        }
    }
    
    /* THIS METHOD IS USED TO SET NEW DOCUMENT URL WHILE CLONING OF ACCOUNT PLAN */
    public static void setNewDocumentUrlForCloning(Map<Account_Plan__c, Id> accPlanToAccId){
        Map<Id, String> accPlanIdToAccPlan = new Map<Id, String>();
        for(Account_Plan__c oldPlan : [SELECT Id, Quip_New_Document_URL__c 
                                       FROM Account_Plan__c 
                                       WHERE Id IN : accPlanToAccId.values()])
        {
            accPlanIdToAccPlan.put(oldPlan.Id, oldPlan.Quip_New_Document_URL__c);
        }
        for(Account_Plan__c newPlan : accPlanToAccId.keySet()){
            newPlan.Quip_New_Document_URL__c = accPlanIdToAccPlan.get(newPlan.getCloneSourceId());
        }
    }
    
    /* THIS METHOD IS USED TO RESTRICT USER TO CREATE MULTIPLE ACCOUNT PLAN FOR THE SAME TIME PERIOD */
    public static void validatePlanStatus(Map<Account_Plan__c, Id> plansToValidateStatus){
        Map<Id, List<Account_Plan__c>> accIdToAccountPlans = new Map<Id, List<Account_Plan__c>>();
        for(Account_Plan__c existingPlan : [SELECT Id, Plan_Start_Date__c, Plan_End_Date__c, Account__c 
                                          FROM Account_Plan__c 
                                          WHERE Account__c IN : plansToValidateStatus.values()])
        {
            if(accIdToAccountPlans.containsKey(existingPlan.Account__c)){
                List<Account_Plan__c> planList = accIdToAccountPlans.get(existingPlan.Account__c);
                planList.add(existingPlan);
                accIdToAccountPlans.put(existingPlan.Account__c,planList);
            }
            else{
                accIdToAccountPlans.put(existingPlan.Account__c,new List<Account_Plan__c>{existingPlan});
            }
        }
        for(Account_Plan__c newPlan : plansToValidateStatus.keySet()){
            if(accIdToAccountPlans.containsKey(newPlan.Account__c)){
                for(Account_Plan__c existingPlan : accIdToAccountPlans.get(newPlan.Account__c)){
                    if(((newPlan.Plan_Start_Date__c >= existingPlan.Plan_Start_Date__c && newPlan.Plan_Start_Date__c <= existingPlan.Plan_End_Date__c) || 
                        (newPlan.Plan_End_Date__c >= existingPlan.Plan_Start_Date__c && newPlan.Plan_End_Date__c <= existingPlan.Plan_End_Date__c) || 
                        (newPlan.Plan_Start_Date__c <= existingPlan.Plan_Start_Date__c && newPlan.Plan_End_Date__c >= existingPlan.Plan_End_Date__c)))
                    {
                        newPlan.addError('There is already an Account Plan during this period.');
                    }
                }
            }
        }
    }
    
    /* THIS METHOD IS USED TO CAPTURE ACCOUNT TEAM MEMBER EMAIL ADDRESSES & SYNC ACCOUNT FIELDS (Configured In Metadata) TO ACCOUNT PLAN */
    public static void setAccountTeamMemberEmailAddresses(List<Id> accountIds, List<Account_Plan__c> newAccountPlans){
        Map<Id,String> accIdToMemberEmailAddresses = new Map<Id,String>();
        Map<Id,Account> accountIdToAccount = new Map<Id,Account>();
        Map<String, Object> accountPlanToAccountFieldMapping = (Map<String, Object>)JSON.deserializeUntyped([SELECT Value__c FROM GSM_Settings_Verbose__mdt WHERE DeveloperName = 'AccountPlanToAccountFieldMapping'][0].Value__c);
        String accountFields = '';
        for(Object fieldObj : accountPlanToAccountFieldMapping.values()){
            accountFields = accountFields + String.valueOf(fieldObj) + ',';
        }
        accountFields = accountFields.removeEndIgnoreCase(',');
        String accountQuery = 'SELECT Id,(SELECT Id, UserId, User.Email, AccountId FROM AccountTeamMembers),' + accountFields + ' FROM Account WHERE Id IN : accountIds';
        
        for(Account acc : Database.query(accountQuery)){
            for(AccountTeamMember atm : acc.AccountTeamMembers){
                if(atm.User.Email.endsWith('@akamai.com') && atm.User.Email != UserInfo.getUserEmail()){
                    if(accIdToMemberEmailAddresses.containsKey(atm.AccountId)){
                        String emails = accIdToMemberEmailAddresses.get(atm.AccountId);
                        emails = emails + atm.User.Email + ',';
                        accIdToMemberEmailAddresses.put(atm.AccountId, emails);
                    }
                    else{
                        String emails = atm.User.Email + ',';
                        accIdToMemberEmailAddresses.put(atm.AccountId, emails);
                    }
                }
            }
            accountIdToAccount.put(acc.Id,acc);
        }
        
        string adminEmail = GsmUtilClass.getGSMSettingValue('Quip_AdminEmails');
        adminEmail = adminEmail.trim();
        for(Account_Plan__c plan : newAccountPlans){
            if(accIdToMemberEmailAddresses.containsKey(plan.Account__c)){
                String emails = accIdToMemberEmailAddresses.get(plan.Account__c);
                emails = emails + adminEmail;
                if(emails!='' && emails!=null){
                    plan.Account_Team_Member_s_Email__c = emails;
                }
            }else{
                plan.Account_Team_Member_s_Email__c = adminEmail;
            }
            for(String planField : accountPlanToAccountFieldMapping.keySet()){
                plan.put(planField, accountIdToAccount.get(plan.Account__c).get(String.valueOf(accountPlanToAccountFieldMapping.get(planField))));
            }
        }
    }
    
    //SFDC-6112
    public static void validateQuipConnection(List<Account_Plan__c> accountPlanTriggerNew){
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('Quip_ConnectToQuipErrorFeature')){
            String quipExternalDataSourceId = GsmUtilClass.getGSMSettingValue('Quip_ExternalDataSourceId');
            list<ExternalDataUserAuth> userList = [Select Id from ExternalDataUserAuth where ExternalDataSourceId =: quipExternalDataSourceId and UserId =: UserInfo.getUserId()];
            string connectToQuipError = GsmUtilClass.getGSMSettingValue('Quip_ConnectToQuipError');
            for(Account_Plan__c newPlan : accountPlanTriggerNew){
                if(userList.size()==0)
                    newPlan.addError(connectToQuipError);
            }
        }
    }
    
    //SFDC-6112
    public static void stampRemovedTeamMemberEmails(Set<Id> userIds, Set<Id> accountIds, List<AccountTeamMember> members){
        map<Id,String> userIdToEmail = new map<Id,String>();
        map<Id,String> accIdToExistingEmail = new map<Id,String>();
        map<Id,Account> accountsToUpdate = new map<Id,Account>();
        for(User u : [select Id, Email from User where Id IN : userIds]){
            userIdToEmail.put(u.Id,u.Email);
        }
        for(Account acc : [select Id,Removed_Account_Team_Emails__c from Account where Id IN : accountIds]){
            accIdToExistingEmail.put(acc.Id, acc.Removed_Account_Team_Emails__c);
        }
        list<Account> accListToUpdate = new list<Account>();
        string existingEmails;
        Account accToUpdate;
        for(AccountTeamMember member : members){
            existingEmails='';
            existingEmails=accIdToExistingEmail.get(member.AccountId);
            if(existingEmails!= null && existingEmails.contains(userIdToEmail.get(member.UserId)))
                continue;
            
            if(existingEmails!=null && existingEmails!='')
                existingEmails+=','+userIdToEmail.get(member.UserId);
            else
                existingEmails=userIdToEmail.get(member.UserId);
            accIdToExistingEmail.put(member.AccountId,existingEmails);
            if(existingEmails.length()<=255){
                accToUpdate = new Account(Id=member.AccountId,Removed_Account_Team_Emails__c=existingEmails,Validation_Override__c=true);
                accountsToUpdate.put(member.AccountId,accToUpdate);
            }
        }
        if(accountsToUpdate.size()>0){
            ByPassAndLimitUtils.disable('AccountTriggerGeneric');
            GsmUtilClass.doDatabaseUpdate(accountsToUpdate.values(),'AccountPlanTriggerClass','stampRemovedTeamMemberEmails');
        }
    }
    
    public static void validateAccountPlanOwner(Map<Id, Account_Plan__c> accIdToAccountPlan){
        Id userId = UserInfo.getUserId();
        List<String> teamMemberRoleForAccountPlan = GsmUtilClass.getGSMSettingValue('ATMRoleForAccountPlan').split(',');
        Boolean flag;
        for(Account acc : [Select id, OwnerId, (Select Id, TeamMemberRole, UserId from AccountTeamMembers) from Account where Id in :accIdToAccountPlan.keySet()]){
            flag = false;
            if(acc.OwnerId == userId){
                flag = true;
            }
            else{
                for(AccountTeamMember atm : acc.AccountTeamMembers){
                    if(teamMemberRoleForAccountPlan.contains(atm.TeamMemberRole) && atm.UserId == userId){
                        flag = true;
                        break;
                    }
                }
            }
            if(!flag){
                accIdToAccountPlan.get(acc.id).addError('Only Account Owner, Sales Primary, Sales Secondary and GAM is allowed to create/initiate the Account Plan, on an Account.');
            }
        }
    }

    /* THIS METHOD IS USED TO ARCHIVE EXISTING PLANS WHEN NEW ACCOUN PLAN IS CREATED */
    public static void archiveAccountPlans(List<Id> accountIds){
        List<Account_Plan__c> lstArchivePlans = new List<Account_Plan__c>();
        for(Account_Plan__c plan : [Select Id,Archived__c from Account_Plan__c 
                                        where Account__c in : accountIds and Archived__c = false]){
            plan.Archived__c =true;                          
            lstArchivePlans.add(plan);                               
        }
        
        if(lstArchivePlans.size()>0){
            GsmUtilClass.doDatabaseUpdate(lstArchivePlans,'AccountPlanTriggerClass','archiveAccountPlans');
        }
    }
        
}