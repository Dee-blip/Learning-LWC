global class EB_UtilApplication
{
    /*
    Authors: satish
    Description: fetches the custom setting values
    
    Created Date :
    Modification Date and modifications done:
    1. 06/29/2010    included a method to fetch value from a new custom setting EBCS_ApplicationTextArea, which stores texts with line breaks
    2. 08/-/2010  retained only the custom setting values that are fetched via this class.                    
    */
    
    public static String getProperty(String strName)
    {
        EBCS_Application__c objApp = EBCS_Application__c.getInstance(strName);
        return (objApp.Value__c);
    }


    public static String getProperty_RowsPerPage()
    {
        return (getProperty('RowsPerPage'));
    }

    public static String getProperty_DebugSQL(){
        return (getProperty('DebugSQL'));
    }
    
    public static String getProperty_EnvironmentURL(){
        return (getProperty('EnvironmentURL'));
    }
    
    public static String getProperty_LimitSQL(){
        return (getProperty('LimitSQL'));
    }
    
    
    /* ==============================================================================================
    descripion: this function retrieves the value of custom settings which specifies the batch size. CR# 794811,813459
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :on 9/29/2010 
    code review:
    =================================================================================================== */
    webservice static Integer getPropertyFromJS(String strName)
    {
    	Integer batchSize;
        EBCS_Application__c objApp = EBCS_Application__c.getInstance(strName);
        batchSize = Integer.valueof((objApp.Value__c).trim());
        return (batchSize);
    }
}