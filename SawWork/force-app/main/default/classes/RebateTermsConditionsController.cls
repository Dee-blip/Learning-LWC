public class RebateTermsConditionsController {

    public String rebateTCText{get;set;}
    public String rebateTCText1{get;set;}
    public String contactId{get;set;}
    public String notificationMessage{get;set;}
    public String returnUrlLabel{get;set;}
    private Account partnerAccount;
    private String partnerAccountId;
    private String returnUrlId;
    private PageReference returnUrl;
    private PageReference pRef;
    private List<Account> childAccountList;

    public RebateTermsConditionsController ()
        {

            rebateTCText=GsmUtilClass.getGSMSettingValue('RebateTCController_RebateText');
            rebateTCText1=GsmUtilClass.getGSMSettingValue('RebateTCController_RebateText1');
            partnerAccountId=ApexPages.currentPage().getParameters().get('accountId');
            returnUrlLabel='<<Back to Opportunity';
            returnUrlId= String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id').escapeHtml4()); // SFDC 5952 Added escapehtml4 and escaped single quotes
            notificationMessage=GsmUtilClass.getGSMSettingValue('RebateTCController_NotificationMessage');
            if(partnerAccountId!=null && partnerAccountId !='')
            {
                partnerAccount=[select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,Rebate_TC_Rejected_At__C,Validation_Override__c  from Account where id =:partnerAccountId];
                childAccountList=[select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,Rebate_TC_Rejected_At__C,Validation_Override__c from Account where parentId=:partnerAccountId];
                notificationMessage=notificationMessage.replace('#account#',partnerAccount.Name);
                notificationMessage=notificationMessage.replace('#year#',''+DateTime.Now().year());
            }
            else if(returnUrlId!=null && returnUrlId!='')
            {
                Opportunity opp=[Select Id,Partner_Owner__r.AccountId from Opportunity where id=:returnUrlId];
                if(opp!=null)
                {
                    partnerAccount=[select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,Rebate_TC_Rejected_At__C,Validation_Override__c  from Account where id =:opp.Partner_Owner__r.AccountId];
                    //childAccountList=[select Id,Name,Rebate_TC_Status__c,Rebate_TC_Accepted_At__C,Rebate_TC_Rejected_At__C,Validation_Override__c from Account where parentId=:opp.Partner_Owner__r.AccountId];
                    notificationMessage=notificationMessage.replace('#account#',partnerAccount.Name);
                    notificationMessage=notificationMessage.replace('#year#',''+DateTime.Now().year());
                }
            }
            else
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR,'Invalid Account Id'));
            }
            if(returnUrlId!=null && returnUrlId!='')
            {
                returnUrl=new PageReference('/'+returnUrlId);
            }
            else returnUrl=null;

        }

    public PageReference reject() {
        List<Account> accountList=new List<Account>();
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
        catch(Exception e)
        {
            pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
        }
        return returnUrl;
    }

    public PageReference goBack()
        {
            return returnUrl;
        }
    public PageReference accept() {

        List<Account> accountList=new List<Account>();
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
        }
        catch(Exception e)
        {
            pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
        }
        return returnUrl;
    }
}