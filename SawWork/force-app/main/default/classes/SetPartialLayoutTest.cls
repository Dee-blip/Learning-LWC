@isTest (seeAllData=true)
public class SetPartialLayoutTest {
    
    private static User devUser=null;
    private static final List<String> REMINDER_OFFSET = GsmUtilClass.GetCustomSettingValue('Release', 'ReminderOffSet_day:hh:mm').split(':');

    
    private static void initDevUser() {
		User dmlUser = new User(id = UserInfo.getUserId());
 		if (devUser==null)
 		{
			devUser = utilTestClass.CreateUser('RELEUSER', 'Worldwide', 'Engineering');
			System.runAs(dmlUser)
			{
				insert devUser;
			}
 		}
    }
    
    private static Release__c createRelease() {
        Release__c rel = new Release__c();
		rel.Active__c = true;
		rel.Business_Owner_Approver__c = devUser.Id;
		rel.Manager__c = devUser.Id;
		rel.SQA_Approver__c = devUser.id;
		rel.Technical_Approver__c = devUser.id;
		rel.SOX_Approval_URL__c = 'www.blah.blah';
		rel.Name = 'citadel-test';
		rel.QA_Release_Date__c = Date.today();
		rel.Release_Date__c = Date.today().addDays(10);
         rel.IT_Function__c = 'Corporate Systems';
        return rel;
    }
    
    
    Static testmethod void testCaseInsert() {
        initDevUser();   
        Release__c rel = createRelease();
        insert rel;
  
        Deployment_Step__c ds = new Deployment_Step__c();
		ds.CR_Number__c = '1234';
        ds.Name = 'TestPageTrigger';
        ds.Release__c = rel.id; 
        ds.Sandbox__c = 'reldev';
        ds.Team__c = 'Proteus';
        ds.QA_Deployed__c = false;
        ds.Submit__c = true;
        insert ds;
        
        Manifest_Custom__c manifest = new Manifest_Custom__c();
        manifest.Component_Type__c = 'Layout';
        manifest.Component_Name__c = 'something';
        manifest.Object_or_Folder_Name__c = 'some other thing';
        manifest.Deployment_Step__c = ds.id;
        manifest.Only_Partial_Layout__c=false;
        insert manifest;
        
        PageLayoutChangeRequest__c plr = new PageLayoutChangeRequest__c();
        plr.LayoutName__c='Lead Layout';
        plr.ManifestCustom__c = manifest.Id;
        plr.Invalid__c=false;
        
        insert plr;
        
        Manifest_Custom__c updated_manifest = [
       	SELECT Id, Only_Partial_Layout__c
       	FROM Manifest_Custom__c
       	WHERE id = :manifest.Id][0];
   
        // Verification
   	    //System.assertNotEquals(manifest.Only_Partial_Layout__c, updated_manifest.Only_Partial_Layout__c);
  	         
    }
    
  Static testmethod void testCaseUpdate() {
        initDevUser();   
        Release__c rel = createRelease();
        insert rel;
  
        Deployment_Step__c ds = new Deployment_Step__c();
		ds.CR_Number__c = '1234';
        ds.Name = 'TestPageTrigger';
        ds.Release__c = rel.id; 
        ds.Sandbox__c = 'reldev';
        ds.Team__c = 'Proteus';
        ds.QA_Deployed__c = false;
        ds.Submit__c = true;
        insert ds;
        
        Manifest_Custom__c manifest = new Manifest_Custom__c();
        manifest.Component_Type__c = 'Layout';
        manifest.Component_Name__c = 'something';
        manifest.Object_or_Folder_Name__c = 'some other thing';
        manifest.Deployment_Step__c = ds.id;
        insert manifest;
        
        PageLayoutChangeRequest__c plr = new PageLayoutChangeRequest__c();
        plr.LayoutName__c='Lead Layout';
        plr.ManifestCustom__c = manifest.Id;
        plr.Invalid__c=false;
        
        insert plr;
      
        Manifest_Custom__c updated_manifest_after_insert = [
       	SELECT Id, Only_Partial_Layout__c
       	FROM Manifest_Custom__c
       	WHERE id = :manifest.Id][0];
      
        PageLayoutChangeRequest__c plrsToBeUpdated = [select id from PageLayoutChangeRequest__c where id = :plr.id][0];
        plrsToBeUpdated.Invalid__c=true;
      
         update plrsToBeUpdated;
      
        Manifest_Custom__c updated_manifest_after_update = [
       	SELECT Id, Only_Partial_Layout__c
       	FROM Manifest_Custom__c
       	WHERE id = :manifest.Id][0];
   
        // Verification
   	    //System.assertNotEquals(updated_manifest_after_insert.Only_Partial_Layout__c, updated_manifest_after_update.Only_Partial_Layout__c);
               
    }
    
    

}