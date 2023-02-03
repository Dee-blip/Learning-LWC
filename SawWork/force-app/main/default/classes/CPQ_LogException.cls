/**
* Custom exception class for CPQ classes, it is used log the error messages in CPQ_Error_Log__c object
* Test Class: CPQ_Test_ExceptionLogger
* @author  Shashank Hegade
* @version 2.0
* @since   2020-05-21
*/

public without sharing class CPQ_LogException extends Exception{


    public static final Integer CUSTOM_MESSAGE_LENGTH = 255;
    private static Boolean logEnabled = CPQSettings.getBooleanValue('Log Enabled');

    public static List<CPQ_Error_Log__c> errors = new List<CPQ_Error_Log__c>();

    public CPQ_Error_Log__c newError{ 
        get { return newError;}
        protected set;
    }

    /**
     * @description CPQ_LogException is a parameterized constructor to set up the error logger record
     * @param  exc instance of the exception
     * @param  ec  custom error code if any, otherwise null
     * @return     CPQ_LogException instance 
     */
    public CPQ_LogException(Exception exc, CPQ_CustomException.StatusCode ec){
        this.newError = new CPQ_Error_Log__c();
        this.newError.Message__c = exc.getMessage();
        this.newError.Stack_Trace__c = exc.getStackTraceString();
        this.newError.Error_Cause__c = String.valueOf(exc.getCause()); 
        this.newError.Line_Number__c = exc.getLineNumber();
        this.newError.Type_Name__c = exc.getTypeName();
        
        if(ec != null){
            this.newError.Error_Code__c = ec.name();
        }
           
    }

    /**
     * PLEASE DO NOT USE THIS AS THIS WILL BE DEPRECATED
     * createErrorRecord method initializes the error object with thr thrown exception values
     * @param doInsert is the boolean value used to decide the intialized error object is inserted to DB in the same method
     * @return Instance of the class variable
     */
    public CPQ_LogException createErrorRecord(Boolean doInsert){
        this.newError = new CPQ_Error_Log__c();
        this.newError.Message__c = this.getMessage();
        this.newError.Stack_Trace__c = this.getStackTraceString();
        this.newError.Error_Cause__c = String.valueOf(this.getCause()); 
        this.newError.Line_Number__c = this.getLineNumber();
        this.newError.Type_Name__c = this.getTypeName();
        if(doInsert){
            try{
                insert this.newError;
            }
            catch (Exception e){
                System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }
        return this;
    }

    /**
     * @description This method inserts the instance error logger variable to database
     * @return   CPQ_LogException instance 
     */
    public CPQ_LogException insertRecord(){

        try{
            insert this.newError;
        }
        catch (Exception e){
            System.debug(LoggingLevel.ERROR, e.getMessage());
        }

        return this;
    }

    /**
     * @description setShortMessage method is used to set a custom message for the error record
     * @param  message String of message
     * @return         CPQ_LogException instance
     */
    public CPQ_LogException setShortMessage(String message){
        if (message.length() > CUSTOM_MESSAGE_LENGTH){
            message = message.substring(CUSTOM_MESSAGE_LENGTH);
        }

        this.newError.Error_Message__c = message;

        return this;
    }

    /**
     * sendEmailtoDev Method will send email to dev only if the error record is inserted within the method
     * @return Instance of the class variable
     */
    public CPQ_LogException sendEmailtoDev(){
        //email will be sent only if the error record is inserted
        if(this.newError !=null && this.newError.Id != null && CPQ_Generic_Settings__c.getValues('errorEmailsTo').CPQ_Active__c){
            String toAddresses = CPQ_Generic_Settings__c.getValues('errorEmailsTo').CPQ_Value__c;
            String[] toAddressesList = toAddresses.split(';');
            sendEmail(this.newError.Id,toAddressesList); 
        }

        return this;
    }

    /**
     * getErrorRecord will return the initialized error object to calling method
     * @return CPQ_Error_Log__c A error record
     */ 
    public CPQ_Error_Log__c getErrorRecord(){
        return this.newError;
    }

    /**
     * sendEmail will send email to developers
     * @param  errorID         Id of the error record inserted in this class
     * @param  toAddressesList List of email addresses to which the email will be sent
     */
    @future
    private static void sendEmail(Id errorID, String[] toAddressesList){

        CPQ_Error_Log__c[] error = [SELECT ID, Stack_Trace__c FROM CPQ_Error_Log__c WHERE ID =: errorID];

        EmailTemplate[] emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                       FROM EmailTemplate 
                                       WHERE name LIKE : '%CPQ Error Logger Email Template%' LIMIT 1];

        User targetUser = [SELECT Id, Name , Alias FROM User where Alias =:CPQ_Generic_Settings__c.getValues('targetUserAlias').CPQ_Value__c LIMIT 1];

        if(error.size() > 0 && emailTemplate.size() > 0){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setTemplateId(emailTemplate[0].Id);
            message.setTargetObjectId(targetUser.Id);
            message.setToAddresses(toAddressesList);
            message.setSaveAsActivity(false);
            message.setTreatTargetObjectAsRecipient(false);
            message.setWhatId(error[0].ID);

            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            try{
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
            }
            catch (Exception e){
                System.debug(LoggingLevel.ERROR, e.getMessage());
            }
        }

    }

    /**
     * @description add method adds a error record to the static error record collector 
     * @param  error error record 
     */
    public static void add(CPQ_Error_Log__c error){
        errors.add(error);
    }

    /**
     * @description flush method pushed all the records collected in the static error record collector 
     */
    public static void flush(){
        if(errors.size() > 0){
            Database.upsert(errors, false);
        }
        
    }
    /**
     * @description get method returns the list of error records collected in the static error collector 
     * @return   list of error records
     */
    public static List<CPQ_Error_Log__c> get(){
        return errors;
    }

    /**
     * @description clear method clears the data stored in the static error collector variable 
     */
    public static void clear(){
        errors.clear();
    }
    /**
     * This method checks if log is enabled or not and it will execute system.debug statement only when log is true
     */
    public static void logInformation(String value){
        if (logEnabled) {
            System.debug(LoggingLevel.INFO, value);
        }

    }

}