/**
Pramod Kamath   31-Dec-2013     Test clases for ausarel Enhancements 
 */
@isTest(SeeAllData=True) 
    private class AusarelTestClass {


        private static User devUser=null;

        /*static{
          utilTestClass.insertCustomSettings();
          }*/
        private static void init()
        {
            // create Dev User.
            if (devUser==null)
            {
                devUser = utilTestClass.CreateUser('SLUSRK', 'Worldwide', 'Engineering');
                insert devUser;
            }
        }



        public static Release__c spawnrelease(String pReleaseName, Date pProdReleaseDate, Date pQAReleaseDate, String pSoxApprovalURL)
        {
            Release__c rel = new Release__c();
            rel.Active__c = true;
            rel.Business_Owner_Approver__c = devUser.Id;
            rel.Manager__c = devUser.Id;
            rel.SQA_Approver__c = devUser.id;
            rel.Technical_Approver__c = devUser.id;
            rel.SOX_Approval_URL__c = pSoxApprovalURL;
            rel.Name = pReleaseName;
            rel.QA_Release_Date__c = pQAReleaseDate;
            rel.Release_Date__c = pProdReleaseDate;
            return rel;
        }


        static testMethod void depstepdelete() {     
            System.runAs(utilTestClass.getTestRunUser())
            {
                init();// Create Test User    

                Date qaReleaseDate = date.parse('03/04/2011');
                Date prodReleaseDate = date.parse('01/01/2013');

                Release__c myrel = spawnrelease('TestRelease', prodReleaseDate, qaReleaseDate, 'www.testrelease.com');
                insert myrel;

                Deployment_Step__c  mydepstep= new Deployment_Step__c();
                mydepstep.Name='TestDepStep';
                mydepstep.Release__c=myrel.id;
                mydepstep.CR_Number__c='555555';
                mydepstep.Sandbox__c='testSandbox';
                insert mydepstep;  


                try
                {
                    delete mydepstep;
                }

                catch(DmlException e)
                {                	
                    System.assert( e.getMessage().contains('Cannot Delete Deployment step'));                	
                }             
            }
        }




        static testMethod void Manifestdelete() {     
            System.runAs(utilTestClass.getTestRunUser())
            {
                init();// Create Test User    

                Date qaReleaseDate = date.parse('03/04/2011');
                Date prodReleaseDate = date.parse('01/01/2013');

                Release__c myrel = spawnrelease('TestRelease', prodReleaseDate, qaReleaseDate, 'www.testrelease.com');
                insert myrel;

                Deployment_Step__c  mydepstep= new Deployment_Step__c();
                mydepstep.Name='TestDepStep';
                mydepstep.Release__c=myrel.id;
                mydepstep.CR_Number__c='555555';
                mydepstep.Sandbox__c='testSandbox';
                insert mydepstep;  


                Manifest_Custom__c mymanifest= new Manifest_Custom__c();
                mymanifest.Deployment_Step__c=mydepstep.id;
                mymanifest.Object_or_Folder_Name__c='mytestobject__c';
                mymanifest.Component_Name__c='abcd';
                mymanifest.Component_Type__c='ApexClass';
                insert mymanifest;

                try
                {
                    delete mymanifest;
                }

                catch(DmlException e)
                {

                    System.assert( e.getMessage().contains('Cannot Delete Manifest Object'));

                }

            }

        }






    }