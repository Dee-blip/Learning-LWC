/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(4.4)    DESCRIPTION                                                       

|  ===========      =========       =======     =========== 

|  13-Sep-2015		Himanshu Kar	2924517 	This class is called from - SC_Autogen_ExistingCOB_Support
												- Used for Auto-gen for PIVC Reporting
												- Associated Page - SC_PIVCReportPage
+=====================================================================================================*/

public class SC_PIVCReportClass{

    // List to display Contract Records in VF Page
    public List<Merge_Contract_Header__c> contractList {get; set;}
    private ApexPages.StandardController controller;
    
    // Variables for Passing Parameters in VF Page
    public string accountName {get; set;}
    public string OrgContractId {get; set;}
    
    public SC_PIVCReportClass(ApexPages.StandardController Controller){
        
        // Getting Parameters from URL
        string getAccountId = ApexPages.currentPage().getParameters().get('AccountId');
        accountName = ApexPages.currentPage().getParameters().get('AccountName');
        OrgContractId = ApexPages.currentPage().getParameters().get('OrgContractId');
        
        // Contract Query Method
        contractList = [select Id,Name,Effective_Start_Date__c,Effective_End_Date__c,
                            createddate,AKAM_Created_Date__c 
    						from Merge_Contract_Header__c 
    						where Account_Name__c = :getAccountId 
                            order by createddate asc];
        
    }
     
}