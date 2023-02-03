@isTest()
private class PRMSearchOpportunityControllerTestClass
{
    static User partner;
    static User dmlUser = new User(id=UserInfo.getUserId());

    public static Opportunity refreshOpportunity(String opptyId)
    {
        return [select id, Deal_Reg_Account_Discount__c, Deal_Reg_Opportunity_Discount__c, Deal_Reg_Account_Status__c, Deal_Reg_Opportunity_Status__c, Rebate__c, Existing_Opportunity__c from Opportunity where id=:opptyId][0];
    }
    
   static testMethod void testExistingCustomerNewOppty() 
   {
       System.runAs(dmlUser) {
           utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TEST acount PRM');
            acc.Website='www.tstwebite.com';
            
            insert acc;

            Account accnew = utilTestClass.CreateAccount('__ TST account PRM New');
            accnew.isCustomer__c = true;
            accnew.isParentCustomer__c = true;
            accnew.Website='www.Prmwebsite.com';
            insert accnew;
            
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;

            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
            oppty.CloseDate= Date.today();
            oppty.End_Customer_Country__c='India';
            oppty.Customer_Company_Name__c='__TEST acc PRM';
            oppty.End_Customer_Website__c='http://testwebsite.com';
            oppty.End_Customer_Street_Address__c='test';
            oppty.End_Customer_City__c='test';
            oppty.End_Customer_State__c='test';
            oppty.End_Customer_Zip_Code__c='560030';
            oppty.Partner_Involved__c = acc.Id;
            system.runAs(partner)
            {
                insert oppty;
            }
            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRM_search_account_controller fpc = new PRM_search_account_controller();
                pageRef.getParameters().put('pid', accnew.id);
                fpc.AddAccount();
            }
            oppty = refreshOpportunity(oppty.id);
            /*System.assertEquals(oppty.Deal_Reg_Account_Status__c, 'Existing Customer');
            System.assertEquals(oppty.Deal_Reg_Account_Discount__c, 5.0);*/

            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRMSearchOpportunity;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                tempController.createNew();
            }
            oppty = refreshOpportunity(oppty.id);
            //System.assertEquals(oppty.Deal_Reg_Opportunity_Status__c, 'New Opportunity');
            //System.assertEquals(oppty.Deal_Reg_Opportunity_Discount__c, 0.0);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(oppty.id);
            
            // Submit the approval request for the account 
            
            Approval.ProcessResult result = Approval.process(req1);
           
            //System.assertEquals('Pending', result.getInstanceStatus(),'Instance Status'+result.getInstanceStatus());
           
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(oppty.Id),'approveXPercent',False);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            // Use the ID from the newly created item to specify the item to be worked 
        
            req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            
            oppty = refreshOpportunity(oppty.id);
            
            // Verify the results   
            //System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());
            //System.assertEquals(oppty.Rebate__c, '5');*/
            Test.stopTest();
        }

   }

   
   static testMethod void testExistingCustomerExistingOppty() 
   {
       System.runAs(dmlUser) {
           utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TEST account PM');
            acc.Website='www.tprmwebsite.com';
            insert acc;

            Account accnew = utilTestClass.CreateAccount('__ TEST account PRM Nw');
            accnew.Website='www.websiteprm.com';
            accnew.isCustomer__c = true;
            accnew.isParentCustomer__c = true;
            insert accnew;
            
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;
               
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            List<Opportunity> listOfOpportunities = new List<Opportunity>();
            Integer numberOfOpportunities = 3;
            for(integer i=0; i<numberOfOpportunities;i++)
            {
                Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty'+i,'1-Create');
                oppty.CloseDate= Date.today();
                oppty.End_Customer_Country__c='India';
                oppty.Customer_Company_Name__c='__TEST acc PRM';
                oppty.End_Customer_Website__c='http://testwebsite.com';
                oppty.End_Customer_Street_Address__c='test';
                oppty.End_Customer_City__c='test';
                oppty.End_Customer_State__c='test';
                oppty.End_Customer_Zip_Code__c='560030';
                oppty.Partner_Involved__c = acc.Id;
                listOfOpportunities.add(oppty);
            }
            //get the last oppty added as current oppty
            Opportunity oppty = listOfOpportunities[numberOfOpportunities - 1];
            System.debug('Oppty Id before '+oppty);
            system.runAs(partner)
            {
                insert listOfOpportunities;
            }
            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRM_search_account_controller fpc = new PRM_search_account_controller();
                pageRef.getParameters().put('pid', accnew.id);
                fpc.AddAccount();
            }
            oppty = refreshOpportunity(oppty.id);
            /*System.assertEquals(oppty.Deal_Reg_Account_Status__c, 'Existing Customer');
            System.assertEquals(oppty.Deal_Reg_Account_Discount__c, 5.0);*/

            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRMSearchOpportunity;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                pageRef.getParameters().put('pid', listOfOpportunities[numberOfOpportunities -2].id);
                tempController.addOppty();
            }
            oppty = refreshOpportunity(oppty.id);
            System.Debug('Oppty after '+oppty);
            

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(oppty.id);
            
            // Submit the approval request for the account 
        
            Approval.ProcessResult result = Approval.process(req1);
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(oppty.Id),'approveXPercent',False);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            // Use the ID from the newly created item to specify the item to be worked 
        
            req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            
            oppty = refreshOpportunity(oppty.id);
            
            Test.stopTest();
            // Verify the results         
            //System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());        
            
        }

   }

   
   static testMethod void testExistingAccountExistingOppty() 
   {

       System.runAs(dmlUser) {
           utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TET account PRM');
            acc.Website='www.teprmwebsite.com';
            insert acc;

            Account accnew = utilTestClass.CreateAccount('__ TEST accont PRM New');
            accnew.Website='www.twebsiteprm.com';
            accnew.isCustomer__c =false;
            accnew.isParentCustomer__c =false;
            insert accnew;
            
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
               
            List<Opportunity> listOfOpportunities = new List<Opportunity>();
            Integer numberOfOpportunities = 3;
            for(integer i=0; i<numberOfOpportunities;i++)
            {
                Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty'+i,'1-Create');
                oppty.CloseDate= Date.today();
                oppty.End_Customer_Country__c='India';
                oppty.Customer_Company_Name__c='__TEST acc PRM';
                oppty.End_Customer_Website__c='http://testwebsite.com';
                oppty.End_Customer_Street_Address__c='test';
                oppty.End_Customer_City__c='test';
                oppty.End_Customer_State__c='test';
                oppty.End_Customer_Zip_Code__c='560030';
                oppty.Partner_Involved__c = acc.Id;

                listOfOpportunities.add(oppty);
            }
            //get the last oppty added as current oppty
            Opportunity oppty = listOfOpportunities[numberOfOpportunities - 1];
            system.runAs(partner)
            {
                insert listOfOpportunities;
            }
            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRM_search_account_controller fpc = new PRM_search_account_controller();
                pageRef.getParameters().put('pid', accnew.id);
                fpc.AddAccount();
            }
            oppty = refreshOpportunity(oppty.id);

            /*System.assertEquals(oppty.Deal_Reg_Account_Status__c, 'Existing Account');
            System.assertEquals(oppty.Deal_Reg_Account_Discount__c, 5.0);

            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRMSearchOpportunity;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                pageRef.getParameters().put('pid', listOfOpportunities[numberOfOpportunities -2].id);
                tempController.addOppty();
            }
            oppty = refreshOpportunity(oppty.id);
            

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(oppty.id);
            
            // Submit the approval request for the account 
        
            Approval.ProcessResult result = Approval.process(req1);
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(oppty.Id),'approveXPercent',False);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            // Use the ID from the newly created item to specify the item to be worked 
        
            req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            
            oppty = refreshOpportunity(oppty.id);
            
            // Verify the results         
            //System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());        
            */
            Test.stopTest();
        }

   }
   
   static testMethod void testExistingAccountNewOppty() 
   {
        System.runAs(dmlUser) {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TEST accoun PRM');
            acc.Website='www.prmweb.com';
            insert acc;

            Account accnew = utilTestClass.CreateAccount('__ TES account PRM New');
            accnew.Website='www.searprm.com';
            insert accnew;
            
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;
               
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            List<Opportunity> listOfOpportunities = new List<Opportunity>();
            Integer numberOfOpportunities = 1;
            for(integer i=0; i<numberOfOpportunities;i++)
            {
                Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty'+i,'1-Create');
                oppty.CloseDate= Date.today();
                oppty.End_Customer_Country__c='India';
                oppty.Customer_Company_Name__c='__TEST acc PRM';
                oppty.End_Customer_Website__c='http://testwebsite.com';
                oppty.End_Customer_Street_Address__c='test';
                oppty.End_Customer_City__c='test';
                oppty.End_Customer_State__c='test';
                oppty.End_Customer_Zip_Code__c='560030';
                oppty.Partner_Involved__c = acc.Id;

                listOfOpportunities.add(oppty);
            }
            //get the last oppty added as current oppty
            Opportunity oppty = listOfOpportunities[numberOfOpportunities - 1];
            system.runAs(partner)
            {
                insert listOfOpportunities;
            }
            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRM_search_account_controller fpc = new PRM_search_account_controller();
                pageRef.getParameters().put('pid', accnew.id);
                fpc.AddAccount();
            }
            oppty = refreshOpportunity(oppty.id);

            /*System.assertEquals(oppty.Deal_Reg_Account_Status__c, 'Existing Account');
            System.assertEquals(oppty.Deal_Reg_Account_Discount__c, 5.0);

            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRMSearchOpportunity;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                tempController.createNew();
            }
            oppty = refreshOpportunity(oppty.id);
            //System.assertEquals(oppty.Deal_Reg_Opportunity_Status__c, 'New Opportunity');
            //System.assertEquals(oppty.Deal_Reg_Opportunity_Discount__c, 0.0);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(oppty.id);
            
            // Submit the approval request for the account 
        
            Approval.ProcessResult result = Approval.process(req1);
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(oppty.Id),'approveXPercent',False);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            // Use the ID from the newly created item to specify the item to be worked 
        
            req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            
            oppty = refreshOpportunity(oppty.id);
            */
            
            Test.stopTest();
            
            // Verify the results  
            //System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());     
            //System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());        
            //System.assertEquals(oppty.Rebate__c, '5');*/
        }

   }

   static testMethod void testCancelCase() {
        System.runAs(dmlUser) {
           utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TEST account PRM01');
            acc.Website='www.searchprm.com';
            
            insert acc;

            Account accnew = utilTestClass.CreateAccount('__ TEST account PRM New1');
            accnew.isCustomer__c = true;
            accnew.isParentCustomer__c = true;
            accnew.Website='www.oppprm.com';
            insert accnew;
            
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;

            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
            oppty.CloseDate= Date.today();
            oppty.End_Customer_Country__c='India';
            oppty.Customer_Company_Name__c='__TEST acc PRM';
            oppty.End_Customer_Website__c='http://testwebsite.com';
            oppty.End_Customer_Street_Address__c='test';
            oppty.End_Customer_City__c='test';
            oppty.End_Customer_State__c='test';
            oppty.End_Customer_Zip_Code__c='560030';
            oppty.Partner_Involved__c = acc.Id;
            system.runAs(partner)
            {
                insert oppty;
            }
            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                tempController.cancel();
            }
        }
    }

   static testMethod void testNewAccountNewOppty() 
   {
   System.runAs(dmlUser) {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TEST account PRM');
            acc.Website='www.opptywebsi.com';
            insert acc;

            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('Test__Rule', opptySCMOwnerUser.Id, 'Sales Operations');
            insert rule;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
               
            List<Opportunity> listOfOpportunities = new List<Opportunity>();
            Integer numberOfOpportunities = 1;
            for(integer i=0; i<numberOfOpportunities;i++)
            {
                Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty'+i,'1-Create');
                oppty.CloseDate= Date.today();
                oppty.End_Customer_Country__c='India';
                oppty.Customer_Company_Name__c='__TEST acc PRM';
                oppty.End_Customer_Website__c='http://testwebsite.com';
                oppty.End_Customer_Street_Address__c='test';
                oppty.End_Customer_City__c='test';
                oppty.End_Customer_State__c='test';
                oppty.End_Customer_Zip_Code__c='560030';
                oppty.Partner_Involved__c = acc.Id;

                listOfOpportunities.add(oppty);
            }
            //get the last oppty added as current oppty
            Opportunity oppty = listOfOpportunities[numberOfOpportunities - 1];
            system.runAs(partner)
            {
                insert listOfOpportunities;
            }

            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRM_search_account_controller fpc = new PRM_search_account_controller();
                pageRef.getParameters().put('pid', acc.id);
                fpc.CreateMode();
                fpc.CreateAcc();
            }
            oppty = refreshOpportunity(oppty.id);

            /*System.assertEquals(oppty.Deal_Reg_Account_Status__c, 'New Account');
            System.assertEquals(oppty.Deal_Reg_Account_Discount__c, 5.0);

            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRMSearchOpportunity;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                tempController.createNew();
            }
            oppty = refreshOpportunity(oppty.id);
            /*System.assertEquals(oppty.Deal_Reg_Opportunity_Status__c, 'New Opportunity');
            System.assertEquals(oppty.Deal_Reg_Opportunity_Discount__c, 0.0);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(oppty.id);
            
            // Submit the approval request for the account 
        
            Approval.ProcessResult result = Approval.process(req1);
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(oppty.Id),'approveXPercent',False);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            // Use the ID from the newly created item to specify the item to be worked 
        
            req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            
            oppty = refreshOpportunity(oppty.id);
            
            // Verify the results         
            //System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());        
            //System.assertEquals(oppty.Rebate__c, '5');*/
            Test.stopTest();
        }

   }

   static testMethod void testNewAccountExistingOppty() 
   {
        System.runAs(dmlUser) {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            Account acc = utilTestClass.CreateAccount('__ TEST account PRM7');
            acc.Website='www.seaoppr.com';
            insert acc;

            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            
            //SFDC-2572
            User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'));
            insert opptySCMOwnerUser;
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('Test__Rule', opptySCMOwnerUser.Id, 'Sales Operations');
            insert rule;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
               
            List<Opportunity> listOfOpportunities = new List<Opportunity>();
            Integer numberOfOpportunities = 2;
            for(integer i=0; i<numberOfOpportunities;i++)
            {
                Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty'+i,'1-Create');
                oppty.CloseDate= Date.today();
                oppty.End_Customer_Country__c='India';
                oppty.Customer_Company_Name__c='__TEST acc PRM';
                oppty.End_Customer_Website__c='http://testwebsite.com';
                oppty.End_Customer_Street_Address__c='test';
                oppty.End_Customer_City__c='test';
                oppty.End_Customer_State__c='test';
                oppty.End_Customer_Zip_Code__c='560030';
                oppty.Partner_Involved__c = acc.Id;

                listOfOpportunities.add(oppty);
            }
            //get the last oppty added as current oppty
            Opportunity oppty = listOfOpportunities[numberOfOpportunities - 1];
            system.runAs(partner)
            {
                insert listOfOpportunities;
            }

            Test.startTest();
            OpportunityShare oppsh = null;
            for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:oppty.id and UserOrGroupId=:opptySCMOwnerUser.id])
                oppsh=oppshare;
            if(oppsh!=null)
                oppsh.OpportunityAccessLevel='Edit';
            if(oppsh!=null)
                    update oppsh;  
            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRM_Search_Account;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRM_search_account_controller fpc = new PRM_search_account_controller();
                pageRef.getParameters().put('pid', acc.id);
                fpc.CreateMode();
                fpc.CreateAcc();
            }
            oppty = refreshOpportunity(oppty.id);

            /*System.assertEquals(oppty.Deal_Reg_Account_Status__c, 'New Account');
            //System.assertEquals(oppty.Deal_Reg_Account_Discount__c, 5.0);

            system.runAs(opptySCMOwnerUser)
            {
                PageReference pageRef = Page.PRMSearchOpportunity;
                pageRef.getParameters().put('opptyid', oppty.id);
                Test.setCurrentPageReference(pageRef);
                PRMSearchOpportunityController tempController= new PRMSearchOpportunityController();
                pageRef.getParameters().put('pid', listOfOpportunities[numberOfOpportunities -2].id);
                tempController.addOppty();
            }
            oppty = refreshOpportunity(oppty.id);
            
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(oppty.id);
            
            // Submit the approval request for the account 
        
            Approval.ProcessResult result = Approval.process(req1);
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(oppty.Id),'approveXPercent',False);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            
            // Use the ID from the newly created item to specify the item to be worked 
        
            req2.setWorkitemId(newWorkItemIds.get(0));
            
            // Submit the request for approval 
        
            Approval.ProcessResult result2 =  Approval.process(req2);
            
            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            
            oppty = refreshOpportunity(oppty.id);
            
            // Verify the results         
            //System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());        
            */
            Test.stopTest();
        }

   }


}