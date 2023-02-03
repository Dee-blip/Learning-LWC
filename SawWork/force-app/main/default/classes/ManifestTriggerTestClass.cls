@isTest(seeAllData=false)
public class ManifestTriggerTestClass {
    private static User devUser=null;
    // private static final List<String> REMINDER_OFFSET = GsmUtilClass.GetCustomSettingValue('Release', 'ReminderOffSet_day:hh:mm').split(':');
 
    private static id initDevUser() {
		User dmlUser = new User(id = UserInfo.getUserId());
 		if (devUser==null)
 		{
			devUser = utilTestClass.CreateUser('RELEUSER', 'Worldwide', 'Engineering');
			System.runAs(dmlUser)
			{
				insert devUser;
			}
 		}
        return dmlUser.id;
    }
    
    private static Release__c createRelease() {
        Release__c rel = new Release__c();
		rel.Active__c = true;
		rel.Business_Owner_Approver__c = devUser.Id;
		rel.Manager__c = devUser.Id;
		rel.SQA_Approver__c = devUser.id;
		rel.Technical_Approver__c = devUser.id;
		rel.SOX_Approval_URL__c = 'www.blah.blah';
		rel.Name = 'ese-force-dummy';
		rel.QA_Release_Date__c = Date.today();
		rel.Release_Date__c = Date.today().addDays(10);
        rel.IT_Function__c = 'Corporate Systems';
        return rel;
    }
    
    private static Manifest_Custom__c setup() {
        Id salesforceId =initDevUser();  
        
        DeploymentStepTestUtilClass.createGSMCustSettData('Release#ReminderOffSet_day:hh:mm','-3:13:30');
        DeploymentStepTestUtilClass.createGSMCustSettData('CRM_Integration', salesforceId); //second parameter takes salesforce Id as value , Since Hard Coaded Salesforce Id should be avoided , Using the userId

        Release__c rel = createRelease();
        insert rel;
        
		Deployment_Step__c ds = new Deployment_Step__c();
		ds.CR_Number__c = '1234';
        ds.Name = 'Test DS';
        ds.Release__c = rel.id; 
        ds.Sandbox__c = 'reldev';
        ds.Team__c = 'Proteus';
        insert ds;
        
        Manifest_Custom__c manifest = new Manifest_Custom__c();
        manifest.Component_Type__c = 'CustomField';
        manifest.Component_Name__c = 'something';
        manifest.Object_or_Folder_Name__c = 'some other thing';
        manifest.Deployment_Step__c = ds.id;
        manifest.Deployed_To__c = '<int><qa>';
        insert manifest;
        
        Deployment_Step__c dsToBeUpdated = [select id, QA_Deployed__c, Submit__c, QA_Verified__c, Approved_for_Prod__c from Deployment_Step__c where id = :ds.id][0];
		dsToBeUpdated.QA_Deployed__c = true;
        dsToBeUpdated.Submit__c = true;
        dsToBeUpdated.QA_Verified__c = true;
        update dsToBeUpdated;
        dsToBeUpdated.Approved_for_Prod__c = true;
        update dsToBeUpdated;
        return manifest;
    }
    
    static testMethod void cannotModifyCompTypeOnceApprovedForProd() {
        Manifest_Custom__c manifest = setup();
        Manifest_Custom__c manifestToBeUpdated = [select id from Manifest_Custom__c where id = :manifest.Id][0];
        manifestToBeUpdated.Component_Type__c = 'ApexClass';
        try {
            update manifestToBeUpdated;
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Component details cannot be changed once DS is Approved for Prod'));
        }
    }
    
    static testMethod void cannotModifyCompNameOnceApprovedForProd() {
        Manifest_Custom__c manifest = setup();
        Manifest_Custom__c manifestToBeUpdated = [select id from Manifest_Custom__c where id = :manifest.Id][0];
        manifestToBeUpdated.Component_Name__c = 'blah';
        try {
            update manifestToBeUpdated;
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Component details cannot be changed once DS is Approved for Prod'));
        }
    }
    
    static testMethod void cannotModifyObjNameOnceApprovedForProd() {
        Manifest_Custom__c manifest = setup();
        Manifest_Custom__c manifestToBeUpdated = [select id from Manifest_Custom__c where id = :manifest.Id][0];
        manifestToBeUpdated.Object_or_Folder_Name__c = 'blah';
        try {
            update manifestToBeUpdated;
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Component details cannot be changed once DS is Approved for Prod'));
        }
    }
}