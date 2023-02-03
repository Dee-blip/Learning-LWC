/*
* File Name: HD_Self_Service_Redifect_Controller
* Description : Controller which determines the URL to be redirected to based on the logged in user and the custom settings
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Mar 23rd, 2022     Aneesh Budnar        PRTORES-2483 - HD Lightning UI page redirect for controlling the SelfService URL for aloha
*/
public without sharing class HD_Self_Service_Redifect_Controller {
    @AuraEnabled(cacheable = true)
    public static string getRedirectURL() {
        String redirectURL = '';
        List<HD_Self_Service_Redirect__mdt> redirectionSettings;
        try {
            Organization org = [SELECT IsSandbox FROM Organization LIMIT 1];
            String env = '';
            if((org.IsSandbox || Test.isRunningTest()) && !UserInfo.getUserName().endsWith('.com')) {
                List<String> splitNames = UserInfo.getUserName().split('\\.');
                env = splitNames[splitNames.size() - 1].toLowerCase();
            }
        
            redirectionSettings = [SELECT Id, Order__c, SOQL__c, Redirect_URL__c, Bypass_Rule__c, DynamicApexCall__c, Strict_Deny__c  
                                                                   FROM HD_Self_Service_Redirect__mdt 
                                                                   WHERE Environment__c = :env ORDER By Order__c];
            redirectURL = checkRecursively(new List<HD_Self_Service_Redirect__mdt>(redirectionSettings));
            if(String.isEmpty(redirectURL)) {
                redirectURL = redirectionSettings[redirectionSettings.size()  - 1].Redirect_URL__c;
            }
        }
        catch(Exception ex) {
            if(redirectionSettings.size() > 0) {
	            redirectURL = redirectionSettings[redirectionSettings.size()  - 1].Redirect_URL__c;
            }
            else {
                redirectURL = 'https://akamai--bmcservicedesk.na134.visual.force.com/apex/StdSelfServiceHome';
            }
        }
        return redirectURL;
    }
    
    private static String checkRecursively(List<HD_Self_Service_Redirect__mdt> redirectionSettings) {
        if(redirectionSettings == null || redirectionSettings.size() ==0) {
            return '';
        }
        else if(redirectionSettings[0].SOQL__c == 'Empty') {
            return redirectionSettings[0].Redirect_URL__c;
        }
        else {
            if(!redirectionSettings[0].Bypass_Rule__c) {
                List<SObject> records = Database.query(redirectionSettings[0].SOQL__c);
                String dynamicApexCall = redirectionSettings[0].DynamicApexCall__c;
                Callable extension = 
                    (Callable) Type.forName((dynamicApexCall.split('\\.'))[0]).newInstance();
                Boolean result = (Boolean) 
                    extension.call((dynamicApexCall.split('\\.'))[1], new Map<String, Object> { 
                        'records' => records
                            });
                if(result) {
                    return (redirectionSettings[0].Strict_Deny__c) ? redirectionSettings[redirectionSettings.size()  - 1].Redirect_URL__c :
                        redirectionSettings[0].Redirect_URL__c;
                }
            }
            redirectionSettings.remove(0);
            return checkRecursively(redirectionSettings);
        }
    }
}