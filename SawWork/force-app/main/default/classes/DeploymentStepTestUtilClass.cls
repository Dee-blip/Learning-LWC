public class DeploymentStepTestUtilClass {
    public static User devUser=null;

    public static void initDevUser() {
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

    public static GSM_Custom_Settings__c createGSMCustSettData(String Name, String Value) {
        GSM_Custom_Settings__c data = new GSM_Custom_Settings__c();
        data.Name = Name;
        data.Value__c = Value;
        insert data;
        return data;
    }
    
    public static Release__c createRelease() {
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
        insert rel;
        return rel;
    }

    public static Deployment_Step__c createDS(String name, String release) {
        Deployment_Step__c ds = new Deployment_Step__c();
		ds.CR_Number__c = '1234';
        ds.Name = name;
        ds.Release__c = release; 
        ds.Sandbox__c = 'reldev';
        ds.Team__c = 'Proteus';
        ds.QA_Deployed__c = false;
        ds.Submit__c = false;
        ds.QA_Verified__c = false;
        insert ds;
        return ds;
    }

    public static Deployment_Step_Request__c createDSRequest(String name, String dsID, String status){
        Deployment_Step_Request__c dsReq = new Deployment_Step_Request__c();
        dsReq.Name = name;
        dsReq.Deployment_Step__c = dsID;
        dsReq.status__c = status;
        dsReq.isMailRequired__c = false;
        dsReq.submissionTime__c = DateTime.now();

        insert dsReq;
        return dsReq;
    }
}