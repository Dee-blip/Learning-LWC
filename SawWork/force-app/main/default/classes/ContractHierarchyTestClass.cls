@isTest
public class ContractHierarchyTestClass {

    /**
    CreateContractHeader()
  */  
  private static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId, Id NAPID, Id ParentID)
  {
    Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
    newHeader.Original_Contract_Id__c = pOrignalContractId;
    newHeader.Name = pOrignalContractId;
    Integer numDays = 30 ; //Integer.valueOf(GSM_Custom_Settings__c.getInstance('Contract_HierarchyEndDateDays').Value__c)+2;
    newHeader.Effective_End_Date__c = Date.today().addDays(-Integer.valueOf(numDays));
    newHeader.Account_Name__c = pAccountId; 
    newHeader.NAP_Master_Contract__c = NAPID;
    newHeader.Active__c= true;
    newHeader.Parent_Contract__c = ParentID;
    return newHeader;
  }
    
    
    
    
    static testMethod void Contract_Hierarchy_Positive() 
    {
      
      // Create required Records
    System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            Account acc = utilTestClass.CreateAccount('_##Test CH Acc');
            insert acc;
            Merge_Contract_Header__c NAPHeader = CreateContractHeader('#test-nap', acc.Id ,null,null );
            insert NAPHeader;
            Merge_Contract_Header__c ResellerHeader = CreateContractHeader('#test-resTop', acc.Id , NAPHeader.Id,null);
            insert ResellerHeader;
            Merge_Contract_Header__c ResellerChild = CreateContractHeader('#Test-res', acc.Id ,null,ResellerHeader.Id);
            insert ResellerChild;
            Merge_Contract_Header__c Indirect = CreateContractHeader('#Test-Ind', acc.Id ,null,ResellerChild.Id);
            insert Indirect;
            Merge_Contract_Header__c IndirectChild = CreateContractHeader('#Test-IndChild', acc.Id, null,Indirect.Id);
            insert IndirectChild;
            PageReference pageRef = Page.ContractHierarchyPage;
            Test.setCurrentPage(pageRef);

            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(NAPHeader);
            ApexPages.currentPage().getParameters().put('Id',NAPHeader.id); 
            Test.startTest();   
            String returnVal = ContractHierarchyClass.setRequiredData(NAPHeader.id);
            //System.assertEquals('null', returnVal);
            Test.stopTest();
        }
    }
    
    static testMethod void Contract_Hierarchy_Positive2() 
    {
      
      // Create required Records
    System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            Account acc = utilTestClass.CreateAccount('_##Test2 CH Acc');
            insert acc;
            
            Merge_Contract_Header__c ResellerHeader2 = CreateContractHeader('#test-resTop2', acc.Id ,null,null);
            insert ResellerHeader2;
            Merge_Contract_Header__c ResellerChild2 = CreateContractHeader('#Test-res2', acc.Id , null,ResellerHeader2.Id);
            insert ResellerChild2;
            Merge_Contract_Header__c Indirect2 = CreateContractHeader('#Test-Ind2', acc.Id , null,ResellerChild2.Id);
            insert Indirect2;
            Merge_Contract_Header__c IndirectChild2 = CreateContractHeader('#Test-IndChild2', acc.Id, null,Indirect2.Id);
            insert IndirectChild2;
            PageReference pageRef = Page.ContractHierarchyPage;
            Test.setCurrentPage(pageRef);
            //ApexPages.standardController controller = new ApexPages.standardController(aspirante);
            //MultiSelectController pag = new MultiSelectController(controller);

            Test.startTest();
            ApexPages.Standardcontroller sc2 = new ApexPages.Standardcontroller(ResellerHeader2);
            ApexPages.currentPage().getParameters().put('Id',ResellerHeader2.id); 
            String returnVal = ContractHierarchyClass.setRequiredData(ResellerHeader2.id);
            //System.assertEquals('null', returnVal);

            ApexPages.Standardcontroller sc3 = new ApexPages.Standardcontroller(ResellerChild2);
            ApexPages.currentPage().getParameters().put('Id',ResellerChild2.id); 
            returnVal = ContractHierarchyClass.setRequiredData(ResellerChild2.id);
            //System.assertEquals('null', returnVal);
            Test.stopTest();
        }
   
    }
}