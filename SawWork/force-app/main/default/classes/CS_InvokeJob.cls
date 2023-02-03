global class CS_InvokeJob
{
    webservice static void invokeContactsProcessing()
    {
        CS_UpdateContacts processResponses = new CS_UpdateContacts();
        processResponses.execute();
    }
}