public class EmailNotificationConfig
{
    private final Email_Notification_Config__mdt emConfig;
    public EmailNotificationConfig(String cronJobType)
    {
        emConfig = [select Business_User_Email_CC__c, Business_User_Email_To_Address__c, Class_Name__c, CSV_Fields__c, CSV_Header__c, Email_Template_Developer_Name__c from Email_Notification_Config__mdt where Batch_Job_Type__c=:cronJobType];
    }

    public String getCSVHeader()
    {
        return emConfig.CSV_Header__c;
    }

    public String getCSVFields()
    {
        return emConfig.CSV_Fields__c;
    }

    public EmailTemplate getTemplate()
    {
        return [select Body,HtmlValue,Subject from EmailTemplate where DeveloperName=:this.emConfig.Email_Template_Developer_Name__c][0];
    }

    //SFDC-1723
    public String getBusinessUserToAddress()
    {
        return emConfig.Business_User_Email_To_Address__c;
    }
    /*
    public String getBusinessUserCCAddress()
    {
        return emConfig.Business_User_Email_CC__c;
    }
    */

}