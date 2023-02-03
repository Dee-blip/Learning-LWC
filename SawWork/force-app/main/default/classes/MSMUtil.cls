global class MSMUtil{

    // function to create a new Deployment Step Request or Update existing one : called from pop-up on DS
    WebService static String submitRequest( String comments, String environment, Id recordId, boolean mailRequired)
    {
        String returnMessage = '';
        if( environment == null || environment == '')
        {
            environment = 'CRMQA';
        }
        if(recordID != null) 
        {
            Try
            {

                ID dsID = recordID;
                boolean recpresent = false;
                for( Deployment_Step_Request__c dsrExist : [Select Id, devComments__c, submissionTime__c, status__c, isMailRequired__c from Deployment_Step_Request__c where Deployment_Step__c=:dsID  AND status__c = 'New' LIMIT 1]) 
                {
                    dsrExist.submissionTime__c=DateTime.now();
                    dsrExist.devComments__c = comments;
                    dsrExist.status__c = 'New';
                    dsrExist.isMailRequired__c = mailRequired;
                    dsrExist.requestedBy__c = userinfo.getuserid();
                    update dsrExist;
                    recpresent = true;
                } 
                if(!recpresent)
                {
                    Deployment_Step_Request__c dsr = new Deployment_Step_Request__c();
                    dsr.Deployment_Step__c = dsID;
                    dsr.devComments__c = comments;
                    dsr.environment__c = environment;
                    dsr.submissionTime__c = DateTime.now();
                    dsr.status__c = 'New';
                    dsr.requestedBy__c = userinfo.getuserid();
                    dsr.isMailRequired__c = mailRequired;
                    insert dsr;
                }
                returnMessage = 'SUCCESS : Request has been sent, Please visit All Tabs -> MSM to view status';
            }
            Catch(Exception ex)
            {
                returnMessage = 'ERROR: An internal error occurred';
            }
        }
        else
        {
            returnMessage = 'ERROR: No Deployment step ID specified';
        }
        return returnMessage;
    }


    // function returns the previos values and settings for pop-up if any : called from pop-up on DS 
    WebService static String getPrevValues(Id recordId) {
        List<Deployment_Step_Request__c> localDsr = [Select Id, isMailRequired__c, devComments__c from Deployment_Step_Request__c where Deployment_Step__c=:recordId ORDER BY submissionTime__c DESC LIMIT 1];
        String organized = JSON.serialize(localDsr);
        return organized;
    }

    // function returns true if the release field on Deployment Step matches with current release else return false : called from pop-up on DS
    WebService static Boolean checkRelease(Id release) 
    {

          for( Release__c rel  :  [ SELECT Id, Name, Release_Date__c FROM Release__c 
                                                    WHERE 
                                                    (Application__c = 'Salesforce' AND Release_Date__c > TODAY) 
                                                    OR  Name = 'ese-force-Maintenance'
                                                    ])
          {
            if(rel.Id == release)
            {
                return true;
            }
          }
        return false;
    }

    public static void updateDeployedDSFields(List<Deployment_Step_Request__c> newDSRList, Map<Id,Deployment_Step_Request__c> oldDSRMap)
    {

        List<Deployment_Step__c> dSListToUpdate = new List<Deployment_Step__c>();
        for(Deployment_Step_Request__c dsr : newDSRList)
        {
            if( oldDSRMap.get(dsr.Id) != null && 
                dsr.status__c != oldDSRMap.get(dsr.Id).status__c)
            {
                String newComments = dsr.DS_Ops_Deployed_Comments__c +' \n' + dsr.opsComments__c;
                if(newComments.length() > 255)
                {
                    newComments = dsr.opsComments__c;
                    if(newComments == null)
                    {
                        newComments = 'None';
                    }
                    else if(newComments.length() > 255)
                    {
                        newComments = newComments.substring(0,254);
                    }
                }
                if(dsr.status__c  == 'Completed')
                {

                    Deployment_Step__c ds = [select id,Number_of_QA_Deployed_manifests__c,Number_of_manifests__c,QA_Deployed__c from Deployment_Step__c where ID=:dsr.Deployment_Step__c];
                    
                    ds.QA_Deployed_Ops_Comments__c = newComments;
                    if(ds.QA_Deployed__c == false && (ds.Number_of_manifests__c == 0 || ds.Number_of_manifests__c == null))
                    {
                        ds.QA_Deployed_By__c = dsr.Assigned_to_name__c;
                        ds.QA_Deployed_Date__c = dsr.completionTime__c;
                        ds.QA_Deployed__c = true;
                    }
                    dSListToUpdate.add(ds);
                }
                else if(dsr.status__c  == 'Failed')
                {
                    Deployment_Step__c ds = new Deployment_Step__c(ID=dsr.Deployment_Step__c);
                    ds.QA_Deployed_Ops_Comments__c = newComments;
                    dSListToUpdate.add(ds);
                }
            }

        }

        if(dSListToUpdate.size()>0)
        {
            update dSListToUpdate;
        }


    }

    public static void populateInstanceURL(List<Deployment_Step_Request__c> newDSRList)
    {
        for( Deployment_Step_Request__c dsr : newDSRList )
        {
            dsr.Instance_URL__c = URL.getSalesforceBaseUrl().toExternalForm();
        }
    }
}