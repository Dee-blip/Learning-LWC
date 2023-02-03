public class AccountHealthDashboardRedirect {

	public Id recordId {get;set;}
	PageReference pageRef;
	String param;

	public PageReference init()
    {

    	recordId = ApexPages.currentPage().getParameters().get('recordId');
		System.debug('recordId: '+recordId);
    	if(recordId != null){
            param = '';
            Account acc = [Select id, Name, AKAM_Account_ID__c from account where id = :recordId];
            param = acc.Name + ' (' + acc.AKAM_Account_ID__c + ')';
            param = EncodingUtil.urlEncode(param, 'UTF-8');
            param = param.replace('%2C','%5C%2C');
            //acc.Account_Profile_URL_Param__c = param;
        }
        //https://a360.akamai.com/#/views/AccountProfile_0/AccountProfile?Account%20Filter=2KDirect, Inc. (1-5OSU)
        String AccountHealthDashboardLink = GSMUtilClass.getGSMSettingValue('Account_Health_Dashboard_Link');
        System.debug('Param: '+param);
    	pageRef = new PageReference(AccountHealthDashboardLink + param);
        pageRef.setRedirect(true);
        return pageRef; 
            
    }

}