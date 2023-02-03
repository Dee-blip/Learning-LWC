/**
    History
        --Developer         --Date              --Description
        Lisha Murthy        05/Sept/2012        CR 1870561 - Renewal Opportunities Dashboard Needs to Appear as a Tab   
                                                - Create the page/controller.

*/

public class CSP_RenewalOpportunitiesTabController 
{
    public Pagereference pageRedirect()
    {
        if(GSM_Custom_Settings__c.getInstance('CSP_SalesProfileIds').Value__c.contains(String.ValueOf(UserInfo.getProfileId()).substring(0,15)))
        {
            PageReference pr = new PageReference(GSM_Custom_Settings__c.getInstance('CSP_SalesReportURL').Value__c);
            pr.getParameters().put('sfdc.tabName',GSM_Custom_Settings__c.getInstance('CSP_TabId').Value__c);
            pr.setRedirect(true);
            return pr;
        }
        else
        {
            String errMessage = 'Insufficient Privileges: You do not have the level of access \n necessary to perform the operation you requested. Please contact your administrator if access is necessary.';
            ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errMessage);
            ApexPages.addMessage(errMsg); 
            return null;
        }
        return null;
    }
    
    //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //@isTest(seeAllData=true)
    //public static void testMe()
    //{
    //    CSP_RenewalOpportunitiesTabController CSPTabController = new CSP_RenewalOpportunitiesTabController();
    //    System.assertEquals(true, GSM_Custom_Settings__c.getInstance('CSP_SalesProfileIds').Value__c.contains(String.valueOf(Userinfo.getProfileId()).substring(0,15)));  
    //}
}