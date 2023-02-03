@isTest(seeAllData=false)
public class L2Q_WaiverEmailGeneratorTest {

        static testmethod void L2Q_WaiverEmailGeneratorController()
        {
                Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
                User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
                u.isActive=true;
                insert u;

                Account acc = utilTestClass.CreateAccount('__Test Account');
                acc.OwnerId =u.Id;
                insert acc;

                AccountTeamMember atmn = new AccountTeamMember();
                atmn.AccountId = acc.Id;
                atmn.UserId  = u.Id;
                atmn.TeamMemberRole = 'CMG - Analyst';
                insert atmn;
                List<Account> AccountIds=new List<Account>();
                AccountIds.add(acc);
                AccountTeamMember atm=[Select AccountId, UserId, User.isActive from AccountTeamMember where AccountId IN :AccountIds and TeamMemberRole='CMG - Analyst'];

                Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
                oppty.AccountId =acc.Id;
                oppty.OwnerId = u.Id;
                oppty.CloseDate = Date.today().addMonths(4);
                insert oppty;

                Order_Approval__c order=new Order_Approval__c();
                order.Associated_Opportunity__c=oppty.id;
                insert order;
            
                Test.startTest();
                Document document;
                document = new Document();
                document.Body = Blob.valueOf('Some Text-new');
                document.ContentType = 'image/png';
                document.DeveloperName = 'Gsm_Workflow_Waiver_Img_Temp';
                document.IsPublic = true;
                document.Name = 'Gsm_Workflow_Waiver_Img';
                document.FolderId = [select id from folder Where Name = 'Shared Documents' LIMIT 1].id;
                insert document;

                ApexPages.currentPage().getParameters().put('id',order.id);
                L2Q_WaiverEmailGenerator waiver=new L2Q_WaiverEmailGenerator();
                Component.Apex.OutputPanel op = waiver.getImageDetails();
                waiver.setRenderWaiverDocPage();
                PageReference pr = waiver.refreshCurrentPage();
                Test.stopTest();
        }

}