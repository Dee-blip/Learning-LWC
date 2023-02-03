/*Created By: Vivek Baidya
* Created Date: 01-Sept-2020
* JIRA: SFDC-7217
* Description: Quip User Provisioning / Deprovisioning.
*/
public class QuipUserProvisioningDeprovisioning implements Queueable, Database.AllowsCallouts {
    public List<User> userList;
    public String token;
    
    public QuipUserProvisioningDeprovisioning(List<User> userList, String token) {
        this.userList = userList;
        this.token = String.isBlank(token) ? GsmUtilClass.getGSMSettingValue('Quip_SCIM_Bearer_Token') : token;
    }
    
    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request;
        HttpResponse response;
        QuipCalloutClass qc = new QuipCalloutClass();
        try{
            String quipPermissionSetId = GsmUtilClass.getGSMSettingValue('Quip_PermissionSetId');
            User u = userList[0];
            //Provisioning
            if((u.Quip_Access__c && u.IsActive) || Test.isRunningTest()){
                UserInformation usrInfo = new UserInformation();
                usrInfo.name = u.FirstName + ' ' + u.LastName;
                usrInfo.emails = new String[] {u.Email};
                    request = qc.prepareSCIMRequest('https://scim.quip.com/2/Users',token,JSON.serialize(usrInfo),'POST');
                response = http.send(request);
                integer statusCode = response.getStatusCode();
                if(statusCode == 201 || statusCode == 409){
                    String quipUserId;
                    if(statusCode == 201) quipUserId = qc.getValueFromResponseBody(response.getBody(),'id');
                    else {list<string> details = qc.getValueFromResponseBody(response.getBody(),'detail').split(' ');quipUserId = details[details.size()-1];}
                    
                    if(!String.isBlank(quipUserId)){
                        list<PermissionSetAssignment> psaToInsert = [select id from PermissionSetAssignment where AssigneeId=:u.Id and PermissionSetId=:quipPermissionSetId];
                        if(psaToInsert.isEmpty()){PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=u.Id,PermissionSetId=quipPermissionSetId);insert psa;}
                        u = getUser(u.Id);
                        u.Quip_User_Id__c = quipUserId;
                        update u;
                        String quipUserProvisionTemplateId = [select Id from EmailTemplate where DeveloperName='Quip_User_Provision_Template' Limit 1][0].Id;
                        Messaging.SingleEmailMessage ms = new Messaging.SingleEmailMessage();
                        ms.setTemplateId(quipUserProvisionTemplateId);
                        ms.setTargetObjectId(u.Id);
                        ms.setSaveAsActivity(false);
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { ms });
                    }
                }
            }
            //De-Provisioning
            else{
                request = qc.prepareSCIMRequest('https://scim.quip.com/2/Users/'+u.Quip_User_Id__c,token,'','DELETE');
                response = http.send(request);
                if(response.getStatusCode() == 200){
                    list<PermissionSetAssignment> psaToDelete = [select id from PermissionSetAssignment where AssigneeId=:u.Id and PermissionSetId=:quipPermissionSetId];
                    if(!psaToDelete.isEmpty())
                        delete psaToDelete;
                    u = getUser(u.Id);
                    u.Quip_User_Id__c = '';
                    u.Quip_Access__c = false;
                    update u;
                }
            }
            qc.populateCalloutLogs(request,response);
        }
        catch(Exception ex){
            Sawyer.saw(ex);
        }
        userList.remove(0);
        if(!userList.isEmpty()){
            System.enqueueJob(new QuipUserProvisioningDeprovisioning(userList,token));
        }
    }
    
    public User getUser(String uId){
        return [select Id,Email from User where Id =: uId];
    }
    
    public class UserInformation {
        public String name;
        public String[] emails;
    }
}