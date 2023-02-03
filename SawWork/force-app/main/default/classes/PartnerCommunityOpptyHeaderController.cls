public without sharing class PartnerCommunityOpptyHeaderController {

    @AuraEnabled
    public static string getObjectName(String recordId){
        return Id.valueOf(recordId).getSObjectType().getDescribe().getName();  
    }

    @AuraEnabled
    public static Opportunity getOppty(String opptyId){
        
        List<Opportunity> opptyList = [select id,isRebateTCToShow__c,Partner_Owner__r.AccountId,Associated_Lead__c,Registration_Status__c 
                                        from Opportunity 
                                        where id=:opptyId];
        if (opptyList.size() > 0) {
            return opptyList[0];
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static Map<String,String> getRebateTermsConditions()
        {
            Map<String,String> response = new Map<String,String>();

            String rebateTCText=GsmUtilClass.getGSMSettingValue('RebateTCController_RebateText');
            response.put('rebateTCText',rebateTCText);
            String rebateTCText1=GsmUtilClass.getGSMSettingValue('RebateTCController_RebateText1');
            response.put('rebateTCText1',rebateTCText1);
            
            String partnerAccountId = [Select Id, Name, profileId, UserType, Contact.AccountId from user where id =: UserInfo.getUserId() limit 1].Contact.AccountId;
        
            String notificationMessage=GsmUtilClass.getGSMSettingValue('RebateTCController_NotificationMessage');
            if(partnerAccountId!=null && partnerAccountId !='')
            {
                Account partnerAccount=[select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,Rebate_TC_Rejected_At__C,Validation_Override__c  from Account where id =:partnerAccountId];
                notificationMessage=notificationMessage.replace('#account#',partnerAccount.Name);
                notificationMessage=notificationMessage.replace('#year#',''+DateTime.Now().year());
            }
            response.put('notificationMessage',notificationMessage);
            return response;

        }

        @AuraEnabled
        public static void accept() {

            System.System.debug('SH : accept');
            List<Account> accountList=new List<Account>();

            String partnerAccountId = [Select Id, Name, profileId, UserType, Contact.AccountId from user where id =: UserInfo.getUserId() limit 1].Contact.AccountId;
            Account partnerAccount = [Select Id,Name, Rebate_TC_Accepted_At__c, Rebate_TC_Rejected_At__c, Rebate_TC_Status__c,
                                        Validation_Override__c 
                                        from Account
                                        where id =:partnerAccountId limit 1 FOR UPDATE];

            List<Account> childAccountList = [select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,
                                                Rebate_TC_Rejected_At__C,Validation_Override__c 
                                                from Account 
                                                where parentId=:partnerAccountId FOR UPDATE];
        
            partnerAccount.Rebate_TC_Accepted_At__c=DateTime.now();
            partnerAccount.Rebate_TC_Rejected_At__c =null;
            partnerAccount.Rebate_TC_Status__c='Accepted';
            partnerAccount.Validation_Override__c =true;
            accountList.add(partnerAccount);
            for(Account acc : childAccountList)
                {
                    acc.Rebate_TC_Accepted_At__c=DateTime.now();
                    acc.Rebate_TC_Rejected_At__c =null;
                    acc.Rebate_TC_Status__c='Accepted';
                    acc.Validation_Override__c =true;
                    accountList.add(acc);
                }
            try
            {
                update accountList;
                System.debug('SH - accept. Updated accounts');
            }
            catch(Exception e) {Error_log__c errorLog = new Error_log__c(Name = 'Rebate TC Accept',Class__c = 'PartnerCommunityOpptyHeaderController',Error_Message__c = e.getMessage() + ' #; ' + e.getStackTraceString()); insert errorLog; PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Rebate TC Accept','Error processing accept request.',500,e.getMessage(),true); throw new AuraHandledException(JSON.serialize(data));}
        }

        @AuraEnabled
        public static void reject() {

            List<Account> accountList=new List<Account>();

            String partnerAccountId = [Select Id, Name, profileId, UserType, Contact.AccountId from user where id =: UserInfo.getUserId() limit 1].Contact.AccountId;
            Account partnerAccount = [Select Id,Name, Rebate_TC_Accepted_At__c, Rebate_TC_Rejected_At__c, Rebate_TC_Status__c,
                                        Validation_Override__c 
                                        from Account
                                        where id =:partnerAccountId limit 1];

            List<Account> childAccountList = [select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,
                                                Rebate_TC_Rejected_At__C,Validation_Override__c 
                                                from Account 
                                                where parentId=:partnerAccountId];
            
            partnerAccount.Rebate_TC_Accepted_At__c=null;
            partnerAccount.Rebate_TC_Rejected_At__c =DateTime.now();
            partnerAccount.Rebate_TC_Status__c='Rejected';
            partnerAccount.Validation_Override__c =true;
            accountList.add(partnerAccount);
            for(Account acc : childAccountList)
                {
                    acc.Rebate_TC_Accepted_At__c=null;
                    acc.Rebate_TC_Rejected_At__c =DateTime.now();
                    acc.Rebate_TC_Status__c='Rejected';
                    acc.Validation_Override__c =true;
                    accountList.add(acc);
                }
            try
            {
                update accountList;
            }
            catch(Exception e) { Error_log__c errorLog = new Error_log__c(Name = 'Rebate TC Accept',Class__c = 'PartnerCommunityOpptyHeaderController',Error_Message__c = e.getMessage() + ' #; ' + e.getStackTraceString()); insert errorLog; PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Rebate TC Reject','Error processing reject request.',500,e.getMessage(),true); throw new AuraHandledException(JSON.serialize(data));}
        }

        //SFDC -9134
        @AuraEnabled
        public static string generateCDlink(){
            string cdLink = GSMUtilClass.getNAPSettingValue('RebateContentDocId');
            //string RebateDocLink = GSMUtilClass.getNAPSettingValue('RebateDocLink');
            string latestcvid = L2Q_ContentDocumentUtilClass.getContentVersionFromCD(cdLink);
            string retLink = '';
            if(latestcvid != ''){
                retLink = URL.getSalesforceBaseUrl().toExternalForm()+'/partners/sfc/servlet.shepherd/version/download/'+latestcvid;

            }

            return retLink;            
        }
}