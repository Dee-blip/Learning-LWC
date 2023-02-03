/*Created By: Vivek Baidya
* Created Date: 08-July-2020
* JIRA: SFDC-7019
* Description: Controller class to redirect any external links via salesforce from Quip.
*/
public without sharing class QuipWeblinkRedirectionController {
    public boolean isWrongUrl { get; set; }
    public PageReference init(){
        
        string recordId = ApexPages.currentPage().getParameters().get('recordId');
        string dashboard = ApexPages.currentPage().getParameters().get('dashboard');
        string currentUrl = ApexPages.currentPage().getUrl();
        List<Quip_Weblinks__mdt> quipWeblink = new List<Quip_Weblinks__mdt>();
        string url='',parameterFormat='',parameterFields='',objType='',queryStr='';
        
        // get the dashboard link with necessary details from metadata
        if(!String.isBlank(dashboard)){
            quipWeblink = [select Link__c,Object__c,Parameter_Fields__c,Parameter_Format__c from Quip_Weblinks__mdt where DeveloperName=:dashboard limit 1];
            if(!quipWeblink.isEmpty()){
                url = quipWeblink[0].Link__c;
                parameterFormat = quipWeblink[0].Parameter_Format__c;
                parameterFields = quipWeblink[0].Parameter_Fields__c;
                objType = quipWeblink[0].Object__c;
            }
        }
        
        PageReference pageRef;
        // for any contextual url
        if(!String.isBlank(parameterFields) && !String.isBlank(objType) && !String.isBlank(recordId) && !String.isBlank(url) && !String.isBlank(parameterFormat)){
            queryStr = 'select '+parameterFields+' from '+objType+' where id =: recordId';
            try{
                sObject ob = Database.query(queryStr);
                // iterating the parameter fields to get the field value and replace the fields with value in parameter format
                for(string str : parameterFields.split(',')){
                    str = str.trim();
                    string val = string.valueOf(ob.get(str));
                    val = EncodingUtil.urlEncode(val, 'UTF-8');
                    val = val.replace('%2C','%5C%2C');
                    str = '<'+str+'>';
                    parameterFormat = parameterFormat.replace(str,val);
                }
                // preparing actual url with paramaters to redirect
                pageRef = new PageReference(url + parameterFormat);
            }
            catch(Exception ex){
                isWrongUrl = true;
                return null;
            }
        }
        // for any generic url (non-contextual)
        else if(!String.isBlank(url)){
            pageRef = new PageReference(url);
        }
        else{
            isWrongUrl = true;
            return null;
        }
        
        pageRef.setRedirect(true);
        return pageRef;
    }
}