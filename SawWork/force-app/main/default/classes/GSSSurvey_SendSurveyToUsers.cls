/**
 * Created by kusharma on 25/04/17.
 * 
 * CR: FF Upgrade 19.1
 * Developer: Sandeep Naga 
 * Changes: Merging custom metadata from Financial_Force_Custom_Metadata__mdt to PSA_Common_Setting__mdt
 * Date: 28th Novemeber 2018
 * 
 */
//Adding line to Prod push
 

public with sharing class GSSSurvey_SendSurveyToUsers {
    List<String> lProductList = new List<String>();
    List<String> lEligibleCloseCodes = new List<String>();
    Set<String> sATMRole = new Set<String>();
    Map<String,List<pse__Proj__c>> mAccountAndLProjectDetails = new Map<String, List<pse__Proj__c>>();
    Map<String,String> mProjectAndSecurityProductName = new Map<String, String>();
    Integer reminderMailFrequency;

    public GSSSurvey_SendSurveyToUsers(){
        /*List<Financial_Force_Custom_Metadata__mdt> lFFCustomMetadata = [SELECT Value__c,Label,DeveloperName FROM PSA_Common_Setting__mdt
        WHERE DeveloperName IN ('IAT_ATM_Roles','IAT_Close_Codes','IAT_Security_Product_List', 'IAT_Reminder_Mail_Frequency') and type__c='Financial_Force_Custom_Metadata__mdt'];*/

        //Changes made by Sandeep Naga for merging custom metadata
        List<PSA_Common_Setting__mdt> lFFCustomMetadata = [SELECT Value__c,Label,DeveloperName FROM PSA_Common_Setting__mdt
        WHERE DeveloperName IN ('IAT_ATM_Roles','IAT_Close_Codes','IAT_Security_Product_List', 'IAT_Reminder_Mail_Frequency') and type__c='Financial_Force_Custom_Metadata__mdt'];
        
        //for (Financial_Force_Custom_Metadata__mdt varFFCustomMetadata : lFFCustomMetadata) {
        for (PSA_Common_Setting__mdt varFFCustomMetadata : lFFCustomMetadata) {
            if (varFFCustomMetadata.DeveloperName == 'IAT_ATM_Roles') {
                for (String varATMRoles : varFFCustomMetadata.Value__c.split(',')) {
                    sATMRole.add(varATMRoles.trim());
                }
            }
            if (varFFCustomMetadata.DeveloperName == 'IAT_Close_Codes') {
                for (String varCloseCode : varFFCustomMetadata.Value__c.split(',')) {
                    lEligibleCloseCodes.add(varCloseCode.trim());
                }
            }
            if (varFFCustomMetadata.DeveloperName == 'IAT_Security_Product_List') {
                for (String varSecurityProductList : varFFCustomMetadata.Value__c.split(',')) {
                    lProductList.add(varSecurityProductList.trim());
                }
            }
            if (varFFCustomMetadata.DeveloperName == 'IAT_Reminder_Mail_Frequency') {
                reminderMailFrequency = Integer.valueOf(varFFCustomMetadata.Value__c.trim());
            }
        }

    }

    public void sendSurveyToATMs(){
        Map<String,List<String>> mProjectAccount = getClosedProjects();
        Map<String, List<AccountTeamMember>> mAccountAndATMs = getATMsForAccount(mProjectAccount);
        List<GSSSurvey_Survey_Form__c> lSurveysInserted = createSurveyForATMs(mProjectAccount,mAccountAndATMs);
    }

    private List<GSSSurvey_Survey_Form__c> createSurveyForATMs (Map<String,List<String>> mProjectAccount, Map<String, List<AccountTeamMember>> mAccountAndATMs){
        System.debug('### mProjectAccount ' + mProjectAccount + ' $$$$ mAccountAndATMs' + mAccountAndATMs);
        List<GSSSurvey_Survey_Form__c> lSurveysToInsert = new List<GSSSurvey_Survey_Form__c>();
        for (String varAccId : mAccountAndATMs.keySet()) {
            for (AccountTeamMember varATMForSurvey : mAccountAndATMs.get(varAccId)) {
                for (pse__Proj__c varClosedProject : mAccountAndLProjectDetails.get(varAccId)) {
                    GSSSurvey_Survey_Form__c varGSSSurveySurveyForm = new GSSSurvey_Survey_Form__c();
                    varGSSSurveySurveyForm.Account__c = varAccId;
                    varGSSSurveySurveyForm.Project__c = varClosedProject.Id;
                    varGSSSurveySurveyForm.User__c = varATMForSurvey.UserId;
                    varGSSSurveySurveyForm.Security_Product_Name__c = mProjectAndSecurityProductName.get(varClosedProject.Id);
                    varGSSSurveySurveyForm.Reminder_Date__c = System.now().addDays(reminderMailFrequency);
                    varGSSSurveySurveyForm.Send_Creation_Email__c = true;
                    lSurveysToInsert.add(varGSSSurveySurveyForm);
                }
            }
        }

        insert lSurveysToInsert;
        return lSurveysToInsert;
    }

    private Map<String,List<String>> getClosedProjects(){
        Map<String,List<String>> mProjectAccount = new Map<String,List<String>>();
        List<pse__Proj__c> lSecurityProjectsClosedInLast24Hrs = [SELECT Id, Name, pse__Account__c, Project_Closed_Date__c, Survey_Request_Status__c,
        (SELECT Id,Product__c FROM pse__Project_Methodologies__r WHERE Product__c IN :lProductList)
        FROM pse__Proj__c
        WHERE pse__Stage__c = 'Closed'
        AND pse__Project_Type__c = 'New Implementation'
        AND Close_Code__c IN : lEligibleCloseCodes
        AND Project_Closed_Date__c = LAST_N_DAYS:2];
        List<pse__Proj__c> lProjectsToUpdate = new List<pse__Proj__c>();

        for (pse__Proj__c varClosedProject :lSecurityProjectsClosedInLast24Hrs) {

            if (varClosedProject.Survey_Request_Status__c != 'Survey Request Sent'
                    && varClosedProject.Survey_Request_Status__c != 'No Security Product') {
                if(!varClosedProject.pse__Project_Methodologies__r.isEmpty()){
                    for (pse__Project_Methodology__c varProduct : varClosedProject.pse__Project_Methodologies__r) {
                        mProjectAndSecurityProductName.put(varClosedProject.Id, varProduct.Product__c);
                    }
                    if(! mAccountAndLProjectDetails.containsKey(varClosedProject.pse__Account__c)){
                        mAccountAndLProjectDetails.put(varClosedProject.pse__Account__c, new List<pse__Proj__c>());
                    }
                    mAccountAndLProjectDetails.get(varClosedProject.pse__Account__c).add(varClosedProject);
                    //mAccountAndProjectDetails.put(varClosedProject.pse__Account__c, varClosedProject);
                    if(! mProjectAccount.containsKey(varClosedProject.Id)){
                        mProjectAccount.put(varClosedProject.Id, new List<String>());
                    }
                    varClosedProject.Survey_Request_Status__c = 'Survey Request Sent';
                    mProjectAccount.get(varClosedProject.Id).add(varClosedProject.pse__Account__c);
                }
                else{
                    varClosedProject.Survey_Request_Status__c = 'No Security Product';
                }
                lProjectsToUpdate.add(varClosedProject);
            }

        }

        update lProjectsToUpdate;

        return mProjectAccount;
    }

    private void getProjectsWithSecurityProject(){
        Set<pse__Proj__c> sProjectsWithSecurityProduct = new Set<pse__Proj__c>();

    }

    private Map<String, List<AccountTeamMember>> getATMsForAccount(Map<String,List<String>> mProjectAccount){
        Map<String, List<AccountTeamMember>> mAccountAndATMs = new Map<String, List<AccountTeamMember>>();
        List<String> lAccountId = new List<String>();
        for (String varProjectId : mProjectAccount.keySet()) {
            lAccountId.addAll(mProjectAccount.get(varProjectId));
        }

        for (AccountTeamMember varATM : [SELECT Id, UserId, User.Name, AccountId,TeamMemberRole FROM AccountTeamMember WHERE AccountId IN :lAccountId]) {
            if (sATMRole.contains(varATM.TeamMemberRole)) {
                if (! mAccountAndATMs.containsKey(varATM.AccountId)) {
                    mAccountAndATMs.put(varATM.AccountId, new List<AccountTeamMember>());
                }
                mAccountAndATMs.get(varATM.AccountId).add(varATM);
            }
        }

        return mAccountAndATMs;
    }
}