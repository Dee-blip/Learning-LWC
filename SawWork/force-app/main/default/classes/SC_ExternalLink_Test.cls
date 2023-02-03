/*=====================================================================================================+
    Class name          :   SC_ExternalLink_Test 
    Author              :   Pinkesh Rathore
    Created             :   31-Jan-17
    Purpose             :   This test class is used to cover code for SC_ExternalLink class

	  Last Modified    Developer  	Purpose            
      =============    =========  	=======
	  23-Sep-2020      Tejaswini     ESESP-4020 : Set seeAllData = false , added testSetup method
==========================================================================================================*/                          
@isTest
public class SC_ExternalLink_Test {

    @testSetup static void setup() {
    	utilTestClass.createCustomSettings(); 
        List<Account> lAc = new List<Account>();
        for(Integer i=0; i<5; i++)
        {
            Account ac = utilTestClass.CreateAccount('TestAccount'+i);
            lAc.add(ac);
        }
        insert lAc;
        
        List<Case> lC = new List<Case>();
        for(Account ac : lAc)
        {
            Case c = utilTestClass.CreateCase(ac.Id);
            lC.add(c);
        }
        
    }
    
    @isTest public static void test_SC_ExternalLink()
    {
		/*List<Account> lAc = new List<Account>();
        for(Integer i=0; i<5; i++)
        {
            Account ac = utilTestClass.CreateAccount('TestAccount'+i);
            lAc.add(ac);
        }
        insert lAc;*/
        
        
        /*List<Case> lC = new List<Case>();
        for(Account ac : lAc)
        {
            Case c = utilTestClass.CreateCase(ac.Id);
            lC.add(c);
        }*/
        
        List<Account> lAc = [Select Id from Account Limit 5];
        List<Case> lC = [Select Id from Case Limit 5];

        
        test.startTest();
        for(Case c : lC)
        {
            PageReference PageRef = Page.SC_ExternalLinks;
            test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(c);
        	ApexPages.currentPage().getParameters().put('Id',c.ID);
            SC_ExternalLink SC_Ext = new SC_ExternalLink();
            SC_Ext.loadLinks();
        }
        test.stopTest();
    }
}