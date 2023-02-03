@isTest(seeAllData=false)
public class Contract_Extension_ControllerTest
{
    public static testmethod void  formattedDateString()
    {
        Contract_Extension_Controller.ReturnFormattedDateString(Date.today(),'YYYY-MM-DD');
    }
    
    static testmethod void unitTestForContractExtension()
    {
        
        System.runAs(utilTestClass.getTestRunUser())
        {
            Account newAccount = utilTestClass.CreateAccount('_TEST_ Account 12');
            newAccount.Type = 'Agency - Active';
            insert newAccount;
            
            Opportunity newOppty = utilTestClass.CreateOpportunity('TestOppty','1-Create');
            newOppty.CloseDate = Date.today();
            insert newOppty;
            
            Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
            contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
            contractHeader.Name = '_TEST CONTRACT _ 12';
            contractHeader.Account_Name__c = newAccount.Id;
            contractHeader.Active__c = true;
            contractHeader.Locked__c = true;
            contractHeader.Effective_End_Date__c = Date.today();
            contractHeader.Currency__c = 'USD';
            contractHeader.Opportunity_Name__c = newOppty.Id;
            
            insert contractHeader;
            
            PageReference extendPage = Page.Contract_Extension;
            Test.setCurrentPageReference(extendPage);
            extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
            extendPage.getParameters().put('requestType', 'BEDD');
            //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
            //Apexpages.currentPage().getParameters().put('requestType', 'ce');
            Contract_Extension_Controller controller = new Contract_Extension_Controller();
            //controller.automationRequestType = 'ce';
            // Extension date
            if(controller.opp!=null){
                controller.opp.CloseDate = Date.today().addDays(30);
                controller.submit();
                controller.cancel();
                controller.viewOA();
                controller.viewOppty();
            }
            
            controller.deferToDate = 'Date';
            controller.contractAlreadyExtended = false;
            String errorMessage = Contract_Extension_Controller.getErrorMessage();
        }
    }
    
    static testmethod void unitTestForContractExtension1()
    {
        
        System.runAs(utilTestClass.getTestRunUser())
        {
            Account newAccount = utilTestClass.CreateAccount('_TEST_ Account 12');
            newAccount.Type = 'Agency - Active';
            insert newAccount;
            
            Opportunity newOppty = utilTestClass.CreateOpportunity('TestOppty1','1-Create');
            newOppty.CloseDate = Date.today();
            insert newOppty;
            
            Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
            contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
            contractHeader.Name = '_TEST CONTRACT _ 12';
            contractHeader.Account_Name__c = newAccount.Id;
            contractHeader.Active__c = true;
            contractHeader.Locked__c = true;
            contractHeader.Currency__c = 'USD';
            contractHeader.Effective_End_Date__c = Date.today();
            contractHeader.Opportunity_Name__c = newOppty.Id;
            
            insert contractHeader;
            String errorMessage = Contract_Extension_Controller.getErrorMessage();
            
            PageReference extendPage1 = Page.Contract_Extension;
            Test.setCurrentPageReference(extendPage1);
            extendPage1.getParameters().put('id', String.valueOf(contractHeader.Id));
            extendPage1.getParameters().put('requestType', 'CE');
            Contract_Extension_Controller controller1 = new Contract_Extension_Controller();
            if(controller1.opp!=null)           {
                controller1.opp.CloseDate = Date.today().addDays(30);
                controller1.isBEDDefermentRequest = false;
                controller1.title = 'TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTest';
                controller1.submit();
                controller1.cancel();
                controller1.viewOA();
                controller1.viewOppty();
            }
            controller1.deferToDate = 'Date';
            controller1.strErrMsg = 'Test Error Msg';
            controller1.SetErrorMsg('Contract_Extension_Error_MissingType');
            controller1.contractAlreadyExtended = false;
        }
    }
}