public class HD_PageAnalytics {
	/*
	@Author: Nikhil Karn
	@Date: 30th Oct, 2017
	@Last Modified By:
	@Details: This class is used to save the details of UI Page Analytics Component.
	*/
    @AuraEnabled
    public static void addPageAudit(String incident,String pageName,Datetime pageVisitTime,String pageUrl,String browserName,String browserVersion)
    {
        try
        {
            HD_Page_Analytic__c  pageAnalytic = new HD_Page_Analytic__c ();
            pageAnalytic.Name = pageName;
            pageAnalytic.Page_URL__c=pageUrl;
            pageAnalytic.User__c = UserInfo.getUserId();
            pageAnalytic.Incident__c = incident;
            pageAnalytic.Page_Visit_Date_and_Time__c = pageVisitTime;
            pageAnalytic.Browser_Name__c = browserName;
            pageAnalytic.Browser_Version__c =browserVersion;
            //System.debug(pageAnalytic);
            insert(pageAnalytic);
        }
        catch(Exception e)
        {
            HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),incident);
        }
    }
}