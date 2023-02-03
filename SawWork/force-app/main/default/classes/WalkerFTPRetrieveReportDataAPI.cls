/******

Author: Sharath Ravishankar
Created Date: 10/11/2016
Description: This is the REST class used to fetch contents from the report given the report id using Pagereference. This is required 
            for dropping Walker survey files automatically to FTP server. 
CR : 3453881

Developer               Date                Description
Sharath Ravishankar     24th April 2017     CR 3710162 : The previous solution of replacing '\n' with the
                                            replaceALL was exceeding the heap space
                                            for voluminous data. Hence a custom replace function is provided.
                                                

*/
@RestResource(urlMapping='/retrievereportdata')
global class WalkerFTPRetrieveReportDataAPI 
{
    @HttpPost
    global static String FetchData(String reportid)
    {
        String fileContent;
        //Check the default case
        Boolean useReplaceAll = TRUE;
        String input;
        Integer chunkIterator;
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        PageReference p = new PageReference('/' + reportid + '?enc=UTF-8&csv=1');

        for (Walker_FTP_File_Drop_Setting__mdt settingVar : [SELECT QualifiedApiName,flagValue__c FROM Walker_FTP_File_Drop_Setting__mdt] )
        {
            if(settingVar.QualifiedApiName == 'useReplaceAll')
            {
                useReplaceAll = settingVar.flagValue__c;
            }

        }
        //for the test class, since it has cannot process getContent().
        input = (system.Test.isRunningTest()) ? 'BlankString' : p.getContent().toString();
        
        //Initially replaceAll() used to fail for huge records in the report. 
        //Custom replace in salesforce also used to hit a limit due to heap size .
        //Hence the replaceAll is done in mule flow
        if(useReplaceAll)
        {
            return input.replaceAll('"\n','"\r\n');
            //\r\n is the required terminator asked by the Walker systems.
        }
        else
        {
            return input;
        }
        
    }
}