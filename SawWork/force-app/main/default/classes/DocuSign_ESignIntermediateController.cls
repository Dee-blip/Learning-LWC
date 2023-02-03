/*
    DocuSign_ESignIntermediateController
    @author :Swati <Swmahapa@akamai.com>
    @Description : This is the generalized Custom Controller for the ESignIntermediate Page
           
    @History
    --Developer         --Date          --Change
       Swati      Jun/2019      Created this class for
                                        - SFDC-4321 e-Signature DocuSign implementation for Upgrade version 
                                        - Show Validation otherwise directly land to DocuSign page.
    */
    public class DocuSign_ESignIntermediateController {

        // ErrorList
        protected List<String> errList;
        public Order_Approval__c oa {get; set;}
        public Boolean showError {get; set;}
        public Boolean showWarning {get; set;}

         public Integer mode {get; set;}
        public string ErrorMessage{get;set;}
        public Id srcObjId{get;set;}
        public Set<Id> contentDocIds;
        public static L2Q_ZOFF_Feature__mdt  zoffmdtValue = ZoffUtilClass.getZOFFmdtsetting('ZOFF');  //Rajesh - SFDC-7061


        // constructor
        public DocuSign_ESignIntermediateController()
        {

        }

        /**
            addError(String pErrorMessage)
            - Method to add to list of Errors.
        */
        private void addError(String pErrorMessage)
        {
            errList.add(pErrorMessage);
        }
        /**
            addError(String pErrorMessageList)
            - Method to add to list of Errors.
        */
        private void addError(String[] pErrorMessageList)
        {
            errList.addAll(pErrorMessageList);
        }


        // entry method s
        public Boolean init()
        {
            //mode = 0;
            mode = String.isBlank(ApexPages.currentPage().getParameters().get('mode')) ? 0 : Integer.valueOf(ApexPages.currentPage().getParameters().get('mode'));
            errList = new List<String>();
            contentDocIds = new Set<Id>();
            Set<Id> ownerIds = new Set<Id>();

            srcObjId = ApexPages.currentPage().getParameters().get('id');

          if(srcObjId != null){
             Order_Approval__c o = [SELECT Id, Name, Approvals_Required__c, CCG__c, Associated_Opportunity__r.Name,
                    Legal__c, Deal_Desk__c,Associated_Opportunity__r.Deal_Type__c,
                    Order_Expires_Unless_Duly_Executed_By__c,recordtype.name,
                    Account_Territory__c, Associated_Opportunity__c, Associated_Account__c, Associated_Opportunity_Sales_Stage__c,
                        Opportunity_Owner__c, Type__c, AKAM_OrderApproval_ID__c, Send_To_Contact__c, Associated_Opportunity__r.AccountId,
                        Associated_Opportunity__r.CCG__c,Associated_Opportunity__r.DD_CCG_Expiration_Date__c, CCG_Status__c ,
                        Associated_Opportunity__r.Account_Division__c, Associated_Opportunity__r.Associated_Account_Vertical__c, Associated_Opportunity__r.Associated_Account_Sub_Vertical__c,Associated_Opportunity__r.IsClosed ,Associated_Opportunity__r.ZOFF_Enabled__c,Associated_Opportunity__r.ZOFF_Status__c,Associated_Opportunity__r.ZOFF_Approval__c,Associated_Opportunity__r.Opportunity_Type__c,Associated_Opportunity__r.RecordType.DeveloperName,Associated_Opportunity__r.Source__c, //Added by Rajesh - SFDC-7061
                        Associated_Opportunity__r.MRR__c,Associated_Opportunity__r.Account_MRR_Type__c,Associated_Opportunity__r.oc_source__c,Associated_Opportunity__r.Opportunity_Category__c,Associated_Opportunity__r.Loss_Reason__c,Associated_Opportunity__r.Competitor__c,Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c,Associated_Opportunity__r.Account.Override_Visual_Compliance__c //added as part of SFDC-8273
                            FROM Order_Approval__c WHERE id=:srcObjId];

                        oa = o;
                User currentUserRecord = [SELECT Id, UserPermissionsSFContentUser, Isactive,Profile.Name FROM User Where Id = :UserInfo.getUserId()];

                //Begin Rajesh SFDC-7061
                List<String> zoffvalidapprType = zoffmdtValue.Opportunity_Type_Appr__c.split(',');
                List<String> webVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Web_Vertical_For_ZOFF').split(',');
                List<String> webSubVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Zoff_Sub_Vetical_For_Web_HighTech').split(',');
                if(oa.Associated_Opportunity__r.Source__C != 'Azure Marketplace'  && zoffmdtValue.Feature_Enabled__c && zoffmdtValue.Toggle6SignedValidation__c && ZoffUtilClass.listcontainsIgnorcase(zoffvalidapprType,oa.Associated_Opportunity__r.Opportunity_Type__C) && (webVerticalForZOFF.contains(oa.Associated_Opportunity__r.Associated_Account_Vertical__c) || (oa.Associated_Opportunity__r.Associated_Account_Vertical__c == 'High Technology' && webSubVerticalForZOFF.contains(oa.Associated_Opportunity__r.Associated_Account_Sub_Vertical__c))) &&
                !oa.Associated_Opportunity__r.IsClosed && oa.Associated_Opportunity__r.ZOFF_Enabled__c &&
                ( 'Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)&& (String.isEmpty(oa.Associated_Opportunity__r.ZOFF_Status__c )) || ( 'No'.equalsIgnorecase(oa.Associated_Opportunity__r.ZOFF_Status__c) && !('Approved'.equalsIgnorecase(oa.Associated_Opportunity__r.ZOFF_Approval__c) ||  'Approval Overridden'.equalsIgnorecase(oa.Associated_Opportunity__r.ZOFF_Approval__c) ) ))
                ) {
                    addError('Associated opportunity should either have ZOFF status Yes OR ZOFF approved when ZOFF status is NO.');
                }
                //End Rajesh SFDC-7061
				//SFDC-6364 - VC Validations
                        if(('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Red').split(',').contains(oa.Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c) && !oa.Associated_Opportunity__r.Account.Override_Visual_Compliance__c )
                        {
                            addError('<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Red') + '<br/>');
                        }
                        if(('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Pending').split(',').contains(oa.Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c) && !oa.Associated_Opportunity__r.Account.Override_Visual_Compliance__c)
                        {
                            addError('<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Pending') + '<br/>');
                        }
                        if(('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_DS_Alert').split(',').contains(oa.Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c) && !oa.Associated_Opportunity__r.Account.Override_Visual_Compliance__c )
                        {
                            addError('<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_DS_Alert') + '<br/>');
                        }	
               system.debug('swati>>>'+oa);
               system.debug('swati>>'+oa.Associated_Opportunity__c);


                // check whether files are associated to order approval
                for(ContentDocumentLink conObj : [Select Id,ContentDocumentId from ContentDocumentLink where
                                                 LinkedEntityId = :oa.Id ]) {
                    contentDocIds.add(conObj.ContentDocumentId);
                }

                //If there is no files associated to Order Approval show error
                if(contentDocIds.size()==0)
                {

                        addError('There are no files for this Order Approval');

                }

                if(oa.Associated_Opportunity__r.Deal_Type__c != 'Direct'){
                        addError('This is not a Direct Account.');
                    }
              
              	//SFDC-8273 -Project Win Competitor and Loss Reason Validation
              if((oa.Associated_Opportunity__r.Opportunity_Category__c == null || oa.Associated_Opportunity__r.Loss_Reason__c == null) && ('LMRR'.equalsIgnoreCase(oa.Associated_Opportunity__r.Account_MRR_Type__c)) && ('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && oa.Associated_Opportunity__r.oc_source__c !='Marketplace' && oa.Associated_Opportunity__r.Opportunity_Type__c !='Auto-Renewal'){
                    addError(GsmUtilClass.getGSMSettingValue('ProjectWinValidationError'));
                    }
              if(oa.Associated_Opportunity__r.Competitor__c  == null && ('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && oa.Associated_Opportunity__r.oc_source__c !='Marketplace' && oa.Associated_Opportunity__r.Opportunity_Type__c !='Auto-Renewal' && oa.Associated_Opportunity__r.Opportunity_Type__c !='Contract Change' && oa.Associated_Opportunity__r.Source__c != 'Azure Marketplace'&&
                currentUserRecord.Profile.Name !='Business Operations' &&
                currentUserRecord.Profile.Name !='CRM Integration' &&
                currentUserRecord.Profile.Name !='CRM Integration 2.0' &&
                currentUserRecord.Profile.Name !='Mulesoft Integration' &&
                currentUserRecord.Profile.Name !='Mulesoft Integration v1'){
                    addError(GsmUtilClass.getGSMSettingValue('ProjectWinValidationCompetitiveError'));
                    }
                /* SFDC-4178
                 if(oa.Associated_Opportunity__r.DD_CCG_Expiration_Date__c < date.today() || oa.Associated_Opportunity__r.DD_CCG_Expiration_Date__c == null){
                        addError('Valid Until Date is required and cannot be in the past.');

                }
                if(oa.CCG_Status__c !='Completed'){
                        addError('OA Status is not Completed');

                }
                if(oa.Associated_Opportunity__r.CCG__c == null){
                        addError('OA# is required.');

                }
                */
            }

            return true;
        }

        public PageReference validate()
        {
            init();
             /*
            @author: swati
            @description: Here is how the page works:
                            -   Check if any errors are present -> show error [mode=0]
                            -   Check if any warnings are present -> show warning with continue button[mode=2]
                            -   If they hit continue OR no warnings are persent, reload the page for choosing contacts [mode=1]
                             */
                system.debug('swati>>>'+oa);
                system.debug('swati>>'+oa.Associated_Opportunity__c);


                if(oa.recordType.name != 'MSA') {
                    errList.addAll(GsmUtilClass.SalesStageSixValidation(oa.Associated_Opportunity__c,'esign'));
                }



                showError = false;
                showWarning = false;

                system.debug('Show Mode2' + mode );
                system.debug('Show Error' + showError);

                //Displaying the error messages
                if (mode == 0 && errList.size()>0){
                    ErrorMessage='<b>Please make sure that the below issues are resolved before proceeding further with "Send for E-Signature" request.</b><br/>';
                    for(string err:errList)
                    ErrorMessage+='<br/><b>•</b> '+err+'<br/>';
                    showError = true;
                }



                //[QTOO-1576]: Getting an intermediate blank page when clicking on "Send for e-signature" button on an agreement
                if(ErrorMessage == null) {
                    mode = 1;
                }



             if(mode == 1)
            {
                //if(oa.id != null)
                return (new PageReference('/apex/dsfs__DocuSign_CreateEnvelope?DSEID=' + '' + '&SourceID=' + oa.id + '&LA=' + '0'));
               // return (new PageReference('/apex/dsfs__DocuSign_CreateEnvelope?DSEID=' + '' + '&SourceID=' + oa.id));

                //String editEnvelopeURL = Label.DocusignEnvelopeURL.replace('##DESID##', dsEnvelope.Id).replace('##OA_ID##', dsEnvelope.dsfs__Source_Object__c);
               // return (new PageReference(editEnvelopeURL));
            }
            else

            return null;
        }

        public PageReference cancel()
        {
            return (new PageReference('/' + oa.id));
        }

        public PageReference canceltoOppty()
        {
            return new PageReference('/'+oa.Associated_Opportunity__c);
        }


    }