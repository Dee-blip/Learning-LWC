public class EmailWithCSVAttachment
{
    private Messaging.SingleEmailMessage emailMessage;
    private String csvHeader;
    private List<String> csvFields ;
    private Integer csvRecordCount;
    private String toAddress;
    private String ccAddress;

    public EmailWithCSVAttachment()
    {
        emailMessage = new Messaging.SingleEmailMessage();
        csvFields = new List<String>();
    }

    public EmailWithCSVAttachment withEmailTemplate(EmailTemplate emTemplate)
    {
        emailMessage.setHtmlBody(emTemplate.HtmlValue);
        emailMessage.setPlainTextBody(emTemplate.Body);
        emailMessage.setSubject(emTemplate.Subject);
        return this;
    }

    public EmailWithCSVAttachment withCCAddress(String ccAddr)
    {
        this.ccAddress = ccAddr;
        if(ccAddr!=null)
            emailMessage.setccAddresses(ccAddr.split(','));
        return this;
    }

    public EmailWithCSVAttachment withToAddress(String toAddr)
    {
        this.toAddress = toAddr;
        emailMessage.setToAddresses(toAddr.split(','));
        return this;
    }

    public EmailWithCSVAttachment withFromAddress(String orgWideAddressDisplayName)
    {
        Id orgWideId = [select Id from OrgWideEmailAddress where DisplayName=:orgWideAddressDisplayName limit 1].Id;
        emailMessage.setOrgWideEmailAddressId(orgWideId);
        return this;
    }

    public EmailWithCSVAttachment withCSVHeader(String csvHeaderParam)
    {
        this.csvHeader = csvHeaderParam;
        return this;
    }

    public EmailWithCSVAttachment withCSVFields(String csvFieldsParam)
    {
        this.csvFields = csvFieldsParam.split(',');
        return this;
    }


    public EmailWithCSVAttachment withCSVRecords(List<sObject> records)
    {
        csvRecordCount = records.size();

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('text/csv');
        String reportName = 'REPORT_#DATE#_#MONTH#_#YEAR#.csv'.replace('#DATE#', String.valueOf(Date.today().day()))
                                                              .replace('#MONTH#', String.valueOf(Date.today().month()))
                                                              .replace('#YEAR#', String.valueOf(Date.today().year()));

        attachment.setFileName(reportName);
        attachment.setInline(false);
        String csvBody = this.csvHeader;

        for(sObject rec : records)
        {
            csvBody += '\n';

            for(String fieldAPIName : csvFields)
            {
                csvBody += getField(rec, fieldAPIName)+',';
            }
        }


        attachment.Body = blob.valueOf(csvBody);

        Messaging.EmailFileAttachment [] attachmentList = new List<Messaging.EmailFileAttachment> () ;
        attachmentList.add(attachment);
        emailMessage.setFileAttachments(attachmentList);
        return this;
    }


    private String getField(sObject objInstance, String fName)
    {
        String retValue='';
        System.Debug(LoggingLevel.Error, 'AGH_D in getField method with fName'+fName);
        if(fName.contains('__r'))
        {
            String[] brokenParts = fName.split('\\.', 2);
            String parentRelationShipName = brokenParts[0];
            String fieldAPIName = brokenParts[1];

            System.Debug(LoggingLevel.Error, 'AGH_D parentRelationShipName:'+parentRelationShipName+'and fieldAPIName:'+fieldAPIName);
            return getField( objInstance.getSobject(parentRelationShipName), fieldAPIName);
        }
        else
        {
            Object retObj = objInstance.get(fName);

            if(retObj instanceof String)
            {
                retValue = ((String) retObj).escapeCsv();
            }
            else if(retObj instanceof DateTime)
            {
                retValue = ((DateTime)retObj).format('dd/MM/yyyy');
            }
            else
            {
                // other data types shouldnt be double quoted because excel recognises those data types
                retValue = String.valueOf(retObj);
            }
        }

        return retValue;
    }



    public String send()
    {
        String mailDeliveryStatus;
        Messaging.sendEmailResult[] sendEmailResults = Messaging.sendEmail(new Messaging.Email[] { emailMessage }, false);

        for(Messaging.SendEmailResult sendEmailResult: sendEmailResults)
        {
            if(!sendEmailResult.isSuccess())
            {
                mailDeliveryStatus = 'FAILED: ';
                for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors())
                {
                    mailDeliveryStatus += sendEmailError.Message + ',';
                }
            }
        }

        if(String.isBlank(mailDeliveryStatus))
            mailDeliveryStatus = 'SUCCEEDED';

        return '\nDelivery to '+this.toAddress+' (with '+ this.ccAddress+' in CC)  with '+csvRecordCount+' records in attachment : '+mailDeliveryStatus;
    }
}