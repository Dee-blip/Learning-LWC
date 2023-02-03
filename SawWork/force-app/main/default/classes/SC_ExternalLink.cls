public class SC_ExternalLink {
    
    private static String dynamicVariableStartHolder = 'replaceMergeStart';
    private static String dynamicVariableEndHolder = 'replaceMergeEnd'; 
    id recordId = null;
    public List<SC_External_Links__c> externalLinkList{get;set;}
    
    public SC_ExternalLink(){
        recordId = ApexPages.currentPage().getParameters().get('id');
        externalLinkList = new List<SC_External_Links__c>();
    }
     
    public void loadLinks(){
        externalLinkList = getExternalLinks();
    }
    
    private LIST<SC_External_Links__c> getExternalLinks(){
        String objectAPIName = recordId.getSObjectType().getDescribe().getName();
        LIST<SC_External_Links__c> linksList = [SELECT category__c,
                                                                has_merge_Fields__c,
                                                                URL__c,
                                                                URL_Name__c,
                                                                openURLInServiceCLoud__c 
                                                        FROM SC_External_Links__c
                                                       WHERE category__c = :objectAPIName];
        List<SC_External_Links__c> responseLinksList = new List<SC_External_Links__c>();
        List<String> dynamicFields = new List<String>();
        List<SC_External_Links__c> staticLinks = new LIst<SC_External_Links__c>();
        List<SC_External_Links__c> dynamicLinks = new LIst<SC_External_Links__c>();
        for(SC_External_Links__c c:linksList){
            if (c.has_merge_Fields__c){
                dynamicLinks.add(c);
                String temp = c.url__c;
                dynamicFields.addall(extractDynamicVaraibles(temp));
            }
            else {
                staticLinks.add(c);
            }
        }
        if (dynamicFields.size() == 0 || recordId == null){
            responseLinksList.addAll(staticLinks);
            return responseLinksList;
        }
        String dynamicQuery = String.join(dynamicFields, ',');
        String queryToExecute = 'Select '+ dynamicQuery + ' From ' + objectAPIName  + ' where Id = : recordId limit 1 ' ; 
        sObject sobjectMap = Database.query(queryToExecute);
        //looop through all fields. one field might be present in many other links. so replace in all links
        for(String s:dynamicFields){
            for(SC_External_Links__c c:dynamicLinks){
                c = transformURL(c,sObjectMap,s);
            }
        }
        responseLinksList.addAll(staticLinks);
        responseLinksList.addAll(dynamicLinks);
        return responseLinksList;
    }
    
    private SC_External_Links__c transformURL(SC_External_Links__c preModifiedURL,sobject sObjectMap,String stringToFindAndReplace){
        String temp = preModifiedURL.url__c;
        Matcher m = getRegexmatcher(temp);
        while(m.find()){
            preModifiedURL.url__c = preModifiedURL.url__c.replace(m.group(),String.valueOf(sobjectMap.get(stringToFindAndReplace)));
        }
        return preModifiedURL;
    } 
    
    private List<String> extractDynamicVaraibles(String url){
        List<String> resultList = new List<String>();
        Matcher m = getRegexmatcher(url);
        while(m.find()){
            resultList.add(m.group().replace(dynamicVariableStartHolder,'').replace(dynamicVariableEndHolder,''));
        }
        return resultList;
    }
    
    private Matcher getRegexmatcher(String regexURL){
        Pattern myPattern = Pattern.compile(dynamicVariableStartHolder + '(.*?)' + dynamicVariableEndHolder);
        Matcher m = myPattern.matcher(regexURL);
        return m;
    }
    
}