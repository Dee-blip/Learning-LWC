/**
    AttachmentTrigger
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class is used to trigger IRCase case creation process once attachment is added to Draft_Invoice record.
                
    @History
    --Developer           --Date            --Change
    Ali KM                06/02/2013        Created the class   
                                            CR 2068273 - Invoice Review Cases Process migration from Siebel to SF. 
                                            - Updates DI when attachment is added/removed.
    Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
                                            - By-passing the trigger code for connection user.
    Kunal Sharma          07/20/2014        - CR 2562744.
                                            Adding functionality for SC Attachment update.
    Akhila                2nd May 2017      CR 3717992 - Minor changes for luna casemanagement user.

    Sharath Prasanna      4th August 2017   For FFPSA-238: Soasta Migration: if an attachment is created against test,     
                                            hasAttachment field has to be checked. On delete, check if the report status is complete
                                            If so, then dont allow delete.
*/ 

trigger AttachmentTrigger on Attachment (after delete, after insert, after update, before delete) 
{
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('Attachment');
    }
}