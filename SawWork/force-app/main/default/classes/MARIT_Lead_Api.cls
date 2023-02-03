/*
 * Created as part of MARIT-1079
 * Api will be invoked by applications such as mule before creating a contact
 */
@RestResource(urlMapping='/lead/convert/*')
global without sharing class MARIT_Lead_Api {
    @HttpPost
    global static void convertLead() {
 
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String jsonResponse = '';
        String email = req.params.get('email');
 
        // No email parameter was found; return status 400
        if(email == null) {
            res.statusCode = 400;
            jsonResponse = '{"response": {"status": "Failure", "message": "MissingRequiredQueryParameter email"}}';
            res.responseBody = blob.valueOf(jsonResponse);
            return;
        }
        
        // Get the list of New/In process marketo leads that match the email sent in the request.
        List<Lead> leads = MARIT_ContactHandler.getLeadsWithEmail(email);
        
        // No Lead with matching email
        if( leads.isEmpty()) {
            res.statusCode = 400;
            jsonResponse = '{"response": {"status": "Failure", "message": "No Person lead matching email was found"}}';
            res.responseBody = blob.valueOf(jsonResponse);
            return;
        }
        
        // Convert lead if exists
        string result = MARIT_ContactHandler.convertMarketoLeadToContact(leads[0]);
        Map<String,Object> contactInfo = (Map<String,Object>) JSON.deserializeUntyped (result);
        if(String.valueOf(contactInfo.get('status')) == 'Success') {
            res.statusCode = 200;
        } else {
            res.statusCode = 500;
        }
        res.responseBody = blob.valueOf(result);
        return;
    }      
}