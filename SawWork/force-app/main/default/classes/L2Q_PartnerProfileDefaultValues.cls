public class L2Q_PartnerProfileDefaultValues 
{
        public String defaultValuesForPartnerProfile {get; set;}
        public String returnValPrefix {get; set;}

        public L2Q_PartnerProfileDefaultValues(ApexPages.StandardController stdSetCtrl) 
        {
            Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();

            Id partnerAccountId ;
            returnValPrefix='';
            if(CurrentUser.isPartner)
            {
                partnerAccountId = CurrentUser.attributes.get('Partner Account');
                returnValPrefix = '/partners';
            }
            if(String.isBlank(partnerAccountId))
            {
                partnerAccountId = ApexPages.currentPage().getParameters().get('CF00NG0000008Nvop_lkid');
            }

            if(!String.isBlank(partnerAccountId))
            {
                Map<String, String> prepopulatedDetails = new Map<String, String>();
                Account relatedAccount=[select Id,Name,NAP_Partner_Type__c,Partner_Tier__c,Website,Phone, BillingCity, BillingCountry, BillingState, BillingStreet, BillingPostalCode,Partner_Reach__c from Account where Id=:partnerAccountId limit 1];
                if (relatedAccount!=null)
                {   

                    List<String> addressFields = new List<String>{relatedAccount.BillingStreet, relatedAccount.BillingCity, relatedAccount.BillingState, relatedAccount.BillingPostalCode, relatedAccount.BillingCountry};

                    for(Integer i=addressFields.size()-1;i>=0;i--)
                    {
                        if(String.isBlank(addressFields[i]) || addressFields[i]=='TBD')
                            addressFields.remove(i);
                    }

                    /*
                       prepopulatedDetails.put('Partner_Address_City1__c', relatedAccount.BillingCity);
                       prepopulatedDetails.put('Partner_Address_Zip1__c', relatedAccount.BillingPostalCode );
                       prepopulatedDetails.put('Partner_Address_State1__c', relatedAccount.BillingState);
                       prepopulatedDetails.put('Partner_Address_Street1__c', relatedAccount.BillingStreet);
                     */
                    prepopulatedDetails.put('Partner_Website__c', relatedAccount.Website);
                    prepopulatedDetails.put('Partner_Phone__c', relatedAccount.Phone);
                    prepopulatedDetails.put('Partner_Account_Name__c', relatedAccount.Id);
                    prepopulatedDetails.put('Partner_Address_Country1__c', relatedAccount.BillingCountry);
                    prepopulatedDetails.put('Partner_Name_for_Tile_Display__c', relatedAccount.Name);
                    prepopulatedDetails.put('Partner_Name_for_Detail_Display__c', relatedAccount.Name);


                    Map<String, String> accountPartnerTypeToPPPartnerType = GSMSettings.getMap('AccountNAPPartnerTypeToPPPartnerType');
                    if(accountPartnerTypeToPPPartnerType.containsKey(relatedAccount.NAP_Partner_Type__c))
                    {
                        prepopulatedDetails.put('Partner_Type__c', accountPartnerTypeToPPPartnerType.get(relatedAccount.NAP_Partner_Type__c));
                    }

                    for(Schema.PicklistEntry pe : Partner_Profile__c.Partner_Level__c.getDescribe().getPicklistValues())
                    {
                        if(!String.isBlank(relatedAccount.Partner_Tier__c) && relatedAccount.Partner_Tier__c.containsIgnorecase(pe.getValue()))
                        {
                            prepopulatedDetails.put('Partner_Level__c', pe.getValue());
                            break;
                        }
                    }


                    if(addressFields.size()>0)
                    {
                        String joined = String.join(addressFields, ', ');
                        joined  = joined.replaceAll('\r\n','').replaceAll('\n','').replaceAll('\r','');
                        if(joined.length()>255)
                            joined = joined.substring(0, 255);
                        prepopulatedDetails.put('Partner_Address__c', joined.escapeHtml4());
                        // SFDC-6889 : @Nagaraj Desai - Removing code explicitly put in for SFDC-5903 and making it globally generic
                    }


                    GSM_GenericFormController.FieldDescriptor eachSectionFields;
                    for(String fieldAPIName : prepopulatedDetails.keySet())
                    {
                        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                        eachSectionFields.value = prepopulatedDetails.get(fieldAPIName);
                        mappOfFieldVsDefaultValues.put(fieldAPIName, eachSectionFields);
                    }
                    defaultValuesForPartnerProfile = mappOfFieldVsDefaultValues.size()>0 ? JSON.serialize(mappOfFieldVsDefaultValues) : '';

                    System.DEBUG(LoggingLevel.Error, 'AGH_D defaultValuesForPartnerProfile' + defaultValuesForPartnerProfile);
                }

            }
        }
}