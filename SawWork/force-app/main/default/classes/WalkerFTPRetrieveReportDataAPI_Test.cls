/******

Author: Sharath Ravishankar
Created Date: 10/11/2016
Description: This is the test class written to test the REST class WalkerFTPRetrieveReportDataAPI. It requires a 
			report with the name WalkerFTPSample in the sandbox for testing.
CR : 3453881
*/

@isTest
global class WalkerFTPRetrieveReportDataAPI_Test {
    global Static testmethod void TestFetchData()
    {
        test.startTest();
        String reportId;
        String outputmsg;
        list<report> reportlist;
        reportlist = [Select Id from report where Name='WalkerFTPSample'];
        if(reportlist.size()>0)
        {
            reportid=reportlist[0].Id;
        }
        RestRequest req = new RestRequest();
  		RestResponse res = new RestResponse();
		req.requestURI = '/services/apexrest/retrievereportdata';  //Request URL
		req.httpMethod = 'POST';	//HTTP Request Type
	    RestContext.request = req;
		RestContext.response= res;
        outputmsg = WalkerFTPRetrieveReportDataAPI.FetchData(reportid); 
        test.stopTest();
      
    }

}