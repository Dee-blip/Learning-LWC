/*Created By: Vivek Baidya
* Created Date: 24-July-2020
* JIRA: SFDC-7116
* Description: This class picks one account plan document at a time and moves it to the Executive folder in Quip.
* Known drawback of '/1/admin/threads/add-members' api is that it can accept only one thread at a time.
*/

public class MoveAccountPlansToExecutiveFolder implements Queueable, Database.AllowsCallouts {
    
    // class variables
    public list<Account_Plan__c> allPlans;
    public integer index;
    public string moveDocumentToFolderAPI;
    
    public MoveAccountPlansToExecutiveFolder(){
        
        // fetch required custom metadata used in this class
        string gsmSettingDeveloperNames = 'Quip_AddDocumentToFolderAPI,Quip_ExecutiveFolderId';
        map<string,string> gsmSetting = GsmUtilClass.getKeyValueMetadata('GSM_Settings__mdt','Value__c',gsmSettingDeveloperNames,false);
        
        moveDocumentToFolderAPI = gsmSetting.get('Quip_AddDocumentToFolderAPI');
        
        // set executive folder id in the api
        moveDocumentToFolderAPI = moveDocumentToFolderAPI.replace('#member_ids#',gsmSetting.get('Quip_ExecutiveFolderId'));
        
        // get all the plans which are not yet moved to executive folder
        allPlans = [select Id,Quip_New_Document_URL__c,Moved_To_Executive_Folder__c from Account_Plan__c where Moved_To_Executive_Folder__c=false and Quip_New_Document_URL__c != null];
        index = 0;
    }
    
    // constructor used for setting the class variables while chaining the job
    public MoveAccountPlansToExecutiveFolder(integer index, list<Account_Plan__c> allPlans, string moveDocumentToFolderAPI){
        this.index = index;
        this.allPlans = allPlans;
        this.moveDocumentToFolderAPI = moveDocumentToFolderAPI;
    }
    
    public void execute(QueueableContext context){
        if(!allPlans.isEmpty()){
            try
            {
                QuipCalloutClass qc = new QuipCalloutClass();
                string documentUrl = allPlans[index].Quip_New_Document_URL__c;
                
                // get thread id from the account plan document url
                documentUrl = documentUrl.substring(documentUrl.lastIndexOf('/')+1,documentUrl.length());
                
                // set thread id in the api
                string postEndPoint = moveDocumentToFolderAPI.replace('#thread_id#',documentUrl);
                
                // do api callout
                integer statusCode = qc.getPostResult(postEndPoint,null);
                
                // if callout is successful, mark account plan as moved to folder, so it won't get picked in the next run
                if(statusCode == 200){
                    allPlans[index].Moved_To_Executive_Folder__c = true;
                    update allPlans[index];
                }
            }
            catch(Exception e){
                Sawyer.saw(e);
            }
            
            index++;
            
            // chaining the job to move the next account plan to executive folder
            if(index < allPlans.size()){
                System.enqueueJob(new MoveAccountPlansToExecutiveFolder(index,allPlans,moveDocumentToFolderAPI));
            }
        }
    }
}