public class MARIT_createBulkCTAController {
    
    public String personIds { get; private set; }
    public List<Map<string,string>> ctaDetails { get; private set; }
    
    public MARIT_createBulkCTAController() {
        this.personIds = Apexpages.currentPage().getParameters().get('Id');
    }
    
    public PageReference dmlOperation() {
        Set<String> personIds = new Set<String>();
        Map<Id, Id> leadTocampaignMap = new Map<Id, Id>();
        Map<Id, Id> contactTocampaignMap = new Map<Id, Id>();
        Map<Id, Id> convertedleadToContactMap = new Map<Id, Id>();
        Map<string,string> ctaMap;
        this.ctaDetails = new List<Map<string,string>>();
        Id campaignId = MarketingUtilClass.getMarketingSettingsValue('CTACreationTableauCampaign');
        if(Test.isRunningTest()) {
            campaignId = null;
        }
        if(this.personIds != null) {
        	personIds = new Set<String>(this.personIds.split(','));
        }
        List<lead> convertedLeads = [Select Id,ConvertedContactId from Lead where IsConverted = true and Id in :personIds];
        for(Lead l:convertedLeads) {
            convertedleadToContactMap.put(l.Id,l.ConvertedContactId);
        }
        for(String pid:personIds) {
            if(Id.valueOf(pid).getSObjectType().getDescribe().getName() == 'Lead') {
                if(convertedleadToContactMap.get(pid) != null) {
                    contactTocampaignMap.put(convertedleadToContactMap.get(pid),campaignId);
                } else {
                    leadTocampaignMap.put(pid,campaignId);
                }    
            } else if(Id.valueOf(pid).getSObjectType().getDescribe().getName() == 'Contact') {
                contactTocampaignMap.put(pid,campaignId);
            } else {
                ctaMap = new Map<string,string>();
                ctaMap.put('personId',pid);
                ctaMap.put('personName',pid);
                ctaMap.put('ctaurlDisplay','0');
                ctaMap.put('ctaError','Not a valid person Id');
                this.ctaDetails.add(ctaMap);
            }
        }
        if((contactTocampaignMap != null && !contactTocampaignMap.isEmpty()) || (leadTocampaignMap != null && !leadTocampaignMap.isEmpty())) {
           Map<string,Map<SObject,string>> result = LeadUtilClass.createCTAforPerson(leadTocampaignMap,contactTocampaignMap,'Surging Dashboard','Web Security');
           Map<SObject,string> ctaCreated = result.get('success');
           String pid;
           if(ctaCreated != null) {
               for(SObject so:ctaCreated.keySet()) {
                   ctaMap = new Map<string,string>();
                   pid = so.get(Schema.Lead.Associated_Contact__c) != null ? (string) so.get(Schema.Lead.Associated_Contact__c):(string) so.get(Schema.Lead.Parent_Lead__c);
                   ctaMap.put('personId',pid);
                   ctaMap.put('personName',getName((string) so.get('FirstName'),(string) so.get('LastName')));
                   ctaMap.put('ctaId',so.Id);
                   ctaMap.put('ctaurlDisplay','1');
                   this.ctaDetails.add(ctaMap);
               }
           }    
            
           Map<SObject,string> ctaError = result.get('error');
           if(ctaError != null) {
               for(SObject so:ctaError.keySet()) {
                   ctaMap = new Map<string,string>();
                   if(so.getSObjectType() == Schema.Lead.getSObjectType() && so.isSet(Lead.parent_lead__c) && so.get('parent_lead__c') != null) {
                       pid = (string) so.get('parent_lead__c');
                   } else if(so.getSObjectType() == Schema.Lead.getSObjectType() && so.isSet(Lead.Associated_Contact__c) && so.get('Associated_Contact__c') != null) {
                       pid = (string) so.get('Associated_Contact__c');
                   } else {
                       pid = (string) so.get('id');
                   }
            	   ctaMap.put('personId',pid);
                   ctaMap.put('personName',getName((string) so.get('FirstName'), (string) so.get('LastName')));
                   ctaMap.put('ctaurlDisplay','0');
                   ctaMap.put('ctaError',ctaError.get(so));
                   this.ctaDetails.add(ctaMap);
               }
           }    
        }
        
        //If only one personId is passed and we can redirect to the cta page, but in case multiple ids are passed we need to display results in a table
        if(personIds.size() == 1 && this.ctaDetails.size() == 1 && this.ctaDetails[0].get('ctaurlDisplay') == '1') {
            PageReference page = new PageReference('/'+this.ctaDetails[0].get('ctaId'));
            return page;
        } else {
        	return null;
        }    
    }
    
    private String getName(String fname,String lname) {
        if(fname != null && lname != null ) {
            return fname + lname;
        } else if(fname == null && lname != null) {
            return lname;
        } else if(fname != null && lname == null) {
            return fname;
        } else {
            return '';
        }
    }
}