public without sharing class ConvertLeadToContactController {

    private Lead leadObj;
    public Boolean showMessage {get;set;}
    Boolean showAkamLeadMessage {get;set;}
    public static String wwwAccountId = GsmUtilClass.getGSMSettingValue('WWWLeadGenAccountIdMarketo');

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public ConvertLeadToContactController(ApexPages.StandardController stdController) {
        leadObj = (Lead)stdController.getRecord();
        showMessage=false;
        showAkamLeadMessage=false;
        System.debug(LoggingLevel.ERROR,'leadObj, l:'+leadObj);
        Id leadId=leadObj.id;
        leadObj = [select id,Associated_Account__c,RecordType.Name,(select id from Leads__r) from lead where id=:leadId ];
        if(leadObj.Associated_Account__c==null)
            showMessage=true;
        //System.debug(LoggingLevel.ERROR,'leadObj.Leads: '+leadObj.Leads__r);
        //if(leadObj.Leads__r.size()!=0)
        //    showAkamLeadMessage=true;
        if(showMessage){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Account should be associated with a lead before conversion'));
                //return null;
            }

        if(leadObj.Associated_Account__c == wwwAccountId) {
            showMessage=true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please associate a real account before converting the Lead to a Contact.'));
        }
        
        //if(showAkamLeadMessage){
        //        showMessage = true;
        //        System.debug(LoggingLevel.ERROR,'showMessage in if :: '+showMessage);
        //        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getGsmSettingValue('Annuitas_MarketoConvertContactAkam')));
        //        //return null;   
        //    }

        if(leadObj.RecordType.Name!='Marketo Lead'){
                showMessage = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can only convert a Person Lead'));
                //return null;   
            }
            System.debug(LoggingLevel.ERROR,'showMessage:: '+showMessage);
        //if(leadObj!=null)
        //    convertLead();
    }

    public PageReference convertLead(){
        //for(Lead l : leadList)

            //leadObj.status='Converted';
            //GsmUtilClass.doDatabaseUpdate(new List<Lead>{leadObj},'ConvertLeadToContactController','convertLead');
            ByPassAndLimitUtils.disable('LeadTrigger');
            //update leadObj;
                         Database.LeadConvert templc;
                         Database.LeadConvertResult lcr=null;
                         PageReference retURL = new PageReference('/'+leadObj.id);
                         Id ContactId;
                         List<Lead> c2aLeadsToReparent = new List<Lead>();
                        System.debug(LoggingLevel.ERROR,'leadObj, l:'+leadObj+' leadObj.Associated_Account__c: '+leadObj.Associated_Account__c);
                        templc = new Database.LeadConvert();
                        templc.setLeadId(leadObj.id);
                        templc.setConvertedStatus('Converted');
                        templc.setAccountId(leadObj.Associated_Account__c);
                        System.debug('not setting account'+leadObj.Associated_Account__c);
                        templc.setDoNotCreateOpportunity(true);
                        
                        try {
                                System.debug('converting the lead##');
                                lcr = Database.convertLead(templc);
                                retURL.setRedirect(true);
                        } catch(Exception ex) {
                            retURL = null;
                            String errMsg = '';
                            if (ex.getMessage().toLowerCase().contains('network contact')) {
                                errMsg = 'Contact is read-only since it is a network contact. Send an email to Globalsalesops@akamai.com if you feel that you should be able to edit this contact.';
                            } else {
                                errMsg = ex.getMessage();
                            }
                            showMessage = true;
                            Apexpages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,errMsg));
                        }
                        if(lcr!=null)
                        {
                                if(lcr.isSuccess())
                                {
                                        //get the ID of the contact converted from lead
                                        if(lcr.getContactId() != null)
                                        {
                                            if(leadObj.Leads__r.size()!=0){
                                                for(Lead lead : leadObj.Leads__r){
                                                    lead.Associated_Contact__c = lcr.getContactId();
                                                    c2aLeadsToReparent.add(Lead);
                                                }

                                            }
                                                ContactId = lcr.getContactId();
                                                retURL = new PageReference('/'+ContactId);
                                                if(!c2aLeadsToReparent.isEmpty())
                                                    GsmUtilClass.doDatabaseUpdate(c2aLeadsToReparent,'ConvertLeadToContactController','convertLead');
                                        }

                                }
                        }


                          
                        return retURL;
                }
    public PageReference Back() {

        return new PageReference('/' +leadObj.id);
    }

}