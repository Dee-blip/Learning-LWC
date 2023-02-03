// Moved this class from Q2O to L2Q repository - Nagaraj Desai
// SFDC- 3271
public class L2Q_WaiverEmailGenerator {
        public Account acc;
        public Order_Approval__c OrderApp = new Order_Approval__c();
        public Opportunity opp = new Opportunity();
        String oppURL;
        String OaURL;
        public Map<String,String> FormValues {get; set;}
        public PageReference pageRef {get; set;}
        public Id orderId;
        public Boolean renderWaiverDocPage {get; set;}
        public String redirectionWaitTime {get; set;}

        public void setRenderWaiverDocPage() {
                renderWaiverDocPage = true;
        }

        public PageReference refreshCurrentPage() {
                return pageRef;
        }

        public L2Q_WaiverEmailGenerator(){

                /*Account Name,Account ID,Division,Opportunity,Order Approval,Channel Partner End User Name,Channel Partner Account ID,
                   Reason for Approval,Justification,Term,Expected Renewal Date,Order Type,Order Name,Description,Owner Full Name,
                   Primary Contact,Valid Until Date,Grand Total*/
                renderWaiverDocPage = false;
                redirectionWaitTime = GSMSettings.getValue('DownloadWaiverPageRedirectionWaitTime');
                if(System.currentPagereference().getParameters().get('id') != null) {
                        orderId = System.currentPagereference().getParameters().get('id');
                }
                System.DEBUG('Id: ' + orderId);
                pageRef = new PageReference('/'+orderId);
                OrderApp =[Select id,
                           Associated_Opportunity__c
                           from Order_Approval__c
                           where id=:orderID];


                opp=[Select id,
                     Partner_Involved__r.Name,
                     Partner_Involved_AKAM_Account_ID__c,
                     Deal_Type__c,
                     Owner__r.Name,
                     AccountId
                     from Opportunity
                     where id=:OrderApp.Associated_Opportunity__c
                ];

                acc=[ Select Id,
                      Name,
                      AKAM_Account_ID__c
                      From Account
                      where id=:opp.AccountId
                ];


                oppURL=URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.id;
                OaURL=URL.getSalesforceBaseUrl().toExternalForm() + '/' + OrderApp.id;

                List<String> listOfValues = Label.Fields_for_Waiver_E_mail.split(',');

                FormValues=new map<String, String>();
                for(String val: listOfValues) {

                        System.debug('val :'+val);

                        /*
                           (Account ID,
                           Account Name,
                           Division,
                           Opportunity,
                           Order Approval,
                           Expected Close Date,
                           Term of Agreement,
                           Total Revenue for Opportunity,
                           Annual Revenue,
                           Annual North American vs. Non-North American Traffic Revenue in Dollars*)
                         */

                        if(val.equals('Account Name'))
                                FormValues.put(val,acc.Name);

                        else if(val.equals('Account ID'))
                                FormValues.put(val,acc.AKAM_Account_ID__c);

                        else if(val.equals('Opportunity'))
                                FormValues.put(val,oppURL);

                        else if(val.equals('Order Approval'))
                                FormValues.put(val,OaURL);

                        else if(val.equals('Order Type'))
                                FormValues.put(val,opp.Deal_Type__c);

                        else if(val.equals('Owner Full Name'))
                                FormValues.put(val,opp.Owner__r.Name);

                        else if(val.equals('Channel Partner End User Name')&&opp.Partner_Involved__c!=null)
                                FormValues.put(val,opp.Partner_Involved__r.Name);


                        else if(val.equals('Channel Partner Account ID')&&opp.Partner_Involved_AKAM_Account_ID__c!=null)
                                FormValues.put(val,opp.Partner_Involved_AKAM_Account_ID__c);

                        else
                                FormValues.put(val,' ');
                }


        }

        public Component.Apex.OutputPanel getImageDetails()
        {
                System.debug('hjdsgjhfs :'+JSON.serialize(FormValues));
                Document doc = [SELECT Id, Name FROM Document where Name='Gsm_Workflow_Waiver_Img' limit 1];
                Component.Apex.OutputText outText = new Component.Apex.OutputText(escape = false);
                Component.Apex.OutputPanel dynOutPanel= new Component.Apex.OutputPanel();
                String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() +'/' + 'servlet/servlet.ImageServer?id=' + doc.Id;
                baseUrl = baseUrl + '&oid=' + UserInfo.getOrganizationId();

                String imageUrl = '<img src="'+baseUrl+'" width="431" height="182"></img>';
                outText.value=imageUrl;

                dynOutPanel.childComponents.add(outText);
                return dynOutPanel;

        }

        public PageReference redirectToCurrentPage() {
                PageReference pr = new PageReference('/a0I2C0000005Cz0UAE');
                return pr;
        }


}