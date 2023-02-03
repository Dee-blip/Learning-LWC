/***
    PLM_PLUViewControllerTestClass
    @author : Chandra Lohani(clohani@akamai.com)
       
    @History
 	--Developer		        --Date			--Change
	Chandra Mohan Lohani   04-10-2011   	Created the class.
																		 																									
											 											   
*/
@isTest
private class PLM_PLUViewControllerTestClass {
	
	private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=pUsrAlias+'__new_user@akamai.com',profileid = pr.Id, UserRoleId = null );
        return newUser;     
    }
    
  
  
  private  static PACE_Program__c CreatePACEProgram(String name,User productManager1, User generalUser1){

    PACE_Program__c program = new PACE_Program__c();
    
    program.Division__c = 'Media';
  
    program.Product_Manager__c = productManager1.Id;
    program.Program_Manager__c = productManager1.Id;
    program.Program_Type__c = 'New Product';
    program.Version__c = '1.0';

    return program;


  }
	
	static testMethod void PLUHomePage_Active()
	{
		/*List<Launch_Item__c> activeliList=[select PLU__c from Launch_Item__c where Archive__c=true];
                Set<Id> activePluIdSet=new Set<Id>();
                for(Launch_Item__c li: activeliList)
                {
                 activePluIdSet.add(li.PLU__c);
                }
		List<PLU__C> pluList =[select Id,Name,PLU_Date__c from PLU__c where ID NOT IN : activePluIdSet order by PLU_Date__c ASC];*/
		List<PLU__C> pluList =[select Id,Name,PLU_Date__c from PLU__c where Archive__c = false order by PLU_Date__c ASC];
		Integer pluCount =pluList.size();
		
		PageReference pluPageReference=new PageReference('/apex/PLM_PLUHomepage');
		Test.setCurrentPageReference(pluPageReference);
		PLM_PLUViewController pluController=new PLM_PLUViewController();
				
		List<PLU__c> pluControllerList=pluController.getPaginatedPLUList();
		Integer pluPageSize=Integer.valueOf(pluController.defaultPLUPageSize);
		if(pluList.size()>pluPageSize)
		{
		    System.assertEquals(pluControllerList.size(),pluPageSize);
		}
		else if(pluList.size()<pluPageSize)
		{
			System.assertEquals(pluControllerList.size(),pluList.size());
		}
		
		for(Integer i=0;i< pluControllerList.size();i++)
		{
			System.assertEquals(pluList[i].Id,pluControllerList[i].Id);
		}
		
		pluPageReference.getParameters().put('activePageSize','5');
		test.setCurrentPageReference(pluPageReference);
		pluController.changePLUPageSize();
		System.assertEquals(pluController.paginationController.getPageSize(),5);
		
		
		
		if(pluController.hasActivePLUNext)
		{
			pluController.activenext();
			pluControllerList=pluController.getPaginatedPLUList();
			if(pluControllerList.size() >= 5)
			{
				if((pluCount-5) >= pluControllerList.size())
				{
					System.assertEquals(pluControllerList.size(),5);
				}
			}
			else
			{
				System.assertEquals(pluControllerList.size(),pluCount-5);
			}
			
		}
		
		if(pluController.hasActivePLUPrevious)
		{
			pluController.activePrevious();
			pluControllerList=pluController.getPaginatedPLUList();
			System.assertEquals(pluControllerList.size(),5);
			
		}
		pluController.activenext();
		pluController.activePrevious();
		pluController.activeFirst();
	    pluController.activeLast();
	}


static testMethod void PLUHomePage_Archive()
	{
		/*List<Launch_Item__c> archiveliList=[select PLU__c from Launch_Item__c where Archive__c=true];
                Set<Id> archivePluIdSet=new Set<Id>();
                for(Launch_Item__c li: archiveliList)
                {
                 archivePluIdSet.add(li.PLU__c);
                }
		List<PLU__C> pluList =[select Id from PLU__c where ID IN : archivePluIdSet order by PLU_Date__c ASC];*/
		List<PLU__C> pluList =[select Id,Name,PLU_Date__c from PLU__c where Archive__c = true order by PLU_Date__c DESC];
		Integer pluCount =pluList.size();
		
		PageReference pluPageReference=new PageReference('/apex/PLM_PLUHomepage');
		Test.setCurrentPageReference(pluPageReference);
		PLM_PLUViewController pluController1=new PLM_PLUViewController();
				
		List<PLU__c> pluControllerList=pluController1.getPaginatedArchivedPLUList();
		Integer pluPageSize=Integer.valueOf(pluController1.defaultArchivedPLUPageSize);
		if(pluList.size()>pluPageSize)
		{
		    System.assertEquals(pluControllerList.size(),pluPageSize);
		}
		else if(pluList.size()<pluPageSize)
		{
			System.assertEquals(pluControllerList.size(),pluList.size());
		}
		
		for(Integer i=0;i< pluControllerList.size();i++)
		{
			System.assertEquals(pluList[i].Id,pluControllerList[i].Id);
		}
		
		pluPageReference.getParameters().put('pageSize','5');
		test.setCurrentPageReference(pluPageReference);
		pluController1.changeArchivedPLUPageSize();
		System.assertEquals(pluController1.paginationArchivedController.getPageSize(),5);
		

		
		
		if(pluController1.hasArchivedPLUNext)
		{
			pluController1.next();
			pluControllerList=pluController1.getpaginatedArchivedPLUList();
			if(pluControllerList.size() >= 5)
			{
				if((pluCount-5) >= pluControllerList.size())
				{
					System.assertEquals(pluControllerList.size(),5);
				}
			}
			else
			{
				System.assertEquals(pluControllerList.size(),pluCount-5);
			}
			
		}
		if(pluController1.hasArchivedPLUPrevious)
		{
			pluController1.previous();
			pluControllerList=pluController1.getpaginatedArchivedPLUList();
			System.assertEquals(pluControllerList.size(),5);
			
		}
		pluController1.next();
		pluController1.previous();
		pluController1.first();
		pluController1.last();
		
	}

/*static testMethod void initTestMethod()
{
	List<PLU__C> pluList =[select Id,Name,PLU_Date__c from PLU__c where Archive__c = false order by PLU_Date__c ASC];
		Integer pluCount =pluList.size();
		
		PageReference pluPageReference=new PageReference('/apex/PLM_PLUHomepage');
		Test.setCurrentPageReference(pluPageReference);
		PLM_PLUViewController pluController2=new PLM_PLUViewController();
				
		List<PLU__c> pluControllerList=pluController2.getPaginatedPLUList();
		pluController2.pluId = pluControllerList[0].Id;
		pluController2.init();
		
}*/

static testMethod void multipleTestMethods(){
	User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
    insert testUser;
        
    User productManager = CreateUser('pr_Mg77', 'Product Operations', 'Worldwide');
    insert productManager;
  
    User generalUser = CreateUser('TS_US77', 'Sales Operations', 'Sales Operations');
    insert generalUser;
    Test.startTest();
        
    Product_Line__c plc = new Product_Line__c();
    plc.Name = 'Application Acceleration';
    insert plc;
    
    PLU__c plu = new PLU__c();
    plu.Name = 'Mar-2011';
    plu.PLU_Date__c = Date.today();
    insert plu;
        
    PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
    insert ppc;
    
    Launch_Item__c li = new Launch_Item__c();
    
    	li.PLU__c = plu.Id; 
    	li.Product_Manager__c = testUser.Id;
        li.Name = 'test_launch_item';      
        li.PLU__c = plu.Id; 
        li.Division__c='Media';
        li.Program__c=ppc.Id;
        insert li;
        
        Launch_Item__c li2 = new Launch_Item__c();
    
    	li2.PLU__c = plu.Id; 
    	li2.Product_Manager__c = testUser.Id;
        li2.Name = 'test_launch_item';      
        li2.PLU__c = plu.Id; 
        li2.Division__c='Media';
        li2.Program__c=ppc.Id;
        insert li2;
  
  PLM_PLUViewController pluController=new PLM_PLUViewController();
  PageReference pageRef=pluController.createNewPLU();
  PageReference pageRef1=pluController.setFunctionalApprovers();
  PageReference pageRef2=pluController.showArhivedLaunches();
   List<Launch_Item__c> liList = new List<Launch_Item__c>();
   liList.add(li);
   liList.add(li2);
   
   pluController.launchItemList = liList;
   pluController.pluId = plu.Id;
   
   PageReference pageRefe = pluController.createFunctionalApprovals();
		      
   List<SelectOption> testSelstList = pluController.getDefaultAPageSizeOptionsList(); 
   
   //pluController.init();
	
}

}